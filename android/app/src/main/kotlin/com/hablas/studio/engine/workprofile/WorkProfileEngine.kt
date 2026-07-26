package com.hablas.studio.engine.workprofile

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.hablas.studio.engine.workprofile.HablasDeviceAdminReceiver
import java.io.File

/**
 * Work Profile Engine — Android's official mechanism for app cloning.
 *
 * This is THE real cloning approach used by professional products like
 * Island and Shelter. It uses Android's DevicePolicyManager API to:
 *   1. Create a Work Profile (isolated Android user space)
 *   2. Install apps inside the Work Profile
 *   3. Freeze/unfreeze Work Profile apps (privacy feature)
 *   4. Remove Work Profile when user wants to reset
 *
 * Benefits over VirtualApp approach:
 *   - Official Android API → Google-approved, Play Store compatible
 *   - True isolation → separate storage, accounts, permissions
 *   - No root required → works on all devices
 *   - Stable → no compatibility issues with most apps
 *   - Legal → no copyright/APK redistribution concerns
 *
 * Limitations:
 *   - Only ONE Work Profile per device → max 1 clone per app
 *   - Requires Device Admin permission → user must activate
 *   - Some vendor ROMs (MIUI) have broken Work Profile implementation
 *
 * Architecture:
 *   DevicePolicyManager → manages Work Profile lifecycle
 *   PackageManager → install/uninstall apps in Work Profile
 *   HablasDeviceAdminReceiver → required component for Device Admin
 */
class WorkProfileEngine(private val context: Context) {

    private val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    private val adminComponent = ComponentName(context, HablasDeviceAdminReceiver::class.java)
    private val pm = context.packageManager

    // ─── Work Profile Status ──────────────────────────────────────────

