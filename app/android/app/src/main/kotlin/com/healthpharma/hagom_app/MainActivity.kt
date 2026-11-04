package com.healthpharma.hagom_app

import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.healthpharma.hagom_app/export"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "downloadCsv" -> {
                    val fileName = call.argument<String>("fileName") ?: "하곰이_건강기록.csv"
                    val content = call.argument<String>("content") ?: ""

                    try {
                        var savedPath = ""

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val values = ContentValues().apply {
                                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                                put(MediaStore.MediaColumns.MIME_TYPE, "text/csv")
                                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                            }
                            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                            if (uri != null) {
                                contentResolver.openOutputStream(uri)?.use { output ->
                                    output.write(content.toByteArray(Charsets.UTF_8))
                                }
                                savedPath = "다운로드 폴더 ($fileName)"
                            }
                        } else {
                            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                            val file = File(downloadsDir, fileName)
                            FileOutputStream(file).use { output ->
                                output.write(content.toByteArray(Charsets.UTF_8))
                            }
                            savedPath = file.absolutePath
                        }

                        val cacheFile = File(cacheDir, fileName)
                        FileOutputStream(cacheFile).use { output ->
                            output.write(content.toByteArray(Charsets.UTF_8))
                        }

                        result.success(mapOf("success" to true, "path" to savedPath, "fileName" to fileName))
                    } catch (e: Exception) {
                        result.error("EXPORT_ERROR", e.message, null)
                    }
                }

                "shareCsv" -> {
                    val fileName = call.argument<String>("fileName") ?: "하곰이_건강기록.csv"
                    val content = call.argument<String>("content") ?: ""

                    try {
                        val cacheFile = File(cacheDir, fileName)
                        FileOutputStream(cacheFile).use { output ->
                            output.write(content.toByteArray(Charsets.UTF_8))
                        }

                        val fileUri: Uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            cacheFile
                        )

                        // 카카오톡 등은 EXTRA_TEXT가 함께 있으면 텍스트만 공유하고 파일을 버리거나,
                        // */* 와일드카드를 거부한다. text/csv + ClipData + 패키지별 URI 권한 부여가 정석.
                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/csv"
                            putExtra(Intent.EXTRA_STREAM, fileUri)
                            clipData = ClipData.newRawUri(fileName, fileUri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }

                        val resInfoList = packageManager.queryIntentActivities(
                            shareIntent,
                            PackageManager.MATCH_DEFAULT_ONLY
                        )
                        for (resolveInfo in resInfoList) {
                            val pkgName = resolveInfo.activityInfo.packageName
                            grantUriPermission(
                                pkgName,
                                fileUri,
                                Intent.FLAG_GRANT_READ_URI_PERMISSION
                            )
                        }

                        val chooser = Intent.createChooser(shareIntent, "건강 기록 파일 전송 및 저장").apply {
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }

                        startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
