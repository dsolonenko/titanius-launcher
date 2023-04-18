package app.titanius.launcher

import android.content.ContentUris
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "file_utils"

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