    /**
     * Checks if a Work Profile is already set up on this device.
     */
    fun isWorkProfileSetup(): Boolean {
        // Android provides this via UserManager or DevicePolicyManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                // Check if our admin component is active in a work profile
                return dpm.isProfileOwnerApp(adminComponent.packageName)
            } catch (e: Exception) {
                return false
            }
        }
        return false
    }

    /**
     * Checks if Work Profile feature is available on this device.
     * Some devices (especially Chinese ROMs) may not support it.
     */
    fun isWorkProfileAvailable(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                // ACTION_MANAGED_PROFILE_PROVISIONED is available
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

    /**
     * Starts the Work Profile provisioning flow.
     * This launches a system activity that guides the user through setup.
     *
     * Returns:
     *   - true if provisioning intent was successfully launched
     *   - false if Work Profile is already setup or not available
     */
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
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                intent.putExtra(
                    DevicePolicyManager.EXTRA_PROVISIONING_ORGANIZATION_NAME,
                    "Hablas Clone"
                )
            }

            // Support color for the work profile badge
            intent.putExtra(
                DevicePolicyManager.EXTRA_PROVISIONING_MAIN_COLOR,
                0x0000F2FE.toInt() // Liquid Cyan #00F2FE
            )

            // Verify the intent can be handled
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

    /**
     * Installs an app into the Work Profile.
     * This effectively "clones" the app into the isolated space.
     *
     * After installation, the app runs with its own:
     *   - Storage (separate files, databases, shared prefs)
     *   - Accounts (separate login sessions)
     *   - Permissions (separate permission grants)
     *
     * @param packageName The package name of the app to install
     * @return true if installation was initiated successfully
     */
    fun installAppInWorkProfile(packageName: String): Boolean {
        if (!isWorkProfileSetup()) return false

        try {
            // Enable the app in work profile (it might be frozen/disabled)
            dpm.enablePackage(adminComponent, packageName)

            // If the app isn't installed in work profile yet, we need
            // to install it via package installer
            val installIntent = Intent(Intent.ACTION_INSTALL_PACKAGE)
            installIntent.data = Uri.fromParts("package", packageName, null)
            installIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

            // Send intent to work profile's package installer
            val workProfileIntent = Intent(Intent.ACTION_MAIN)
            workProfileIntent.setPackage(packageName)
            workProfileIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

            // Check if app exists in work profile
            try {
                val workProfileAppInfo = pm.getApplicationInfo(packageName, 0)
                // App already exists → just enable it
                return true
            } catch (e: PackageManager.NameNotFoundException) {
                // App not in work profile → install it
                // Use the original app's APK path as source
                val mainAppInfo = pm.getApplicationInfo(packageName, 0)
                val apkPath = mainAppInfo.sourceDir

                // Install APK into work profile
                dpm.installExistingPackage(adminComponent, packageName)
                return true
            }
        } catch (e: Exception) {
            return false
        }
    }

    /**
     * Launches an app in the Work Profile.
     */
    fun launchAppInWorkProfile(packageName: String): Boolean {
        if (!isWorkProfileSetup()) return false

        try {
            // Enable the app first (if frozen)
            dpm.enablePackage(adminComponent, packageName)

            // Get launch intent for the work profile version
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

    /**
     * Freezes (disables) an app in the Work Profile.
     * This prevents the app from running or being woken up.
     * Privacy feature: frozen apps can't track you.
     */
    fun freezeApp(packageName: String): Boolean {
        if (!isWorkProfileSetup()) return false

        try {
            dpm.disablePackage(adminComponent, packageName)
            return true
        } catch (e: Exception) {
            return false
        }
    }

    /**
     * Unfreezes (enables) a previously frozen app.
     */
    fun unfreezeApp(packageName: String): Boolean {
        if (!isWorkProfileSetup()) return false

        try {
            dpm.enablePackage(adminComponent, packageName)
            return true
        } catch (e: Exception) {
            return false
        }
    }

    /**
     * Checks if an app is frozen in the Work Profile.
     */
    fun isAppFrozen(packageName: String): Boolean {
        try {
            val appInfo = pm.getApplicationInfo(packageName, 0)
            return !appInfo.enabled
        } catch (e: PackageManager.NameNotFoundException) {
            return false
        }
    }

    /**
     * Removes (uninstalls) an app from the Work Profile.
     */
    fun removeAppFromWorkProfile(packageName: String): Boolean {
        if (!isWorkProfileSetup()) return false

        try {
            dpm.uninstallPackage(adminComponent, packageName)
            return true
        } catch (e: Exception) {
            return false
        }
    }

    /**
     * Gets all apps installed in the Work Profile.
     */
    fun getWorkProfileApps(): List<String> {
        if (!isWorkProfileSetup()) return emptyList()

        try {
            val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
            return apps
                .filter { it.flags and ApplicationInfo.FLAG_SYSTEM == 0 }
                .filter { it.packageName != context.packageName }
                .map { it.packageName }
        } catch (e: Exception) {
            return emptyList()
        }
    }

    // ─── Work Profile Removal ───────────────────────────────────────────

    /**
     * Removes the entire Work Profile and all its data.
     * This is a destructive operation — all cloned apps and their data will be lost.
     */
    fun removeWorkProfile(): Boolean {
        if (!isWorkProfileSetup()) return false

        try {
            dpm.clearProfileOwner(adminComponent)
            // The system will automatically remove the work profile
            return true
        } catch (e: Exception) {
            return false
        }
    }

    // ─── MethodChannel Interface ────────────────────────────────────────

    /**
     * Handle MethodChannel calls for Work Profile operations.
     */
    fun handleMethodCall(method: String, args: Map<String, Any?>?): Any? {
        return when (method) {
            "isWorkProfileSetup" -> isWorkProfileSetup()
            "isWorkProfileAvailable" -> isWorkProfileAvailable()
            "installAppInWorkProfile" -> {
                val packageName = args?.get("packageName") as? String ?: return false
                installAppInWorkProfile(packageName)
            }
            "launchAppInWorkProfile" -> {
                val packageName = args?.get("packageName") as? String ?: return false
                launchAppInWorkProfile(packageName)
            }
            "freezeApp" -> {
                val packageName = args?.get("packageName") as? String ?: return false
                freezeApp(packageName)
            }
            "unfreezeApp" -> {
                val packageName = args?.get("packageName") as? String ?: return false
                unfreezeApp(packageName)
            }
            "isAppFrozen" -> {
                val packageName = args?.get("packageName") as? String ?: return false
                isAppFrozen(packageName)
            }
            "removeAppFromWorkProfile" -> {
                val packageName = args?.get("packageName") as? String ?: return false
                removeAppFromWorkProfile(packageName)
            }
            "getWorkProfileApps" -> getWorkProfileApps()
            "removeWorkProfile" -> removeWorkProfile()
            else -> null
        }
    }

    companion object {
        const val PROVISIONING_REQUEST_CODE = 10001
    }
}
