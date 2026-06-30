package com.nickdegs.movelog.data

import android.app.Application
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

const val API = "https://kisisel-api.nickdegs.com"

data class Ride(
    val id: String, val date: String, val type: String?, val mode: String?,
    val size: Double, val ts: Double?, val to: Double?, val aspect: String?,
    val speed: String?, val done: Double?, val rendering: Boolean, val novideo: Boolean,
)

data class Profile(val username: String?, val name: String, val premium: Boolean)

// iOS Store.swift'in Kotlin karşılığı — aynı backend (kisisel-api), aynı uçlar.
class Store(app: Application) : AndroidViewModel(app) {
    private val prefs = app.getSharedPreferences("movelog", Context.MODE_PRIVATE)

    var token by mutableStateOf(prefs.getString("nd_token", "") ?: "")
        private set
    var me by mutableStateOf("")
    var premium by mutableStateOf(prefs.getBoolean("nd_premium", false))
    var loginError by mutableStateOf(false)

    val loggedIn: Boolean get() = token.isNotEmpty()

    private fun persistToken(t: String) {
        token = t; prefs.edit().putString("nd_token", t).apply()
    }
    fun persistPremium(v: Boolean) {
        premium = v; prefs.edit().putBoolean("nd_premium", v).apply()
    }
    fun signOut() { persistToken(""); prefs.edit().remove("nd_token").apply() }

    // ---- HTTP yardımcısı (auth header + JSON) ----
    private suspend fun req(path: String, method: String = "GET", body: JSONObject? = null): String? =
        withContext(Dispatchers.IO) {
            try {
                val c = (URL(API + path).openConnection() as HttpURLConnection)
                c.requestMethod = method
                c.connectTimeout = 15000; c.readTimeout = 30000
                if (token.isNotEmpty()) c.setRequestProperty("Authorization", "Bearer $token")
                if (body != null) {
                    c.setRequestProperty("Content-Type", "application/json")
                    c.doOutput = true
                    OutputStreamWriter(c.outputStream).use { it.write(body.toString()) }
                }
                val code = c.responseCode
                val txt = (if (code in 200..299) c.inputStream else c.errorStream)
                    ?.bufferedReader()?.readText()
                if (code in 200..299) txt else null
            } catch (e: Exception) { null }
        }

    // ---- Auth (telefon + SMS tek-kullanımlık kod; iOS ile aynı) ----
    suspend fun smsStart(phone: String): Boolean =
        req("/api/auth/sms/start", "POST", JSONObject().put("phone", phone)) != null

    suspend fun smsVerify(phone: String, code: String): Boolean {
        val d = req("/api/auth/sms/verify", "POST",
            JSONObject().put("phone", phone).put("code", code)) ?: run { loginError = true; return false }
        val t = JSONObject(d).optString("token", "")
        if (t.isEmpty()) { loginError = true; return false }
        persistToken(t); loginError = false
        loadProfile()
        return true
    }

    // ---- Profil ----
    suspend fun loadProfile() {
        val d = req("/api/me") ?: return
        val o = JSONObject(d)
        me = o.optString("username", me)
        persistPremium(o.optBoolean("premium", premium))
    }

    // ---- Rotalar ----
    suspend fun rides(): List<Ride> {
        val d = req("/api/rides") ?: return emptyList()
        val arr = JSONObject(d).optJSONArray("rides") ?: JSONArray()
        return (0 until arr.length()).map { i ->
            val o = arr.getJSONObject(i)
            Ride(
                id = o.getString("id"), date = o.optString("date", ""),
                type = o.optString("type", null), mode = o.optString("mode", null),
                size = o.optDouble("size", 0.0),
                ts = if (o.has("ts")) o.optDouble("ts") else null,
                to = if (o.has("to")) o.optDouble("to") else null,
                aspect = o.optString("aspect", null), speed = o.optString("speed", null),
                done = if (o.has("done")) o.optDouble("done") else null,
                rendering = o.optBoolean("rendering", false),
                novideo = o.optBoolean("novideo", false),
            )
        }
    }

    fun videoUrl(id: String) = "$API/api/rides/$id/video"
    suspend fun signedVideoUrl(id: String): String? {
        val d = req("/api/rides/$id/videourl") ?: return null
        return JSONObject(d).optString("url", null)
    }

    suspend fun setRideType(id: String, type: String): Boolean =
        req("/api/rides/$id/type", "POST", JSONObject().put("type", type)) != null

    suspend fun deleteRide(id: String): Boolean =
        req("/api/rides/$id", "DELETE") != null

    // ---- Özetler (Özet sekmesi; iOS /api/activities) ----
    suspend fun summaries(): List<Summary> {
        val d = req("/api/activities") ?: return emptyList()
        val arr = JSONObject(d).optJSONArray("activities") ?: JSONArray()
        return (0 until arr.length()).map { i ->
            val o = arr.getJSONObject(i)
            Summary(o.optString("date", ""), o.optString("summary", ""),
                if (o.isNull("video_id")) null else o.optString("video_id", null))
        }
    }
    suspend fun summarizeToday(): Boolean = req("/api/activities/summarize", "POST", JSONObject()) != null
}

data class Summary(val date: String, val summary: String, val videoId: String?)
