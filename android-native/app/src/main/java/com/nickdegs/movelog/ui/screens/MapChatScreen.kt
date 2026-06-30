package com.nickdegs.movelog.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.background
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nickdegs.movelog.data.Convo
import com.nickdegs.movelog.data.Position
import com.nickdegs.movelog.data.Store
import com.nickdegs.movelog.ui.L
import com.nickdegs.movelog.ui.theme.Brand

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MapChatScreen(store: Store) {
    var seg by remember { mutableStateOf(0) }   // 0 = Harita (canlı konum), 1 = Sohbet
    Column(Modifier.fillMaxSize().padding(16.dp)) {
        SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(bottom = 12.dp)) {
            SegmentedButton(selected = seg == 0, onClick = { seg = 0 },
                shape = SegmentedButtonDefaults.itemShape(0, 2)) { Text(L("Harita", "Map")) }
            SegmentedButton(selected = seg == 1, onClick = { seg = 1 },
                shape = SegmentedButtonDefaults.itemShape(1, 2)) { Text(L("Sohbet", "Chat")) }
        }
        if (seg == 0) MapPane(store) else ChatPane(store)
    }
}

@Composable
private fun MapPane(store: Store) {
    var pos by remember { mutableStateOf<List<Position>>(emptyList()) }
    LaunchedEffect(Unit) { pos = store.positions() }
    if (pos.isEmpty()) Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text(L("Canlı konum yok", "No live locations"), color = Color(0xFF9AA4B2))
    }
    LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        items(pos) { p ->
            Surface(color = Brand.card, shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
                Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.LocationOn, null, tint = if (p.online) Brand.accent else Color(0xFF6B7280))
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(p.device, color = Color.White, fontWeight = FontWeight.SemiBold)
                        Text("%.5f, %.5f".format(p.lat, p.lon), color = Color(0xFF9AA4B2), fontSize = 12.sp)
                    }
                    Text("${p.speedKmh.toInt()} km/h", color = Brand.accent, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}

@Composable
private fun ChatPane(store: Store) {
    var convos by remember { mutableStateOf<List<Convo>>(emptyList()) }
    LaunchedEffect(Unit) { convos = store.conversations() }
    if (convos.isEmpty()) Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text(L("Henüz sohbet yok", "No chats yet"), color = Color(0xFF9AA4B2))
    }
    LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        items(convos) { c ->
            Surface(color = Brand.card, shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
                Row(Modifier.padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(44.dp).background(Brand.gradient, CircleShape), contentAlignment = Alignment.Center) {
                        Text((c.name ?: c.username).take(1).uppercase(), color = Color.White, fontWeight = FontWeight.Bold)
                    }
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(c.name ?: c.username, color = Color.White, fontWeight = FontWeight.SemiBold)
                        Text("@${c.username}", color = Color(0xFF9AA4B2), fontSize = 12.sp)
                    }
                    if (c.unread > 0) Badge(containerColor = Brand.accent) { Text("${c.unread}") }
                }
            }
        }
    }
}
