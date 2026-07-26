package com.hablas.studio.engine.hooks

import android.content.Context
import android.content.Intent
import java.util.concurrent.ConcurrentHashMap

/**
 * Virtual Activity Manager Hook — Proxies IActivityManager / IActivityTaskManager
 * Binder interfaces to manage virtual process lifecycles, intent redirection,
 * and task stacks.
 *
 * In production, this would:
 *   1. Hook into IActivityManager via reflection on ActivityManagerNative
 *   2. Create a dynamic proxy for IActivityManager interface
 *   3. Intercept startActivity() calls and redirect to virtual components
 *   4. Manage virtual task stacks independent of the host
 *   5. Handle process creation via VirtualProcessManager
 *
 * For v1.0.0, this provides the scaffolding and registration infrastructure.
 */
class ActivityManagerHook(private val context: Context) {

    // Track virtual activity stacks
    private val virtualTaskStacks = ConcurrentHashMap<String, VirtualTaskStack>()

    // Track running virtual processes
    private val runningProcesses = ConcurrentHashMap<String, VirtualProcessRecord>()

    /**
     * Launches a virtual activity for a cloned app.
     *
     * In production:
     *   1. Resolve the target app's main activity via PackageManager
     *   2. Create a virtual component name mapping
     *   3. Intercept startActivity() via Binder proxy
     *   4. Redirect intent to the virtual activity running in sandbox
     */
    fun launchVirtualActivity(packageName: String, instanceId: Int): Boolean {
        val key = "${packageName}_$instanceId"

        // Create virtual task stack
        virtualTaskStacks[key] = VirtualTaskStack(
            packageName = packageName,
            instanceId = instanceId,
            rootActivity = resolveMainActivity(packageName) ?: "",
            createdAt = System.currentTimeMillis()
        )

        // Track the process
        runningProcesses[key] = VirtualProcessRecord(
            packageName = packageName,
            instanceId = instanceId,
            pid = 0, // Would be assigned by the virtual process manager
            startedAt = System.currentTimeMillis()
        )

        return true
    }

    /**
     * Terminates a virtual activity and cleans up its task stack.
     */
    fun terminateVirtualActivity(packageName: String, instanceId: Int): Boolean {
        val key = "${packageName}_$instanceId"
        virtualTaskStacks.remove(key)
        runningProcesses.remove(key)
        return true
    }

    /**
     * Resolves the main launcher activity for a package.
     */
    private fun resolveMainActivity(packageName: String): String? {
        return try {
            val pm = context.packageManager
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
                setPackage(packageName)
            }
            val resolveInfo = pm.resolveActivity(intent, 0)
            resolveInfo?.activityInfo?.name
        } catch (e: Exception) {
            null
        }
    }

    // ─── Internal Data Classes ─────────────────────────────────────────

    data class VirtualTaskStack(
        val packageName: String,
        val instanceId: Int,
        val rootActivity: String,
        val createdAt: Long
    )

    data class VirtualProcessRecord(
        val packageName: String,
        val instanceId: Int,
        val pid: Int,
        val startedAt: Long
    )
}
