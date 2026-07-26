package com.hablas.studio

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.hablas.studio.engine.VirtualEngineManager

/**
 * Hablas Clone — Main Activity
 *
 * Serves as the Flutter host activity and the MethodChannel bridge endpoint
 * for the native virtualization engine. All communication between the Dart
 * UI layer and the Android native subsystem flows through this activity.
 *
 * IMPROVED (v2):
 *   1. Added isHealthy check method
 *   2. launchVirtualInstance now ACTUALLY launches apps via Intent
 *   3. Better error messages for debugging
 *   4. Package validation before creating instances
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
                try {
                    when (call.method) {
                        // ─── Health Check ────────────────────────────────────
                        "isHealthy" -> {
                            result.success(engineManager.isHealthy())
                        }

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
                            try {
                                val instanceId = engineManager.createVirtualInstance(packageName)
                                result.success(instanceId)
                            } catch (e: IllegalArgumentException) {
                                result.error("PACKAGE_NOT_FOUND", e.message, null)
                            } catch (e: IllegalStateException) {
                                result.error("SANDBOX_ERROR", e.message, null)
                            }
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
                } catch (e: Exception) {
                    result.error("ENGINE_ERROR", "Unexpected error: ${e.message}", e.stackTraceToString())
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::engineManager.isInitialized) {
            engineManager.shutdownAll()
        }
    }
}
