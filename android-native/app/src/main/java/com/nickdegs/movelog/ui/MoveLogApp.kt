package com.nickdegs.movelog.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.nickdegs.movelog.data.Store
import com.nickdegs.movelog.ui.screens.*
import com.nickdegs.movelog.ui.theme.Brand

private data class Tab(val title: String, val icon: ImageVector)

@Composable
fun MoveLogApp(store: Store) {
    if (!store.loggedIn) { LoginScreen(store); return }

    var sel by remember { mutableStateOf(0) }
    val tabs = listOf(
        Tab(L("Rotalar", "Routes"), Icons.Filled.Map),
        Tab(L("Videolarım", "My Videos"), Icons.Filled.VideoLibrary),
        Tab(L("Özet", "Summary"), Icons.Filled.Article),
        Tab(L("Harita", "Map"), Icons.Filled.LocationOn),
        Tab(L("Profil", "Profile"), Icons.Filled.Person),
    )

    Scaffold(
        containerColor = Brand.bg,
        bottomBar = {
            NavigationBar(containerColor = Brand.card) {
                tabs.forEachIndexed { i, t ->
                    NavigationBarItem(
                        selected = sel == i,
                        onClick = { sel = i },
                        icon = { Icon(t.icon, contentDescription = t.title) },
                        label = { Text(t.title) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = Brand.accent,
                            selectedTextColor = Brand.accent,
                            indicatorColor = Brand.accent.copy(alpha = 0.15f),
                        )
                    )
                }
            }
        }
    ) { pad ->
        Box(Modifier.padding(pad).fillMaxSize()) {
            when (sel) {
                0 -> RoutesScreen(store)
                1 -> VideosScreen(store)
                2 -> SummariesScreen(store)
                3 -> PlaceholderScreen(L("Harita + Sohbet", "Map + Chat"))
                else -> ProfileScreen(store)
            }
        }
    }
}

@Composable
fun PlaceholderScreen(title: String) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text("$title\n${L("yakında", "coming soon")}", color = Color_secondary)
    }
}

private val Color_secondary = androidx.compose.ui.graphics.Color(0xFF9AA4B2)
