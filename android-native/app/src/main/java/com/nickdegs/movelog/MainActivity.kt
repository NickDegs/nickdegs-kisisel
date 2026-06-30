package com.nickdegs.movelog

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.viewmodel.compose.viewModel
import com.nickdegs.movelog.data.Store
import com.nickdegs.movelog.ui.MoveLogApp
import com.nickdegs.movelog.ui.theme.MoveLogTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MoveLogTheme {
                val store: Store = viewModel()
                MoveLogApp(store)
            }
        }
    }
}
