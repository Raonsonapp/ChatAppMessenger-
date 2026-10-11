package com.example.chatapp

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "chatapp/launcher_icon"
        private const val PREFIX = "com.example.chatapp.MainActivityIcon"
        private const val COUNT = 10
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
