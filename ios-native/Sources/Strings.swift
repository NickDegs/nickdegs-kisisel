import SwiftUI

// MARK: - Launch ortamı (ekran görüntüsü/demo için)
enum AppEnv {
    static let args = CommandLine.arguments
    static var demo: Bool { args.contains("DEMO") }
    static var screen: String? { args.first(where: { $0.hasPrefix("SCREEN=") })?.replacingOccurrences(of: "SCREEN=", with: "") }
    static var langOverride: String? { args.first(where: { $0.hasPrefix("LANG=") })?.replacingOccurrences(of: "LANG=", with: "") }
}

let SUPPORTED = ["en","tr","de","fr","es","it","pt","ru","ja","zh","ko","ar"]
func currentLang() -> String {
    if let o = AppEnv.langOverride, SUPPORTED.contains(o) { return o }
    let code = Locale.preferredLanguages.first?.split(separator: "-").first.map(String.init) ?? "en"
    return SUPPORTED.contains(code) ? code : "en"
}

// İngilizce anahtara göre 12-dil çeviri (eksikse İngilizce'ye düşer)
private let TRANS: [String: [String:String]] = [
 "Routes · Activity · Live location": ["tr":"Rotalar · Aktivite · Canlı konum","de":"Routen · Aktivität · Live-Standort","fr":"Itinéraires · Activité · Position en direct","es":"Rutas · Actividad · Ubicación en vivo","it":"Percorsi · Attività · Posizione live","pt":"Rotas · Atividade · Localização ao vivo","ru":"Маршруты · Активность · Геопозиция","ja":"ルート · アクティビティ · 現在地","zh":"路线 · 活动 · 实时位置","ko":"경로 · 활동 · 실시간 위치","ar":"المسارات · النشاط · الموقع المباشر"],
 "Username": ["tr":"Kullanıcı","de":"Benutzer","fr":"Identifiant","es":"Usuario","it":"Utente","pt":"Usuário","ru":"Пользователь","ja":"ユーザー名","zh":"用户名","ko":"사용자 이름","ar":"اسم المستخدم"],
 "Password": ["tr":"Parola","de":"Passwort","fr":"Mot de passe","es":"Contraseña","it":"Password","pt":"Senha","ru":"Пароль","ja":"パスワード","zh":"密码","ko":"비밀번호","ar":"كلمة المرور"],
 "Sign in": ["tr":"Giriş yap","de":"Anmelden","fr":"Se connecter","es":"Iniciar sesión","it":"Accedi","pt":"Entrar","ru":"Войти","ja":"サインイン","zh":"登录","ko":"로그인","ar":"تسجيل الدخول"],
 "Routes": ["tr":"Rotalar","de":"Routen","fr":"Itinéraires","es":"Rutas","it":"Percorsi","pt":"Rotas","ru":"Маршруты","ja":"ルート","zh":"路线","ko":"경로","ar":"المسارات"],
 "Chat": ["tr":"Sohbet","de":"Chat","fr":"Discussion","es":"Chat","it":"Chat","pt":"Conversa","ru":"Чат","ja":"チャット","zh":"聊天","ko":"채팅","ar":"الدردشة"],
 "Map": ["tr":"Harita","de":"Karte","fr":"Carte","es":"Mapa","it":"Mappa","pt":"Mapa","ru":"Карта","ja":"マップ","zh":"地图","ko":"지도","ar":"الخريطة"],
 "Stats": ["tr":"İstatistik","de":"Statistik","fr":"Stats","es":"Stats","it":"Statistiche","pt":"Estatísticas","ru":"Статистика","ja":"統計","zh":"统计","ko":"통계","ar":"الإحصاءات"],
 "Profile": ["tr":"Profil","de":"Profil","fr":"Profil","es":"Perfil","it":"Profilo","pt":"Perfil","ru":"Профиль","ja":"プロフィール","zh":"个人资料","ko":"프로필","ar":"الملف"],
 "Live GPS": ["tr":"Canlı GPS","de":"Live-GPS","fr":"GPS en direct","es":"GPS en vivo","it":"GPS live","pt":"GPS ao vivo","ru":"GPS вживую","ja":"ライブGPS","zh":"实时 GPS","ko":"실시간 GPS","ar":"GPS مباشر"],
 "Play": ["tr":"İzle","de":"Ansehen","fr":"Lire","es":"Ver","it":"Guarda","pt":"Assistir","ru":"Смотреть","ja":"再生","zh":"播放","ko":"재생","ar":"تشغيل"],
 "Motorcycle": ["tr":"Motosiklet","de":"Motorrad","fr":"Moto","es":"Motocicleta","it":"Moto","pt":"Motocicleta","ru":"Мотоцикл","ja":"バイク","zh":"摩托车","ko":"오토바이","ar":"دراجة نارية"],
 "Cycling": ["tr":"Bisiklet","de":"Radfahren","fr":"Vélo","es":"Ciclismo","it":"Ciclismo","pt":"Ciclismo","ru":"Велосипед","ja":"サイクリング","zh":"骑行","ko":"자전거","ar":"دراجة"],
 "Running": ["tr":"Koşu","de":"Laufen","fr":"Course","es":"Correr","it":"Corsa","pt":"Corrida","ru":"Бег","ja":"ランニング","zh":"跑步","ko":"달리기","ar":"الجري"],
 "Walking": ["tr":"Yürüyüş","de":"Gehen","fr":"Marche","es":"Caminar","it":"Camminata","pt":"Caminhada","ru":"Ходьба","ja":"ウォーキング","zh":"步行","ko":"걷기","ar":"المشي"],
 "Other": ["tr":"Diğer","de":"Sonstige","fr":"Autre","es":"Otro","it":"Altro","pt":"Outro","ru":"Другое","ja":"その他","zh":"其他","ko":"기타","ar":"أخرى"],
 "Total routes": ["tr":"Toplam rota","de":"Routen gesamt","fr":"Itinéraires au total","es":"Rutas totales","it":"Percorsi totali","pt":"Total de rotas","ru":"Всего маршрутов","ja":"ルート合計","zh":"路线总数","ko":"총 경로","ar":"إجمالي المسارات"],
 "Latest route": ["tr":"Son rota","de":"Letzte Route","fr":"Dernier itinéraire","es":"Última ruta","it":"Ultimo percorso","pt":"Última rota","ru":"Последний маршрут","ja":"最新のルート","zh":"最新路线","ko":"최근 경로","ar":"أحدث مسار"],
 "Move Log member": ["tr":"Move Log üyesi","de":"Move Log-Mitglied","fr":"Membre Move Log","es":"Miembro de Move Log","it":"Membro Move Log","pt":"Membro Move Log","ru":"Участник Move Log","ja":"Move Log メンバー","zh":"Move Log 会员","ko":"Move Log 회원","ar":"عضو في Move Log"],
 "Friends": ["tr":"Arkadaşlar","de":"Freunde","fr":"Amis","es":"Amigos","it":"Amici","pt":"Amigos","ru":"Друзья","ja":"友だち","zh":"好友","ko":"친구","ar":"الأصدقاء"],
 "Add friend": ["tr":"Arkadaş ekle","de":"Freund hinzufügen","fr":"Ajouter un ami","es":"Añadir amigo","it":"Aggiungi amico","pt":"Adicionar amigo","ru":"Добавить друга","ja":"友だちを追加","zh":"添加好友","ko":"친구 추가","ar":"إضافة صديق"],
 "Typography": ["tr":"Tipografi","de":"Typografie","fr":"Typographie","es":"Tipografía","it":"Tipografia","pt":"Tipografia","ru":"Типографика","ja":"書体","zh":"字体","ko":"서체","ar":"الخطوط"],
 "Default": ["tr":"Varsayılan","de":"Standard","fr":"Par défaut","es":"Predeterminado","it":"Predefinito","pt":"Padrão","ru":"По умолчанию","ja":"デフォルト","zh":"默认","ko":"기본","ar":"افتراضي"],
 "Appearance": ["tr":"Görünüm","de":"Darstellung","fr":"Apparence","es":"Apariencia","it":"Aspetto","pt":"Aparência","ru":"Оформление","ja":"外観","zh":"外观","ko":"화면 모드","ar":"المظهر"],
 "Light": ["tr":"Açık","de":"Hell","fr":"Clair","es":"Claro","it":"Chiaro","pt":"Claro","ru":"Светлая","ja":"ライト","zh":"浅色","ko":"라이트","ar":"فاتح"],
 "Dark": ["tr":"Koyu","de":"Dunkel","fr":"Sombre","es":"Oscuro","it":"Scuro","pt":"Escuro","ru":"Тёмная","ja":"ダーク","zh":"深色","ko":"다크","ar":"داكن"],
 "Sign out": ["tr":"Çıkış","de":"Abmelden","fr":"Déconnexion","es":"Cerrar sesión","it":"Esci","pt":"Sair","ru":"Выйти","ja":"サインアウト","zh":"退出","ko":"로그아웃","ar":"تسجيل الخروج"],
 "Message": ["tr":"Mesaj","de":"Nachricht","fr":"Message","es":"Mensaje","it":"Messaggio","pt":"Mensagem","ru":"Сообщение","ja":"メッセージ","zh":"消息","ko":"메시지","ar":"رسالة"],
 "Online": ["tr":"Çevrimiçi","de":"Online","fr":"En ligne","es":"En línea","it":"Online","pt":"Online","ru":"В сети","ja":"オンライン","zh":"在线","ko":"온라인","ar":"متصل"],
 "Offline": ["tr":"Çevrimdışı","de":"Offline","fr":"Hors ligne","es":"Sin conexión","it":"Offline","pt":"Offline","ru":"Не в сети","ja":"オフライン","zh":"离线","ko":"오프라인","ar":"غير متصل"],
 "Friend": ["tr":"Arkadaş","de":"Freund","fr":"Ami","es":"Amigo","it":"Amico","pt":"Amigo","ru":"Друг","ja":"友だち","zh":"好友","ko":"친구","ar":"صديق"],
 "Route": ["tr":"Rota","de":"Route","fr":"Itinéraire","es":"Ruta","it":"Percorso","pt":"Rota","ru":"Маршрут","ja":"ルート","zh":"路线","ko":"경로","ar":"مسار"],
]

