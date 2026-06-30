package com.nickdegs.movelog.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nickdegs.movelog.data.Ride
import com.nickdegs.movelog.data.Store
import com.nickdegs.movelog.ui.L
import com.nickdegs.movelog.ui.theme.Brand
import java.text.SimpleDateFormat
import java.util.*

private fun typeLabel(t: String?) = when (t) {
    "moto" -> L("Motosiklet", "Motorcycle"); "car" -> L("Araba", "Car")
    "bike" -> L("Bisiklet", "Cycling"); "run" -> L("Koşu", "Running")
    "walk" -> L("Yürüyüş", "Walking"); else -> L("Diğer", "Other")
}
private fun typeIcon(t: String?) = when (t) {
    "moto", "bike" -> Icons.Filled.TwoWheeler; "car" -> Icons.Filled.DirectionsCar
    "run" -> Icons.Filled.DirectionsRun; "walk" -> Icons.Filled.DirectionsWalk
    else -> Icons.Filled.Route
}
private fun dayTime(r: Ride): String {
    val ts = r.ts ?: return r.date
    val fmt = SimpleDateFormat(L("d MMM yyyy · HH:mm", "MMM d, yyyy · HH:mm"), Locale.getDefault())
    return fmt.format(Date((ts * 1000).toLong()))
}

@Composable
fun RoutesScreen(store: Store) {
    var rides by remember { mutableStateOf<List<Ride>>(emptyList()) }
    var loaded by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { rides = store.rides(); loaded = true }

    Column(Modifier.fillMaxSize().padding(16.dp)) {
        Text("Move Log", fontSize = 30.sp, fontWeight = FontWeight.Bold, color = Color.White,
            modifier = Modifier.padding(vertical = 8.dp))
        if (loaded && rides.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(L("Henüz rota yok", "No routes yet"), color = Color(0xFF9AA4B2))
            }
        }
        LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(rides) { r ->
                Surface(color = Brand.card, shape = RoundedCornerShape(20.dp)) {
                    Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(typeIcon(r.type), null, tint = Brand.accent, modifier = Modifier.size(40.dp))
                        Spacer(Modifier.width(14.dp))
                        Column(Modifier.weight(1f)) {
                            Text(dayTime(r), color = Color.White, fontWeight = FontWeight.SemiBold)
                            Text(typeLabel(r.type), color = Color(0xFF9AA4B2), fontSize = 13.sp)
                        }
                        if (r.rendering) {
                            Text(L("Hazırlanıyor…", "Rendering…"), color = Brand.accent, fontSize = 13.sp)
                        } else if (r.novideo) {
                            Icon(Icons.Filled.MovieCreation, null, tint = Brand.accent)
                        } else {
                            Icon(Icons.Filled.PlayCircle, null, tint = Brand.accent, modifier = Modifier.size(34.dp))
                        }
                    }
                }
            }
        }
    }
}
