package app.titanius.launcher

import android.content.ContentUris
import android.content.ContentResolver
import android.content.Intent
import android.hardware.input.InputManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.provider.MediaStore
import android.view.KeyEvent
import android.view.MotionEvent
import androidx.annotation.RequiresApi
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.flame_engine.gamepads_android.GamepadsCompatibleActivity
import java.io.File

class MainActivity : FlutterActivity(), GamepadsCompatibleActivity {
    private val CHANNEL = "file_utils"
    private var gamepadKeyHandler: ((KeyEvent) -> Boolean)? = null
    private var gamepadMotionHandler: ((MotionEvent) -> Boolean)? = null

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (gamepadKeyHandler?.invoke(event) == true) {
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
        if (gamepadMotionHandler?.invoke(event) == true) {
            return true
        }
        return super.dispatchGenericMotionEvent(event)
    }

    override fun registerInputDeviceListener(
        listener: InputManager.InputDeviceListener,
        handler: Handler?,
    ) {
        val inputManager = getSystemService(INPUT_SERVICE) as InputManager
        inputManager.registerInputDeviceListener(listener, handler)
    }

    override fun registerKeyEventHandler(handler: (KeyEvent) -> Boolean) {
        gamepadKeyHandler = handler
    }

    override fun registerMotionEventHandler(handler: (MotionEvent) -> Boolean) {
        gamepadMotionHandler = handler
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getContentUri") {
                val path = call.argument<String>("path")
                if (path != null) {
                    val contentUri = getContentUriFromFilePath(path)
                    if (contentUri != null) {
                        result.success(contentUri)
                    } else {
                        result.error("INVALID_URI", "Invalid URI", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getContentUriFromFilePath(filePath: String): String? {
        try {
            val file = File(filePath)
            return FileProvider.getUriForFile(
                applicationContext,
                "${applicationContext.packageName}.fileprovider",
                file
            ).toString()
        } catch (e: Exception) {
            val contentResolver = applicationContext.contentResolver
            val cursor = contentResolver.query(
                MediaStore.Files.getContentUri("external"),
                arrayOf(MediaStore.Files.FileColumns._ID),
                MediaStore.Files.FileColumns.DATA + "=?",
                arrayOf(filePath),
                null
            )

            var contentUri: String? = null
            if (cursor != null && cursor.moveToFirst()) {
                val id = cursor.getLong(cursor.getColumnIndex(MediaStore.Files.FileColumns._ID))
                contentUri = ContentUris.withAppendedId(MediaStore.Files.getContentUri("external"), id).toString()
                cursor.close()
            }

            return contentUri
        }
    }
}
