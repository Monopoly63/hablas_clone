package com.hablas.studio.engine

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import com.hablas.studio.engine.hooks.ActivityManagerHook
import com.hablas.studio.engine.hooks.PackageManagerHook
import com.hablas.studio.engine.sandbox.FileRedirector
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * Virtual Engine Manager — Core orchestrator for the Hablas virtualization subsystem.
 *
 * Manages the lifecycle of virtual app instances, coordinates sandbox directory
 * mounting, and delegates to specialized hook modules for system service interception.
 *
 * Architecture:
 *   - VirtualPackageManager: Intercepts package resolution for cloned apps
 *   - VirtualActivityManager: Manages virtual process lifecycles via Binder proxy
 *   - FileRedirector: Redirects file I/O to sandbox directories
 *
 * Thread Safety: All mutable state uses ConcurrentHashMap and AtomicInteger.
 */
class VirtualEngineManager(private val context: Context) {

    // ─── Instance Tracking ─────────────────────────────────────────────
    private val instanceCounter = AtomicInteger(0)
    private val activeInstances = ConcurrentHashMap<String, VirtualInstanceRecord>()

    // ─── Hook Modules ──────────────────────────────────────────────────
    private val packageManagerHook = PackageManagerHook(context)
    private val activityManagerHook = ActivityManagerHook(context)
    private val fileRedirector = FileRedirector(context)

    // ─── Sandbox Base Path ─────────────────────────────────────────────
    private val sandboxBasePath: String
        get() = "${context.filesDir.absolutePath}/virtual/sandbox"

    // ─── App Discovery ─────────────────────────────────────────────────

    /**
     * Scans the device for all installed applications that can be cloned.
     * Returns a list of maps with package metadata.
     */
    fun getSystemInstalledApps(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)

