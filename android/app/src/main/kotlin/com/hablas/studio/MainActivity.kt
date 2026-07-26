package com.hablas.studio

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.hablas.studio.engine.VirtualEngineManager

/**
 * Hablas Virtual Studio — Main Activity
 *
 * Serves as the Flutter host activity and the MethodChannel bridge endpoint
 * for the native virtualization engine. All communication between the Dart
 * UI layer and the Android native subsystem flows through this activity.
 */
class MainActivity : FlutterActivity() {

    private lateinit var engineManager: VirtualEngineManager

    companion object {
        private const val ENGINE_CHANNEL = "com.hablas.studio/engine"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        engineManager = VirtualEngineManager(context = this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENGINE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // ─── App Discovery ─────────────────────────────────────
                    "getSystemInstalledApps" -> {
                        val apps = engineManager.getSystemInstalledApps()
                        result.success(apps)
                    }

                    // ─── Instance Lifecycle ────────────────────────────────
                    "createVirtualInstance" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName == null) {
                            result.error("INVALID_ARGS", "packageName is required", null)
                            return@setMethodCallHandler
                        }
                        val instanceId = engineManager.createVirtualInstance(packageName)
                        result.success(instanceId)
                    }

                    "launchVirtualInstance" -> {
                        val packageName = call.argument<String>("packageName")
                        val instanceId = call.argument<Int>("instanceId")
                        if (packageName == null || instanceId == null) {
                            result.error("INVALID_ARGS", "packageName and instanceId are required", null)
                            return@setMethodCallHandler
                        }
                        val success = engineManager.launchVirtualInstance(packageName, instanceId)
                        result.success(success)
                    }

                    "terminateVirtualInstance" -> {
                        val packageName = call.argument<String>("packageName")
                        val instanceId = call.argument<Int>("instanceId")
                        if (packageName == null || instanceId == null) {
                            result.error("INVALID_ARGS", "packageName and instanceId are required", null)
                            return@setMethodCallHandler
                        }
                        val success = engineManager.terminateVirtualInstance(packageName, instanceId)
                        result.success(success)
                    }

                    // ─── Storage Management ────────────────────────────────
                    "getVirtualInstanceStorageSize" -> {
                        val packageName = call.argument<String>("packageName")
                        val instanceId = call.argument<Int>("instanceId")
                        if (packageName == null || instanceId == null) {
                            result.error("INVALID_ARGS", "packageName and instanceId are required", null)
                            return@setMethodCallHandler
                        }
                        val size = engineManager.getVirtualInstanceStorageSize(packageName, instanceId)
                        result.success(size)
                    }

                    "clearInstanceCache" -> {
                        val packageName = call.argument<String>("packageName")
                        val instanceId = call.argument<Int>("instanceId")
                        if (packageName == null || instanceId == null) {
                            result.error("INVALID_ARGS", "packageName and instanceId are required", null)
                            return@setMethodCallHandler
                        }
                        val success = engineManager.clearInstanceCache(packageName, instanceId)
                        result.success(success)
                    }

                    // ─── Bulk Operations ──────────────────────────────────
                    "getAllInstances" -> {
                        val instances = engineManager.getAllInstances()
                        result.success(instances)
                    }

                    "deleteVirtualInstance" -> {
                        val packageName = call.argument<String>("packageName")
                        val instanceId = call.argument<Int>("instanceId")
                        if (packageName == null || instanceId == null) {
                            result.error("INVALID_ARGS", "packageName and instanceId are required", null)
                            return@setMethodCallHandler
                        }
                        val success = engineManager.deleteVirtualInstance(packageName, instanceId)
                        result.success(success)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Ensure all virtual instances are properly terminated
        if (::engineManager.isInitialized) {
            engineManager.shutdownAll()
        }
    }
}
