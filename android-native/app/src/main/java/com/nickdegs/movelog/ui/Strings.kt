package com.nickdegs.movelog.ui

import java.util.Locale

// iOS L(tr,en) karşılığı: cihaz dili tr ise Türkçe, değilse İngilizce.
// (Tam 12-dil TRANS sözlüğü iOS'taki gibi kademeli eklenecek.)
fun L(tr: String, en: String): String =
    if (Locale.getDefault().language == "tr") tr else en
