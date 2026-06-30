package com.nickdegs.movelog.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nickdegs.movelog.data.Store
import com.nickdegs.movelog.ui.L
import com.nickdegs.movelog.ui.theme.Brand
import kotlinx.coroutines.launch

@Composable
fun LoginScreen(store: Store) {
    val scope = rememberCoroutineScope()
    var phone by remember { mutableStateOf("") }
    var code by remember { mutableStateOf("") }
    var sent by remember { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }

    Box(Modifier.fillMaxSize().padding(24.dp), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Text("Move Log", fontSize = 34.sp, fontWeight = FontWeight.Bold, color = Brand.accent)
            Text(L("Telefonunla giriş yap", "Sign in with your phone"), color = androidx.compose.ui.graphics.Color(0xFF9AA4B2))
            OutlinedTextField(
                value = phone, onValueChange = { phone = it },
                label = { Text(L("Telefon (+90...)", "Phone (+90...)")) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                modifier = Modifier.fillMaxWidth()
            )
            if (sent) {
                OutlinedTextField(
                    value = code, onValueChange = { code = it },
                    label = { Text(L("6 haneli kod", "6-digit code")) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth()
                )
            }
            Button(
                onClick = {
                    busy = true
                    scope.launch {
                        if (!sent) { sent = store.smsStart(phone) }
                        else { store.smsVerify(phone, code) }
                        busy = false
                    }
                },
                enabled = !busy && phone.length >= 8 && (!sent || code.length >= 4),
                colors = ButtonDefaults.buttonColors(containerColor = Brand.accent),
                modifier = Modifier.fillMaxWidth()
            ) {
                if (busy) CircularProgressIndicator(Modifier.size(20.dp), color = androidx.compose.ui.graphics.Color.White)
                else Text(if (!sent) L("Kod gönder", "Send code") else L("Doğrula ve gir", "Verify & sign in"))
            }
            if (store.loginError) Text(L("Kod hatalı, tekrar dene", "Wrong code, try again"),
                color = androidx.compose.ui.graphics.Color(0xFFFF6B6B))
        }
    }
}
