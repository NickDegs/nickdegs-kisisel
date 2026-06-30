package com.nickdegs.movelog.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nickdegs.movelog.data.Store
import com.nickdegs.movelog.ui.L
import com.nickdegs.movelog.ui.theme.Brand

@Composable
fun ProfileScreen(store: Store) {
    var showPaywall by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { store.loadProfile() }
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Spacer(Modifier.height(24.dp))
        Box(Modifier.size(96.dp).background(Brand.gradient, CircleShape), contentAlignment = Alignment.Center) {
            Text((store.me.ifEmpty { "?" }).take(1).uppercase(), fontSize = 40.sp, color = Color.White, fontWeight = FontWeight.Bold)
        }
        Text(store.me.ifEmpty { "Move Log" }, fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.White)

        Surface(color = Brand.card, shape = RoundedCornerShape(22.dp),
            modifier = Modifier.fillMaxWidth().clickable { if (!store.premium) showPaywall = true }) {
            Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Star, null, tint = Brand.accent)
                Spacer(Modifier.width(12.dp))
                Column {
                    Text(if (store.premium) L("Premium üyesin", "You're Premium")
                         else L("Move Log Premium", "Move Log Premium"), color = Color.White, fontWeight = FontWeight.Bold)
                    Text(if (store.premium) L("Tüm özellikler açık", "All features unlocked")
                         else L("3B videolar, filigransız, müzik", "3D videos, no watermark, music"),
                        color = Color(0xFF9AA4B2), fontSize = 13.sp)
                }
            }
        }
        Spacer(Modifier.weight(1f))
        OutlinedButton(onClick = { store.signOut() }, modifier = Modifier.fillMaxWidth()) {
            Text(L("Çıkış", "Sign out"))
        }
    }

    if (showPaywall) {
        androidx.compose.ui.window.Dialog(
            onDismissRequest = { showPaywall = false },
            properties = androidx.compose.ui.window.DialogProperties(usePlatformDefaultWidth = false)
        ) { PaywallScreen(store) { showPaywall = false } }
    }
}
