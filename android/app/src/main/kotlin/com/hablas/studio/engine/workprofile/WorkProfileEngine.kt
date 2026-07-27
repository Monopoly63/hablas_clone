package com.hablas.studio.engine.workprofile

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import java.io.File

/**
 * Work Profile Engine — Android's official mechanism for app cloning.
 *
 * Uses Android's DevicePolicyManager API to:
 *   1. Create a Work Profile (isolated Android user space)
 *   2. Install apps inside the Work Profile
 *   3. Freeze/unfreeze Work Profile apps (privacy feature)
 *   4. Remove Work Profile when user wants to reset
 *
 * NOTE: Some DevicePolicyManager methods (enablePackage, disablePackage,
 * uninstallPackage) are only available to profile/device owners.
 * We use safe public API alternatives where possible.
 */
class WorkProfileEngine(private val context: Context) {

    private val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    private val adminComponent = ComponentName(context, HablasDeviceAdminReceiver::class.java)
    private val pm = context.packageManager

    // ─── Work Profile Status ──────────────────────────────────────────

    fun isWorkProfileSetup(): Boolean {
        try {
            return dpm.isProfileOwnerApp(adminComponent.packageName)
        } catch (e: Exception) {
            return false
        }
    }

    fun isWorkProfileAvailable(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                val intent = Intent(DevicePolicyManager.ACTION_PROVISION_MANAGED_PROFILE)
                intent.putExtra(DevicePolicyManager.EXTRA_PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME, adminComponent)
                return intent.resolveActivity(pm) != null
            } catch (e: Exception) {
                return false
            }
        }
        return false
    }

    // ─── Work Profile Creation ─────────────────────────────────────────

    fun startProvisioning(activity: Activity): Boolean {
        if (isWorkProfileSetup()) return false
        if (!isWorkProfileAvailable()) return false

        try {
            val intent = Intent(DevicePolicyManager.ACTION_PROVISION_MANAGED_PROFILE)
            intent.putExtra(
                DevicePolicyManager.EXTRA_PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME,
                adminComponent
            )
            intent.putExtra(
                DevicePolicyManager.EXTRA_PROVISIONING_DEVICE_ADMIN_PACKAGE_NAME,
                adminComponent.packageName
            )

            // Set organization name for the work profile
            // EXTRA_PROVISIONING_ORGANIZATION_NAME was removed in API 33,
            // use the string key directly
            intent.putExtra(
                "android.app.extra.PROVISIONING_ORGANIZATION_NAME",
                "Hablas Clone"
            )

            // Support color for the work profile badge
            intent.putExtra(
                DevicePolicyManager.EXTRA_PROVISIONING_MAIN_COLOR,
                0x0000F2FE.toInt() // Liquid Cyan #00F2FE
            )

            if (intent.resolveActivity(pm) != null) {
                activity.startActivityForResult(intent, PROVISIONING_REQUEST_CODE)
                return true
            }
        } catch (e: Exception) {
            // Provisioning failed
        }

        return false
    }

    // ─── App Operations in Work Profile ─────────────────────────────────

    fun installAppInWorkProfile(packageName: String): Boolean {
        if (!isWorkProfileSetup()) return false

        try {
            // Use installExistingPackage (public API for profile owners)
            dpm.installExistingPackage(adminComponent, packageName)
            return true
        } catch (e: Exception) {
            // Fallback: try to enable the app via PackageManager
            try {
                pm.setApplicationEnabledSetting(
                    packageName,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    0
                )
                return true
            } catch (e2: Exception) {
                return false
            }
        }
    }

    fun launchAppInWorkProfile(packageName: String): Boolean {
        if (!isWorkProfileSetup()) return false

        try {
            val launchIntent = pm.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                context.startActivity(launchIntent)
                return true
            }
        } catch (e: Exception) {
            return false
        }

        return false
    }

    fun freezeApp(packageName: String): Boolean {
        if (!isWorkProfileSetup()) return false

        try {
            // Use public PackageManager API to disable the app
            pm.setApplicationEnabledSetting(
                packageName,
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER,
                0
            )
            return true
        } catch (e: Exception) {
            return false
        }
    }

    fun unfreezeApp(packageName: String): Boolean {
        if (!isWorkProfileSetup()) return false

        try {
            // Use public PackageManager API to enable the app
            pm.setApplicationEnabledSetting(
                packageName,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                0
            )
            return true
        } catch (e: Exception) {
            return false
        }
    }

    fun isAppFrozen(packageName: String): Boolean {
        try {
            val appInfo = pm.getApplicationInfo(packageName, 0)
            return !appInfo.enabled
        } catch (e: PackageManager.NameNotFoundException) {
            return false
        }
    }

    fun removeAppFromWorkProfile(packageName: String): Boolean {
        if (!isWorkProfileSetup()) return false

        try {
            // Use public PackageManager API to uninstall
            val deleteIntent = Intent(Intent.ACTION_DELETE)
            deleteIntent.data = Uri.fromParts("package", packageName, null)
            deleteIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(deleteIntent)
            return true
        } catch (e: Exception) {
            return false
        }
    }

    fun getWorkProfileApps(): List<String> {
        if (!isWorkProfileSetup()) return emptyList()

        try {
            val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
            return apps
                .filter { (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }
                .filter { it.packageName != context.packageName }
                .map { it.packageName }
        } catch (e: Exception) {
            return emptyList()
        }
    }

    // ─── Work Profile Removal ───────────────────────────────────────────

    fun removeWorkProfile(): Boolean {
        if (!isWorkProfileSetup()) return false

        try {
            dpm.clearProfileOwner(adminComponent)
            return true
        } catch (e: Exception) {
            return false
        }
    }

    companion object {
        const val PROVISIONING_REQUEST_CODE = 10001
    }
}
