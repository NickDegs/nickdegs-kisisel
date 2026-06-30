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
import com.nickdegs.movelog.data.Billing
import com.nickdegs.movelog.data.Convo
import com.nickdegs.movelog.data.Store
import com.nickdegs.movelog.ui.L
import com.nickdegs.movelog.ui.theme.Brand

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(store: Store) {
    val scope = rememberCoroutineScope()
    val ctx = androidx.compose.ui.platform.LocalContext.current
    var showPaywall by remember { mutableStateOf(false) }
    var editName by remember { mutableStateOf(false) }
    var addFriend by remember { mutableStateOf(false) }
    var friends by remember { mutableStateOf<List<Convo>>(emptyList()) }
    var boostMsg by remember { mutableStateOf<String?>(null) }
    var sens by remember { mutableStateOf(store.sensitivity) }
    var sumOn by remember { mutableStateOf(true) }
    var sumHour by remember { mutableStateOf(21) }
    var showHour by remember { mutableStateOf(false) }
    var showDelete by remember { mutableStateOf(false) }
    val billing = remember {
        Billing(ctx, onPurchase = {}, onBoost = { t ->
            scope.launch { if (store.verifyGoogleBoost(t)) boostMsg = L("Bugünkü limitin 2 katına çıktı 🚀", "Today's limit doubled 🚀") }
        })
    }
    LaunchedEffect(Unit) {
        store.loadProfile(); friends = store.friends()
        val s = store.summarySettings(); sumOn = s.first; sumHour = s.second
    }
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

        // Günlük 2× Boost (consumable) — premium üyeye, ürün Play'de yüklüyse
        if (store.premium && billing.boost != null) {
            item {
                Surface(color = Brand.card, shape = RoundedCornerShape(22.dp),
                    modifier = Modifier.fillMaxWidth().clickable { (ctx as? android.app.Activity)?.let { billing.buyBoost(it) } }) {
                    Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Filled.Bolt, null, tint = Brand.accent)
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(L("Günlük 2× Boost", "Daily 2× Boost"), color = Color.White, fontWeight = FontWeight.Bold)
                            Text(boostMsg ?: L("Bugünkü video limitini ikiye katla", "Double today's video limit"),
                                color = Color(0xFF9AA4B2), fontSize = 13.sp)
                        }
                        Text(billing.boostPrice(), color = Brand.accent, fontWeight = FontWeight.Bold)
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

        // Algılama hassasiyeti (premium)
        item {
            Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(L("Algılama hassasiyeti", "Detection sensitivity"), color = Color(0xFF9AA4B2),
                    fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                    val opts = listOf("hassas" to L("Hassas", "High"), "dengeli" to L("Dengeli", "Balanced"), "basit" to L("Basit", "Simple"))
                    opts.forEachIndexed { i, (id, label) ->
                        SegmentedButton(
                            selected = sens == id,
                            onClick = { if (store.premium || id == "basit") { sens = id; store.sensitivity = id } else showPaywall = true },
                            shape = SegmentedButtonDefaults.itemShape(i, opts.size)
                        ) { Text(label) }
                    }
                }
                if (!store.premium) Text(L("Hassas ve Dengeli için Premium gerekir.", "High and Balanced require Premium."),
                    color = Color(0xFF9AA4B2), fontSize = 12.sp)
            }
        }

        // Günlük özet (premium)
        item {
            Surface(color = Brand.card, shape = RoundedCornerShape(18.dp), modifier = Modifier.fillMaxWidth()) {
                Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(L("Günlük özet", "Daily summary"), color = Color.White, fontWeight = FontWeight.SemiBold)
                        Text(L("Her gün ${"%02d".format(sumHour)}:00'da aktivite özeti", "Activity summary daily at ${"%02d".format(sumHour)}:00"),
                            color = Color(0xFF9AA4B2), fontSize = 12.sp)
                    }
                    if (sumOn) TextButton(onClick = { showHour = true }) { Text("${"%02d".format(sumHour)}:00", color = Brand.accent) }
                    Switch(checked = sumOn, onCheckedChange = {
                        sumOn = it; scope.launch { store.setSummarySettings(it, sumHour) }
                    })
                }
            }
        }

        item {
            Spacer(Modifier.height(8.dp))
            OutlinedButton(onClick = { store.signOut() }, modifier = Modifier.fillMaxWidth()) {
                Text(L("Çıkış", "Sign out"))
            }
            TextButton(onClick = { showDelete = true }, modifier = Modifier.fillMaxWidth()) {
                Text(L("Hesabı sil", "Delete account"), color = Color(0xFFFF6B6B))
            }
            Spacer(Modifier.height(24.dp))
        }
    }

    if (showHour) {
        AlertDialog(onDismissRequest = { showHour = false },
            title = { Text(L("Özet saati", "Summary time")) },
            text = {
                LazyColumn(Modifier.height(280.dp)) {
                    items((0..23).toList()) { h ->
                        Text("${"%02d".format(h)}:00", color = if (h == sumHour) Brand.accent else Color.White,
                            fontWeight = if (h == sumHour) FontWeight.Bold else FontWeight.Normal,
                            modifier = Modifier.fillMaxWidth().clickable {
                                sumHour = h; showHour = false; scope.launch { store.setSummarySettings(sumOn, h) }
                            }.padding(vertical = 10.dp))
                    }
                }
            }, confirmButton = {})
    }

    if (showDelete) {
        AlertDialog(onDismissRequest = { showDelete = false },
            title = { Text(L("Hesabı sil?", "Delete account?")) },
            text = { Text(L("Tüm verilerin kalıcı olarak silinir. Bu işlem geri alınamaz.", "All your data is permanently deleted. This cannot be undone.")) },
            confirmButton = {
                TextButton(onClick = { showDelete = false; scope.launch { store.deleteAccount() } }) {
                    Text(L("Sil", "Delete"), color = Color(0xFFFF6B6B))
                }
            },
            dismissButton = { TextButton(onClick = { showDelete = false }) { Text(L("Vazgeç", "Cancel")) } })
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
