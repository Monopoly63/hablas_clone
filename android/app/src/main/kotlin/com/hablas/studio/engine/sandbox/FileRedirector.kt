package com.hablas.studio.engine.sandbox

import android.content.Context
import java.io.File
import java.util.concurrent.ConcurrentHashMap

/**
 * File System Redirector — Intercepts file I/O operations and maps
 * them from the original app's data directory to the virtual sandbox.
 *
 * Redirection mapping:
 *   Source: /data/user/0/{original.package}/
 *   Target: /data/data/com.hablas.studio/virtual/sandbox/{original.package}_{instanceId}/
 *
 * In production, this would:
 *   1. Hook native file operations via LD_PRELOAD or PLT hooking
 *   2. Intercept Java-level File/RandomAccessFile operations
 *   3. Redirect SQLite database paths
 *   4. Redirect SharedPreferences file paths
 *   5. Mount virtual /proc and /sys for process isolation
 *
 * For v1.0.0, this provides the directory structure management and
 * mapping registration infrastructure.
 */
class FileRedirector(private val context: Context) {

    private val mappings = ConcurrentHashMap<String, SandboxMapping>()

    /**
     * Registers a new sandbox mapping for a virtual instance.
     */
    fun registerMapping(packageName: String, instanceId: Int, sandboxPath: String) {
        val key = "${packageName}_$instanceId"
        val originalPath = "/data/user/0/$packageName"

        mappings[key] = SandboxMapping(
            packageName = packageName,
            instanceId = instanceId,
            originalPath = originalPath,
            sandboxPath = sandboxPath,
            isActive = false
        )
    }

    /**
     * Activates a mapping — file operations will be redirected.
     */
    fun activateMapping(packageName: String, instanceId: Int) {
        val key = "${packageName}_$instanceId"
        mappings[key]?.let { mapping ->
            mappings[key] = mapping.copy(isActive = true)
        }
    }

    /**
     * Deactivates a mapping — file operations stop being redirected.
     */
    fun deactivateMapping(packageName: String, instanceId: Int) {
        val key = "${packageName}_$instanceId"
        mappings[key]?.let { mapping ->
            mappings[key] = mapping.copy(isActive = false)
        }
    }

    /**
     * Removes a mapping entirely.
     */
    fun removeMapping(packageName: String, instanceId: Int) {
        val key = "${packageName}_$instanceId"
        mappings.remove(key)
    }

    /**
     * Resolves a file path by redirecting it to the sandbox if a mapping exists.
     *
     * This is the core redirect function. In production, it would be called
     * by the native file hook layer for every file operation.
     */
    fun resolvePath(originalPath: String, packageName: String, instanceId: Int): String {
        val key = "${packageName}_$instanceId"
        val mapping = mappings[key] ?: return originalPath

        if (!mapping.isActive) return originalPath

        // Replace the original data path prefix with sandbox path
        return if (originalPath.startsWith(mapping.originalPath)) {
            originalPath.replace(mapping.originalPath, mapping.sandboxPath)
        } else {
            originalPath
        }
    }

    /**
     * Gets the sandbox directory size for a given mapping.
     */
    fun getSandboxSize(packageName: String, instanceId: Int): Long {
        val key = "${packageName}_$instanceId"
        val mapping = mappings[key] ?: return 0L
        val dir = File(mapping.sandboxPath)
        if (!dir.exists()) return 0L
        return dir.walkTopDown().filter { it.isFile }.sumOf { it.length() }
    }

    /**
     * Returns all active mappings.
     */
    fun getActiveMappings(): List<SandboxMapping> {
        return mappings.values.filter { it.isActive }
    }

    // ─── Internal Data Class ───────────────────────────────────────────

    data class SandboxMapping(
        val packageName: String,
        val instanceId: Int,
        val originalPath: String,
        val sandboxPath: String,
        val isActive: Boolean
    )
}
