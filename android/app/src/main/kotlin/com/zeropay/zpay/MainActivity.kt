package com.zeropay.zpay

import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val launcherAliases = listOf("LauncherZPay", "LauncherQuickScan", "LauncherScannerUtility")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "zpay/app")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "finishTask" -> {
                        result.success(null)
                        finishAndRemoveTask()
                    }
                    "setLauncherAlias" -> {
                        val alias = call.arguments as String
                        if (alias in launcherAliases) {
                            setLauncherAlias(alias)
                            result.success(null)
                        } else {
                            result.error("invalid_alias", alias, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Enables the new alias first so the app is never left without a launcher entry.
    private fun setLauncherAlias(alias: String) {
        setAliasState(alias, PackageManager.COMPONENT_ENABLED_STATE_ENABLED)
        launcherAliases.filter { it != alias }.forEach {
            setAliasState(it, PackageManager.COMPONENT_ENABLED_STATE_DISABLED)
        }
    }

    private fun setAliasState(alias: String, state: Int) {
        packageManager.setComponentEnabledSetting(
            ComponentName(packageName, "$packageName.$alias"),
            state,
            PackageManager.DONT_KILL_APP,
        )
    }
}
