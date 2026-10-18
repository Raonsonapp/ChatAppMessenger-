package com.example.chatapp

import android.content.ComponentName
import android.content.pm.PackageManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.content.FileProvider
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "chatapp/launcher_icon"
        private const val UPDATE_CHANNEL = "chatapp/update_installer"
        private const val PREFIX = "com.example.chatapp.MainActivityIcon"
        private const val COUNT = 10
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canRequestInstallPackages" -> {
                    result.success(Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls())
                }
                "openInstallPermissionSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")))
                    }
                    result.success(null)
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("invalid_path", "APK path is missing", null)
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
                        result.success("permission_required")
                    } else {
                        try {
                            val apk = File(path)
                            if (!apk.isFile || apk.length() < 1024 * 1024) {
                                result.error("invalid_apk", "APK file is missing or incomplete", null)
                            } else {
                                val uri = FileProvider.getUriForFile(this, "$packageName.updateprovider", apk)
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(uri, "application/vnd.android.package-archive")
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success("installer_opened")
                            }
                        } catch (e: Exception) {
                            result.error("install_failed", e.message ?: "Could not open installer", null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSelectedIcon" -> result.success(getSelectedIcon())
                "setLauncherIcon" -> {
                    val number = call.argument<Int>("icon")
                    if (number == null || number !in 1..COUNT) {
                        result.error("invalid_icon", "Icon must be from 1 to $COUNT", null)
                    } else {
                        try {
                            setLauncherIcon(number)
                            result.success(number)
                        } catch (e: Exception) {
                            result.error("icon_switch_failed", e.message ?: "Could not change app icon", null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun component(number: Int) = ComponentName(packageName, "$PREFIX${number.toString().padStart(2, '0')}")

    private fun getSelectedIcon(): Int {
        for (number in 1..COUNT) {
            val state = packageManager.getComponentEnabledSetting(component(number))
            val enabled = when (state) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED -> false
                else -> number == 1 // manifest default: alias 01 enabled, others disabled
            }
            if (enabled) return number
        }
        return 1
    }

    private fun setLauncherIcon(selected: Int) {
        // Enable the new launcher component first to avoid a moment without a launcher entry.
        packageManager.setComponentEnabledSetting(
            component(selected), PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )
        for (number in 1..COUNT) {
            if (number != selected) {
                packageManager.setComponentEnabledSetting(
                    component(number), PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
            }
        }
    }
}
