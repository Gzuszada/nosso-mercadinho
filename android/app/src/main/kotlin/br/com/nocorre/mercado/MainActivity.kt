package br.com.nocorre.mercado

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private data class PendingBackupSave(
        val contents: String,
        val disallowSameUri: String?,
        val result: MethodChannel.Result,
    )

    private var pendingBackupOpen: MethodChannel.Result? = null
    private var pendingBackupSave: PendingBackupSave? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BACKUP_FILE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openJson" -> openJson(result)
                "saveJson" -> saveJson(
                    call.argument("fileName"),
                    call.argument("contents"),
                    call.argument("disallowSameUri"),
                    result,
                )
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == OPEN_BACKUP_REQUEST_CODE) {
            onBackupOpenResult(resultCode, data)
            return
        }
        if (requestCode != SAVE_BACKUP_REQUEST_CODE) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }

        val pending = pendingBackupSave
        pendingBackupSave = null
        if (pending == null) {
            return
        }
        if (resultCode != Activity.RESULT_OK) {
            pending.result.success(false)
            return
        }

        val uri = data?.data
        if (uri == null) {
            pending.result.error(
                "backup_save_failed",
                "O seletor não retornou um local para salvar o backup.",
                null,
            )
            return
        }
        if (pending.disallowSameUri != null &&
            pending.disallowSameUri == uri.toString()
        ) {
            pending.result.error(
                "backup_destination_is_source",
                "Escolha um arquivo diferente para salvar o backup de segurança.",
                null,
            )
            return
        }

        Thread({
            try {
                writeBackup(uri, pending.contents)
                runOnUiThread { pending.result.success(true) }
            } catch (error: Exception) {
                runOnUiThread {
                    pending.result.error(
                        "backup_save_failed",
                        "Não foi possível salvar o backup selecionado.",
                        error.message,
                    )
                }
            }
        }, "mercado-backup-save").start()
    }

    @Suppress("DEPRECATION")
    private fun openJson(result: MethodChannel.Result) {
        if (pendingBackupOpen != null) {
            result.error(
                "backup_open_in_progress",
                "Já existe uma abertura de backup em andamento.",
                null,
            )
            return
        }

        pendingBackupOpen = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf(
                    "application/json",
                    "text/json",
                    "text/plain",
                    "application/octet-stream",
                ),
            )
        }
        try {
            startActivityForResult(intent, OPEN_BACKUP_REQUEST_CODE)
        } catch (error: Exception) {
            pendingBackupOpen = null
            result.error(
                "backup_picker_unavailable",
                "Não foi possível abrir o seletor de backup.",
                error.message,
            )
        }
    }

    private fun onBackupOpenResult(resultCode: Int, data: Intent?) {
        val result = pendingBackupOpen
        pendingBackupOpen = null
        if (result == null) {
            return
        }
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri = data?.data
        if (uri == null) {
            result.error(
                "backup_open_failed",
                "O seletor não retornou um arquivo para importar.",
                null,
            )
            return
        }

        Thread({
            try {
                val contents = contentResolver.openInputStream(uri)
                    ?.bufferedReader(Charsets.UTF_8)
                    ?.use { it.readText() }
                    ?: throw IOException("O arquivo selecionado não pôde ser lido.")
                runOnUiThread {
                    result.success(mapOf("contents" to contents, "uri" to uri.toString()))
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error(
                        "backup_open_failed",
                        "Não foi possível ler o arquivo de backup selecionado.",
                        error.message,
                    )
                }
            }
        }, "mercado-backup-open").start()
    }

    @Suppress("DEPRECATION")
    private fun saveJson(
        fileName: String?,
        contents: String?,
        disallowSameUri: String?,
        result: MethodChannel.Result,
    ) {
        if (pendingBackupSave != null) {
            result.error(
                "backup_save_in_progress",
                "Já existe um salvamento de backup em andamento.",
                null,
            )
            return
        }
        if (fileName.isNullOrBlank() || contents == null) {
            result.error(
                "invalid_backup",
                "O nome ou o conteúdo do backup está ausente.",
                null,
            )
            return
        }

        pendingBackupSave = PendingBackupSave(contents, disallowSameUri, result)
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/json"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        try {
            startActivityForResult(intent, SAVE_BACKUP_REQUEST_CODE)
        } catch (error: Exception) {
            pendingBackupSave = null
            result.error(
                "backup_picker_unavailable",
                "Não foi possível abrir o seletor de local para salvar.",
                error.message,
            )
        }
    }

    private fun writeBackup(uri: Uri, contents: String) {
        val output = contentResolver.openOutputStream(uri, "wt")
            ?: throw IOException("O local escolhido não permite gravar o arquivo.")
        output.use {
            it.write(contents.toByteArray(Charsets.UTF_8))
        }
    }

    private companion object {
        const val BACKUP_FILE_CHANNEL = "br.com.nocorre.mercado/backup_files"
        const val OPEN_BACKUP_REQUEST_CODE = 9087
        const val SAVE_BACKUP_REQUEST_CODE = 9086
    }
}
