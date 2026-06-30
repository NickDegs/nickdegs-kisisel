package com.nickdegs.movelog.ui.screens

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.*
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
    var busy by remember { mutableStateOf(false) }

    val modes = listOf(Opt("flat", L("Düz", "Flat")), Opt("flyover", "Flyover"), Opt("3d", L("3B", "3D")))
    val speeds = listOf(Opt("fast", L("Kısa", "Short")), Opt("medium", L("Orta", "Medium")),
        Opt("slow", L("Uzun", "Long")), Opt("auto", L("Otonom", "Auto")))
    val aspects = listOf(Opt("16:9", "16:9"), Opt("9:16", "9:16"))
    val cams = listOf(Opt("yakin", L("Yakın", "Near")), Opt("orta", L("Orta", "Medium")), Opt("uzak", L("Uzak", "Far")))

    ModalBottomSheet(onDismissRequest = onClose, containerColor = Brand.card) {
        Column(Modifier.padding(horizontal = 20.dp).padding(bottom = 28.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Text(L("Video oluştur", "Create video"), fontSize = 22.sp, fontWeight = FontWeight.Bold, color = Color.White)
            Picker(L("Görünüm", "Mode"), modes, mode) { mode = it }
            Picker(L("Süre", "Duration"), speeds, speed) { speed = it }
            Picker(L("En-boy", "Aspect"), aspects, aspect) { aspect = it }
            Picker(L("Kamera mesafesi", "Camera distance"), cams, cam) { cam = it }
            Button(
                onClick = {
                    busy = true
                    scope.launch {
                        val ok = store.generate(from, to, type, mode, aspect, speed, cam)
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