        return apps
            .filter { it.flags and ApplicationInfo.FLAG_SYSTEM == 0 || it.packageName != context.packageName }
            .filter { it.packageName != context.packageName } // Exclude self
            .map { appInfo ->
                val appName = pm.getApplicationLabel(appInfo).toString()
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                mapOf(
                    "packageName" to appInfo.packageName,
                    "appName" to appName,
                    "versionName" to try {
                        pm.getPackageInfo(appInfo.packageName, 0).versionName
                    } catch (e: Exception) { null },
                    "isSystemApp" to isSystemApp,
                    "iconPath" to null // Icon bytes would be sent via BasicMessageChannel
                )
            }
            .sortedBy { it["appName"] as String }
    }

    // ─── Instance Lifecycle ────────────────────────────────────────────

    /**
     * Creates a new isolated virtual instance for the given package.
     *
     * Process:
     *   1. Allocate next instance ID
     *   2. Create sandbox directory structure
     *   3. Initialize file redirector mappings
     *   4. Register instance in active tracking
     *
     * @return The assigned instance ID
     */
    fun createVirtualInstance(packageName: String): Int {
        val instanceId = instanceCounter.incrementAndGet()
        val sandboxPath = getSandboxPath(packageName, instanceId)

        // Create sandbox directory structure
        val sandboxDir = File(sandboxPath)
        sandboxDir.mkdirs()
        File(sandboxDir, "shared_prefs").mkdirs()
        File(sandboxDir, "databases").mkdirs()
        File(sandboxDir, "cache").mkdirs()
        File(sandboxDir, "files").mkdirs()
        File(sandboxDir, "code_cache").mkdirs()

        // Register file redirector mapping
        fileRedirector.registerMapping(
            packageName = packageName,
            instanceId = instanceId,
            sandboxPath = sandboxPath
        )

        // Register with package manager hook
        packageManagerHook.registerVirtualPackage(packageName, instanceId)

        // Track the instance
        val record = VirtualInstanceRecord(
            packageName = packageName,
            instanceId = instanceId,
            sandboxPath = sandboxPath,
            status = "idle",
            createdAt = System.currentTimeMillis()
        )
        activeInstances["${packageName}_$instanceId"] = record

        return instanceId
    }

    /**
     * Launches a virtual instance inside its sandbox container.
     *
     * In production, this would:
     *   1. Fork a new process via Zygot
     *   2. Set up Binder proxy redirection
     *   3. Mount sandbox directories via FileRedirector
     *   4. Start the target app's main activity in the virtual context
     */
    fun launchVirtualInstance(packageName: String, instanceId: Int): Boolean {
        val key = "${packageName}_$instanceId"
        val record = activeInstances[key] ?: return false

        // Update status
        activeInstances[key] = record.copy(status = "running", lastActiveAt = System.currentTimeMillis())

        // Activate file redirector for this instance
        fileRedirector.activateMapping(packageName, instanceId)

        // Start the foreground service to prevent OS from killing the process
        // ForegroundServiceController.start(context, packageName, instanceId)

        // In production: ActivityManagerHook would launch the virtual process
        // val launched = activityManagerHook.launchVirtualActivity(packageName, instanceId)

        return true
    }

    /**
     * Safely terminates a virtual instance, flushing data before shutdown.
     */
    fun terminateVirtualInstance(packageName: String, instanceId: Int): Boolean {
        val key = "${packageName}_$instanceId"
        val record = activeInstances[key] ?: return false

        // Deactivate file redirector
        fileRedirector.deactivateMapping(packageName, instanceId)

        // Update status
        activeInstances[key] = record.copy(status = "idle")

        // Stop foreground service if no more running instances
        // ForegroundServiceController.stopIfNeeded(context)

        return true
    }

    // ─── Storage Management ────────────────────────────────────────────

    /**
     * Returns the current disk usage for a specific instance's sandbox.
     */
    fun getVirtualInstanceStorageSize(packageName: String, instanceId: Int): Long {
        val sandboxPath = getSandboxPath(packageName, instanceId)
        val dir = File(sandboxPath)
        if (!dir.exists()) return 0L
        return dir.walkTopDown().filter { it.isFile }.sumOf { it.length() }
    }

    /**
     * Clears the cache directory for a specific instance without
     * affecting active session data (SharedPreferences, databases).
     */
    fun clearInstanceCache(packageName: String, instanceId: Int): Boolean {
        val sandboxPath = getSandboxPath(packageName, instanceId)
        val cacheDir = File(sandboxPath, "cache")
        val codeCacheDir = File(sandboxPath, "code_cache")
        var success = true

        if (cacheDir.exists()) {
            success = success && cacheDir.deleteRecursively()
            cacheDir.mkdirs() // Recreate empty cache dir
        }
        if (codeCacheDir.exists()) {
            success = success && codeCacheDir.deleteRecursively()
            codeCacheDir.mkdirs()
        }

        return success
    }

    // ─── Bulk Operations ───────────────────────────────────────────────

    /**
     * Returns metadata for all tracked virtual instances.
     */
    fun getAllInstances(): List<Map<String, Any?>> {
        return activeInstances.values.map { record ->
            mapOf(
                "packageName" to record.packageName,
                "instanceId" to record.instanceId,
                "customName" to "${record.packageName.split(".").lastOrNull()} Instance ${record.instanceId}",
                "status" to record.status,
                "storageSizeBytes" to getVirtualInstanceStorageSize(record.packageName, record.instanceId),
                "createdAt" to record.createdAt
            )
        }
    }

    /**
     * Permanently deletes a virtual instance and all its sandbox data.
     */
    fun deleteVirtualInstance(packageName: String, instanceId: Int): Boolean {
        val key = "${packageName}_$instanceId"

        // Terminate if running
        val record = activeInstances[key]
        if (record?.status == "running") {
            terminateVirtualInstance(packageName, instanceId)
        }

        // Remove redirector mapping
        fileRedirector.removeMapping(packageName, instanceId)

        // Remove package manager hook
        packageManagerHook.unregisterVirtualPackage(packageName, instanceId)

        // Delete sandbox directory
        val sandboxPath = getSandboxPath(packageName, instanceId)
        val dir = File(sandboxPath)
        val deleted = if (dir.exists()) dir.deleteRecursively() else true

        // Remove from tracking
        activeInstances.remove(key)

        return deleted
    }

    /**
     * Shuts down all running instances. Called on app destroy.
     */
    fun shutdownAll() {
        activeInstances.values
            .filter { it.status == "running" }
            .forEach { record ->
                terminateVirtualInstance(record.packageName, record.instanceId)
            }
    }

    // ─── Private Helpers ───────────────────────────────────────────────

    private fun getSandboxPath(packageName: String, instanceId: Int): String {
        return "$sandboxBasePath/${packageName}_$instanceId"
    }

    // ─── Internal Data Class ───────────────────────────────────────────
    data class VirtualInstanceRecord(
        val packageName: String,
        val instanceId: Int,
        val sandboxPath: String,
        val status: String,
        val createdAt: Long,
        val lastActiveAt: Long? = null
    )
}
