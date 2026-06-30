package com.nickdegs.movelog.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.background
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
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
    val ctx = androidx.compose.ui.platform.LocalContext.current
    val scope = androidx.compose.runtime.rememberCoroutineScope()
    var recording by remember { mutableStateOf(com.nickdegs.movelog.TrackingService.active) }
    val perm = androidx.activity.compose.rememberLauncherForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.RequestMultiplePermissions()
    ) { res ->
        if (res[android.Manifest.permission.ACCESS_FINE_LOCATION] == true) {
            scope.launch {
                val t = store.trackerInfo()
                if (t != null) { com.nickdegs.movelog.TrackingService.start(ctx, t.first, t.second); recording = true }
            }
        }
    }
    LaunchedEffect(Unit) { pos = store.positions() }

    Button(
        onClick = {
            if (recording) { com.nickdegs.movelog.TrackingService.stop(ctx); recording = false }
            else perm.launch(arrayOf(
                android.Manifest.permission.ACCESS_FINE_LOCATION,
                android.Manifest.permission.ACCESS_BACKGROUND_LOCATION,
                android.Manifest.permission.POST_NOTIFICATIONS))
        },
        colors = androidx.compose.material3.ButtonDefaults.buttonColors(
            containerColor = if (recording) androidx.compose.ui.graphics.Color(0xFFFF3B30) else Brand.accent),
        modifier = Modifier.fillMaxWidth().padding(bottom = 12.dp)
    ) {
        Icon(if (recording) Icons.Filled.Stop else Icons.Filled.FiberManualRecord, null)
        Spacer(Modifier.width(8.dp))
        Text(if (recording) L("Kaydı durdur", "Stop recording") else L("Rota kaydını başlat", "Start recording"))
    }

    // Gerçek harita (OpenStreetMap — Maps API key gerekmez), konumlar marker
    androidx.compose.ui.viewinterop.AndroidView(
        factory = { c ->
            org.osmdroid.config.Configuration.getInstance().userAgentValue = c.packageName
            org.osmdroid.views.MapView(c).apply {
                setTileSource(org.osmdroid.tileprovider.tilesource.TileSourceFactory.MAPNIK)
                setMultiTouchControls(true); controller.setZoom(13.5)
            }
        },
        update = { map ->
            map.overlays.clear()
            pos.forEach { p ->
                val mk = org.osmdroid.views.overlay.Marker(map)
                mk.position = org.osmdroid.util.GeoPoint(p.lat, p.lon)
                mk.title = "${p.device} · ${p.speedKmh.toInt()} km/h"
                mk.setAnchor(org.osmdroid.views.overlay.Marker.ANCHOR_CENTER, org.osmdroid.views.overlay.Marker.ANCHOR_BOTTOM)
                map.overlays.add(mk)
            }
            pos.firstOrNull()?.let { map.controller.setCenter(org.osmdroid.util.GeoPoint(it.lat, it.lon)) }
            map.invalidate()
        },
        modifier = Modifier.fillMaxSize().clip(RoundedCornerShape(16.dp))
    )
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