func L(_ tr: String, _ en: String) -> String {
    let lang = currentLang()
    if lang == "tr" { return tr }
    if lang == "en" { return en }
    return TRANS[en]?[lang] ?? en
}

// MARK: - Demo veri (native ekran görüntüleri — kişisel veri YOK)
enum Demo {
    static let names: [String:[String]] = [
     "en":["James Carter","Emma Hughes","Liam Foster","Olivia Reed"],"tr":["Mehmet Demir","Elif Kaya","Ahmet Yıldız","Zeynep Şahin"],
     "de":["Lukas Müller","Anna Schmidt","Jonas Weber","Lea Fischer"],"fr":["Hugo Martin","Léa Dubois","Louis Bernard","Emma Laurent"],
     "es":["Hugo García","Lucía Martín","Mateo López","Sofía Ruiz"],"it":["Marco Rossi","Giulia Bianchi","Luca Romano","Sara Conti"],
     "pt":["João Silva","Maria Souza","Pedro Costa","Ana Oliveira"],"ru":["Иван Смирнов","Анна Иванова","Дмитрий Кузнецов","Мария Попова"],
     "ja":["田中 健","佐藤 美咲","鈴木 大輔","高橋 結衣"],"zh":["王伟","李娜","张强","刘洋"],
     "ko":["김민준","이서연","박지훈","최수아"],"ar":["أحمد محمد","سارة علي","خالد حسن","نور عبدالله"]]
    static let city: [String:(Double,Double)] = [
     "en":(51.5074,-0.1278),"tr":(41.0082,28.9784),"de":(52.52,13.405),"fr":(48.8566,2.3522),"es":(40.4168,-3.7038),
     "it":(41.9028,12.4964),"pt":(-23.55,-46.633),"ru":(55.7558,37.6173),"ja":(35.6762,139.6503),"zh":(31.2304,121.4737),"ko":(37.5665,126.978),"ar":(24.7136,46.6753)]
    static let thread: [String:[String]] = [
     "en":["Morning! Ready for the ride?","Almost, leaving in 5","Perfect, I'll wait at the bridge","On my way","See you there!"],
     "tr":["Günaydın! Sürüşe hazır mısın?","Az kaldı, 5 dakikaya çıkıyorum","Süper, köprüde beklerim","Yoldayım","Orada görüşürüz!"],
     "de":["Morgen! Bereit für die Tour?","Fast, fahre in 5 los","Super, warte an der Brücke","Bin unterwegs","Bis gleich!"],
     "fr":["Salut ! Prêt pour la sortie ?","Presque, je pars dans 5 min","Parfait, j'attends au pont","En route","À tout de suite !"],
     "es":["¡Buenos días! ¿Listo?","Casi, salgo en 5","Perfecto, te espero en el puente","En camino","¡Nos vemos!"],
     "it":["Buongiorno! Pronto?","Quasi, parto tra 5","Perfetto, ti aspetto al ponte","Sto arrivando","Ci vediamo lì!"],
     "pt":["Bom dia! Pronto?","Quase, saio em 5","Perfeito, espero na ponte","A caminho","Até já!"],
     "ru":["Доброе утро! Готов?","Почти, выезжаю через 5","Отлично, жду у моста","Уже еду","До встречи!"],
     "ja":["おはよう！準備できた？","もうすぐ、5分で出る","了解、橋で待ってる","向かってるよ","じゃあそこで！"],
     "zh":["早上好！准备好了吗？","快了，5分钟后出发","好的，我在桥边等你","在路上了","到那儿见！"],
     "ko":["좋은 아침! 준비됐어?","거의, 5분 뒤 출발","좋아, 다리에서 기다릴게","가는 중","거기서 봐!"],
     "ar":["صباح الخير! جاهز؟","تقريبًا، سأخرج خلال 5","ممتاز، سأنتظرك عند الجسر","في الطريق","نراك هناك!"]]
    static var nm: [String] { names[currentLang()] ?? names["en"]! }
    static var user: String { nm[0] }
}
