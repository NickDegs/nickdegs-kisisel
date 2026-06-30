package com.nickdegs.movelog.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
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
import kotlinx.coroutines.launch
import com.nickdegs.movelog.data.Convo
import com.nickdegs.movelog.data.Store
import com.nickdegs.movelog.ui.L
import com.nickdegs.movelog.ui.theme.Brand

@Composable
fun ProfileScreen(store: Store) {
    val scope = rememberCoroutineScope()
    var showPaywall by remember { mutableStateOf(false) }
    var editName by remember { mutableStateOf(false) }
    var addFriend by remember { mutableStateOf(false) }
    var friends by remember { mutableStateOf<List<Convo>>(emptyList()) }
    LaunchedEffect(Unit) { store.loadProfile(); friends = store.friends() }
    val shown = store.displayName.ifBlank { store.me }.ifBlank { "Move Log" }

    LazyColumn(
        Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Spacer(Modifier.height(12.dp))
            Box(Modifier.size(96.dp).background(Brand.gradient, CircleShape), contentAlignment = Alignment.Center) {
                Text(shown.take(1).uppercase(), fontSize = 40.sp, color = Color.White, fontWeight = FontWeight.Bold)
            }
        }
        item {
            Row(verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.clickable { editName = true }) {
                Text(shown, fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Color.White)
                Spacer(Modifier.width(8.dp))
                Icon(Icons.Filled.Edit, L("İsmi düzenle", "Edit name"), tint = Color(0xFF9AA4B2), modifier = Modifier.size(18.dp))
            }
            Text(L("İsmin video başında görünür", "Your name appears at the start of videos"),
                color = Color(0xFF9AA4B2), fontSize = 12.sp)
        }

        // Premium kartı
        item {
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
        }

        // Arkadaşlar
        item {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(L("Arkadaşlar", "Friends"), color = Color(0xFF9AA4B2), fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.weight(1f))
                TextButton(onClick = { addFriend = true }) {
                    Icon(Icons.Filled.PersonAdd, null, tint = Brand.accent, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(4.dp))
                    Text(L("Ekle", "Add"), color = Brand.accent)
                }
            }
        }
        items(friends) { f ->
            Surface(color = Brand.card, shape = RoundedCornerShape(16.dp), modifier = Modifier.fillMaxWidth()) {
                Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(38.dp).background(Brand.gradient, CircleShape), contentAlignment = Alignment.Center) {
                        Text((f.name ?: f.username).take(1).uppercase(), color = Color.White, fontWeight = FontWeight.Bold)
                    }
                    Spacer(Modifier.width(12.dp))
                    Column {
                        Text(f.name ?: f.username, color = Color.White, fontWeight = FontWeight.SemiBold)
                        Text("@${f.username}", color = Color(0xFF9AA4B2), fontSize = 12.sp)
                    }
                }
            }
        }

        item {
            Spacer(Modifier.height(8.dp))
            OutlinedButton(onClick = { store.signOut() }, modifier = Modifier.fillMaxWidth()) {
                Text(L("Çıkış", "Sign out"))
            }
        }
    }

    if (editName) {
        var v by remember { mutableStateOf(store.displayName.ifBlank { store.me }) }
        AlertDialog(onDismissRequest = { editName = false },
            title = { Text(L("İsmini düzenle", "Edit your name")) },
            text = {
                OutlinedTextField(value = v, onValueChange = { v = it }, singleLine = true,
                    label = { Text(L("Ad Soyad", "Full name")) })
            },
            confirmButton = {
                TextButton(onClick = {
                    val n = v.trim(); editName = false
                    if (n.isNotEmpty()) scope.launch { store.setName(n) }
                }) { Text(L("Kaydet", "Save")) }
            },
            dismissButton = { TextButton(onClick = { editName = false }) { Text(L("Vazgeç", "Cancel")) } })
    }

    if (addFriend) {
        var u by remember { mutableStateOf("") }
        AlertDialog(onDismissRequest = { addFriend = false },
            title = { Text(L("Arkadaş ekle", "Add friend")) },
            text = {
                OutlinedTextField(value = u, onValueChange = { u = it }, singleLine = true,
                    label = { Text(L("Kullanıcı adı", "Username")) }, prefix = { Text("@") })
            },
            confirmButton = {
                TextButton(onClick = {
                    val name = u.trim(); addFriend = false
                    if (name.isNotEmpty()) scope.launch { if (store.addFriend(name)) friends = store.friends() }
                }) { Text(L("Ekle", "Add")) }
            },
            dismissButton = { TextButton(onClick = { addFriend = false }) { Text(L("Vazgeç", "Cancel")) } })
    }

    if (showPaywall) {
        androidx.compose.ui.window.Dialog(
            onDismissRequest = { showPaywall = false },
            properties = androidx.compose.ui.window.DialogProperties(usePlatformDefaultWidth = false)
        ) { PaywallScreen(store) { showPaywall = false } }
    }
}
