package com.nickdegs.movelog.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.ui.draw.clip
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Block
import androidx.compose.material3.*
import androidx.compose.ui.Alignment
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nickdegs.movelog.data.Store
import com.nickdegs.movelog.ui.L
import com.nickdegs.movelog.ui.theme.Brand
import kotlinx.coroutines.launch

private data class Opt(val id: String, val label: String)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GenerateSheet(store: Store, from: Double, to: Double, type: String, onClose: () -> Unit) {
    val scope = rememberCoroutineScope()
    var mode by remember { mutableStateOf("flyover") }
    var speed by remember { mutableStateOf("medium") }
    var aspect by remember { mutableStateOf("16:9") }
    var cam by remember { mutableStateOf("orta") }
    var music by remember { mutableStateOf("") }
    var line by remember { mutableStateOf("#00E5FF") }
    var stock by remember { mutableStateOf<List<Pair<String, String>>>(emptyList()) }
    var busy by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { stock = store.musicList() }

    val modes = listOf(Opt("flat", L("Düz", "Flat")), Opt("flyover", "Flyover"), Opt("3d", L("3B", "3D")))
    val speeds = listOf(Opt("fast", L("Kısa", "Short")), Opt("medium", L("Orta", "Medium")),
        Opt("slow", L("Uzun", "Long")), Opt("auto", L("Otonom", "Auto")))
    val aspects = listOf(Opt("16:9", "16:9"), Opt("9:16", "9:16"))
    val cams = listOf(Opt("yakin", L("Yakın", "Near")), Opt("orta", L("Orta", "Medium")), Opt("uzak", L("Uzak", "Far")))
    val lineColors = listOf("#00E5FF", "#FF3B30", "#39FF14", "#FFD60A", "#FF7AB6", "#FFFFFF", "#7C4DFF", "#FF8C00")

    ModalBottomSheet(onDismissRequest = onClose, containerColor = Brand.card) {
        Column(Modifier.padding(horizontal = 20.dp).padding(bottom = 28.dp).verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Text(L("Video oluştur", "Create video"), fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Color.White)
            Picker(L("Görünüm", "Mode"), modes, mode) { mode = it }
            Picker(L("Süre", "Duration"), speeds, speed) { speed = it }
            Picker(L("En-boy", "Aspect"), aspects, aspect) { aspect = it }
            Picker(L("Kamera mesafesi", "Camera distance"), cams, cam) { cam = it }
            val musicOpts = listOf(Opt("", L("Yok", "None"))) + stock.map { Opt("stock:${it.first}", it.second) }
            Picker(L("Müzik", "Music"), musicOpts, music) { music = it }
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(L("Rota çizgisi", "Route line"), color = Color(0xFF9AA4B2), fontSize = 13.sp)
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    // Çizgisiz (sadece nokta) seçeneği
                    Box(Modifier.size(34.dp)
                        .clip(androidx.compose.foundation.shape.CircleShape)
                        .background(Color(0xFF2A3340))
                        .border(if (line == "none") 3.dp else 0.dp, Color.White, androidx.compose.foundation.shape.CircleShape)
                        .clickable { line = "none" }, contentAlignment = Alignment.Center) {
                        Icon(Icons.Filled.Block, L("Çizgisiz", "No line"), tint = Color(0xFF9AA4B2), modifier = Modifier.size(18.dp))
                    }
                    lineColors.forEach { hex ->
                        Box(Modifier.size(34.dp)
                            .clip(androidx.compose.foundation.shape.CircleShape)
                            .background(Color(android.graphics.Color.parseColor(hex)))
                            .border(if (line.equals(hex, true)) 3.dp else 0.dp, Color.White, androidx.compose.foundation.shape.CircleShape)
                            .clickable { line = hex })
                    }
                }
            }
            Button(
                onClick = {
                    busy = true
                    scope.launch {
                        val ok = store.generate(from, to, type, mode, aspect, speed, cam, music, line)
                        busy = false
                        if (ok) onClose()
                    }
                },
                enabled = !busy,
                colors = ButtonDefaults.buttonColors(containerColor = Brand.accent),
                modifier = Modifier.fillMaxWidth().height(50.dp)
            ) {
                if (busy) CircularProgressIndicator(Modifier.size(20.dp), color = Color.White, strokeWidth = 2.dp)
                else Text(L("Video oluştur", "Create video"), fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun Picker(title: String, opts: List<Opt>, sel: String, onSel: (String) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(title, color = Color(0xFF9AA4B2), fontSize = 13.sp)
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            opts.forEach { o ->
                FilterChip(
                    selected = sel == o.id, onClick = { onSel(o.id) },
                    label = { Text(o.label) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = Brand.accent,
                        selectedLabelColor = Color.White,
                    )
                )
            }
        }
    }
}
