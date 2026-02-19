package com.lectra.app

import android.content.Intent
import android.net.Uri
import android.os.Environment
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.lectra.app/camera"
    private val REQUEST_OPEN_CAMERA = 1001
    private var pendingResult: MethodChannel.Result? = null
    private var photoUri: Uri? = null
    private var photoPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openCamera") {
                pendingResult = result
                openOpenCamera()
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openOpenCamera() {
        try {
            // Crear archivo temporal para guardar la foto
            val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val imageFileName = "LECTRA_$timeStamp.jpg"
            val storageDir = getExternalFilesDir(Environment.DIRECTORY_PICTURES)
            val imageFile = File(storageDir, imageFileName)
            photoPath = imageFile.absolutePath
            
            // Crear URI usando FileProvider
            photoUri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                imageFile
            )

            // Intent para Open Camera
            val intent = Intent("android.media.action.IMAGE_CAPTURE")
            intent.setPackage("net.sourceforge.opencamera")
            intent.putExtra(android.provider.MediaStore.EXTRA_OUTPUT, photoUri)
            intent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            
            // Verificar si Open Camera está instalada
            if (intent.resolveActivity(packageManager) != null) {
                startActivityForResult(intent, REQUEST_OPEN_CAMERA)
            } else {
                // Si Open Camera no está instalada, usar cámara nativa
                intent.setPackage(null) // Remover el package específico
                startActivityForResult(intent, REQUEST_OPEN_CAMERA)
            }
        } catch (e: Exception) {
            pendingResult?.error("CAMERA_ERROR", "Error al abrir cámara: ${e.message}", null)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_OPEN_CAMERA) {
            if (resultCode == RESULT_OK) {
                // La foto fue capturada exitosamente
                pendingResult?.success(photoPath)
            } else {
                // El usuario canceló
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }
}
