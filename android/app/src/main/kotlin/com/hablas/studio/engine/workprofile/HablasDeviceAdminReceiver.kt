package com.hablas.studio.engine.workprofile

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Device Admin Receiver — Required component for Work Profile management.
 *
 * This class is required by Android's DevicePolicyManager API to
 * receive admin events and manage the Work Profile lifecycle.
 *
 * It must be declared in AndroidManifest.xml as a <receiver> with
 * BIND_DEVICE_ADMIN permission.
 */
class HablasDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.i(TAG, "Device Admin enabled")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.i(TAG, "Device Admin disabled")
    }

    override fun onProfileProvisioningComplete(context: Context, intent: Intent) {
        super.onProfileProvisioningComplete(context, intent)
        Log.i(TAG, "Work Profile provisioning complete")

        // Enable the profile so apps can run inside it
        val adminComponent = getComponentName(context)
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE)
            as android.app.admin.DevicePolicyManager

        // Set the profile name to "Hablas Clone"
        dpm.setProfileName(adminComponent, "Hablas Clone")

        // Disable our own app in the work profile (we only need it in main profile)
        // Actually we need it enabled for management, so keep it
    }

    companion object {
        private const val TAG = "HablasDeviceAdmin"

        fun getComponentName(context: Context): android.content.ComponentName {
            return android.content.ComponentName(
                context.packageName,
                HablasDeviceAdminReceiver::class.java.name
            )
        }
    }
}
