package com.keyflow.keyflow

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import com.keyflow.keyflow.keyboard.bridge.ConfigStore
import com.keyflow.keyflow.keyboard.layouts.LayoutRepository
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

/** Flutter <-> native bridge. Only configuration and keyboard-status calls; never typed text. */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val store = ConfigStore(this)
        val repo = LayoutRepository(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "keyflow/keyboard").setMethodCallHandler { call, result ->
            when (call.method) {
                "isEnabled" -> result.success(isEnabled())
                "isDefault" -> result.success(isDefault())
                "openInputSettings" -> { startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)); result.success(true) }
                "showInputPicker" -> {
                    (getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager).showInputMethodPicker()
                    result.success(true)
                }
                "saveConfig" -> try {
                    store.saveRaw(call.arguments as String); result.success(true)
                } catch (e: Exception) { result.error("invalid_config", "Invalid configuration", null) }
                "loadConfig" -> result.success(store.rawOrNull() ?: ConfigStore.DEFAULT)
                "listLayouts" -> {
                    val arr = JSONArray()
                    repo.all().keys.forEach { id -> repo.rawJson(id)?.let { arr.put(it) } }
                    result.success(arr.toString())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isEnabled(): Boolean {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        return imm.enabledInputMethodList.any { it.packageName == packageName }
    }

    private fun isDefault(): Boolean {
        val id = Settings.Secure.getString(contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD) ?: return false
        return id.startsWith("$packageName/")
    }
}
