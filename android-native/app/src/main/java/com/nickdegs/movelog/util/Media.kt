package com.nickdegs.movelog.util

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore

// mp4 baytlarını galeriye (Movies/MoveLog) kaydet. API 29+ izin gerekmez.
fun saveVideoToGallery(ctx: Context, bytes: ByteArray, name: String): Boolean {
    return try {
        val resolver = ctx.contentResolver
        val cv = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, name)
            put(MediaStore.Video.Media.MIME_TYPE, "video/mp4")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Video.Media.RELATIVE_PATH, Environment.DIRECTORY_MOVIES + "/MoveLog")
                put(MediaStore.Video.Media.IS_PENDING, 1)
            }
        }
        val uri = resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, cv) ?: return false
        resolver.openOutputStream(uri)?.use { it.write(bytes) } ?: return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            cv.clear(); cv.put(MediaStore.Video.Media.IS_PENDING, 0); resolver.update(uri, cv, null, null)
        }
        true
    } catch (e: Exception) { false }
}
