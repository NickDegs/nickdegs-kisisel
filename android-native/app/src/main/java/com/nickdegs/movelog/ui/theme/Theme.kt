package com.nickdegs.movelog.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

// iOS Brand renkleriyle birebir (Glass.swift): accent #0A85FF, accent2 #5E5CE6, bg #05070c
object Brand {
    val accent = Color(0xFF0A85FF)
    val accent2 = Color(0xFF5E5CE6)
    val bg = Color(0xFF05070C)
    val card = Color(0xFF11151F)
    val gradient = Brush.linearGradient(listOf(accent, accent2))
}

private val DarkColors = darkColorScheme(
    primary = Brand.accent,
    secondary = Brand.accent2,
    background = Brand.bg,
    surface = Brand.card,
    onPrimary = Color.White,
    onBackground = Color.White,
    onSurface = Color.White,
)

@Composable
fun MoveLogTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = DarkColors, content = content)
}
