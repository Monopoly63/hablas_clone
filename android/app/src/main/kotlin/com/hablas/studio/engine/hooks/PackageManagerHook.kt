package com.hablas.studio.engine.hooks

import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import java.util.concurrent.ConcurrentHashMap

/**
 * Virtual Package Manager Hook — Intercepts package resolution calls
 * so cloned apps read their virtual AndroidManifest.xml and virtual components.
 *
 * In production, this would use Java Reflection and Dynamic Proxies to intercept
 * IPackageManager Binder calls. For v1.0.0, we provide the scaffolding and
 * registration infrastructure.
 *
 * Architecture:
 *   - Virtual packages are registered with their instance IDs
 *   - Each virtual package gets its own manifest resolution path
 *   - The hook intercepts getPackageInfo(), getActivityInfo(), etc.
 *   - Redirects to virtualized component definitions
 */
class PackageManagerHook(private val context: Context) {

    private val virtualPackages = ConcurrentHashMap<String, MutableSet<Int>>()

    /**
     * Registers a virtual package instance.
     * This tells the hook that [packageName] has a virtual instance [instanceId].
     */
    fun registerVirtualPackage(packageName: String, instanceId: Int) {
        virtualPackages.getOrPut(packageName) { mutableSetOf() }.add(instanceId)
    }

    /**
     * Unregisters a virtual package instance.
     */
    fun unregisterVirtualPackage(packageName: String, instanceId: Int) {
        virtualPackages[packageName]?.remove(instanceId)
        if (virtualPackages[packageName]?.isEmpty() == true) {
            virtualPackages.remove(packageName)
        }
    }

    /**
     * Checks if a package has any virtual instances registered.
     */
    fun isVirtualPackage(packageName: String): Boolean {
        return virtualPackages.containsKey(packageName)
    }

    /**
     * Returns all instance IDs for a given package.
     */
    fun getInstancesForPackage(packageName: String): Set<Int> {
        return virtualPackages[packageName]?.toSet() ?: emptySet()
    }

    /**
     * Gets the original PackageInfo for a package.
     * In production, this would be intercepted to return virtualized info.
     */
    fun getPackageInfo(packageName: String): PackageInfo? {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }

    /**
     * Returns the total count of virtual instances across all packages.
     */
    fun totalVirtualInstanceCount(): Int {
        return virtualPackages.values.sumOf { it.size }
    }
}
