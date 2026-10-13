package com.euroside.siteflow_admin

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import androidx.core.content.FileProvider

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "com.euroside.siteflow_admin/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "savePdf", "saveFile" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val requestedName = call.argument<String>("fileName") ?: "download"
                        val mimeType = call.argument<String>("mimeType") ?: if (call.method == "savePdf") "application/pdf" else "application/octet-stream"
                        val fileName = requestedName.replace(Regex("[^A-Za-z0-9._-]"), "_")
                        if (bytes == null || bytes.isEmpty()) {
                            result.error("INVALID_FILE", "Downloaded file data is empty.", null)
                            return@setMethodCallHandler
                        }

                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                val values = ContentValues().apply {
                                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                                    put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/Euroside")
                                    put(MediaStore.Downloads.IS_PENDING, 1)
                                }
                                val resolver = contentResolver
                                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                                    ?: throw IllegalStateException("Unable to create download")
                                resolver.openOutputStream(uri)?.use { it.write(bytes) }
                                    ?: throw IllegalStateException("Unable to write download")
                                values.clear()
                                values.put(MediaStore.Downloads.IS_PENDING, 0)
                                resolver.update(uri, values, null, null)
                                result.success(uri.toString())
                            } else {
                                @Suppress("DEPRECATION")
                                val downloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                                val folder = File(downloads, "Euroside")
                                if (!folder.exists() && !folder.mkdirs()) throw IllegalStateException("Unable to create Downloads folder")
                                val output = File(folder, fileName)
                                FileOutputStream(output).use { it.write(bytes) }
                                result.success(output.absolutePath)
                            }
                        } catch (error: Exception) {
                            result.error("SAVE_FAILED", error.message, null)
                        }
                    }
                    "openFile" -> {
                        try {
                            val location = call.argument<String>("location") ?: throw IllegalArgumentException("Missing file location")
                            val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                            val uri = if (location.startsWith("content://")) {
                                Uri.parse(location)
                            } else {
                                FileProvider.getUriForFile(this, "${applicationContext.packageName}.fileprovider", File(location))
                            }
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, mimeType)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("OPEN_FAILED", error.message, null)
                        }
                    }
                    "deleteFile" -> {
                        try {
                            val location = call.argument<String>("location") ?: throw IllegalArgumentException("Missing file location")
                            val deleted = if (location.startsWith("content://")) {
                                contentResolver.delete(Uri.parse(location), null, null)
                                true
                            } else {
                                val file = File(location)
                                !file.exists() || file.delete()
                            }
                            result.success(deleted)
                        } catch (error: Exception) {
                            result.error("DELETE_FAILED", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
