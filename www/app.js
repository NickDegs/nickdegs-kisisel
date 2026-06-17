// Move Log — frontend (çerçeve-bağımsız) · çok dilli · resmi tasarım dili
const API = "https://kisisel-api.nickdegs.com";
let TOKEN = localStorage.getItem("nd_token") || "";
let map, markers = {};

const $ = (s) => document.querySelector(s);
const show = (id) => { document.querySelectorAll(".screen").forEach(s => s.classList.remove("active")); $("#" + id).classList.add("active"); };

/* ---------------- i18n ---------------- */
const I18N = {
  en: { tagline:"Routes · Activity · Live location", user:"Username", password:"Password", signin:"Sign in", err:"Incorrect username or password", rides:"Routes", gps:"Map", stats:"Stats", profile:"Profile", watch:"Play", loading:"Loading…", failed:"Failed to load.", noRides:"No route videos yet.", noLoc:"No location data.", kmh:"km/h", online:"Online", offline:"Offline", totalRoutes:"Total routes", lastRoute:"Latest route", tracked:"People tracked", trackedList:"Tracked people", memberSub:"Move Log member", t_moto:"Motorcycle", t_bike:"Cycling", t_run:"Running", t_walk:"Walking", t_other:"Other" },
  tr: { tagline:"Rotalar · Aktivite · Canlı konum", user:"Kullanıcı", password:"Parola", signin:"Giriş yap", err:"Kullanıcı adı veya parola hatalı", rides:"Rotalar", gps:"Harita", stats:"İstatistik", profile:"Profil", watch:"İzle", loading:"Yükleniyor…", failed:"Yüklenemedi.", noRides:"Henüz rota videosu yok.", noLoc:"Konum verisi yok.", kmh:"km/s", online:"Çevrimiçi", offline:"Çevrimdışı", totalRoutes:"Toplam rota", lastRoute:"Son rota", tracked:"Takip edilen", trackedList:"Takip edilenler", memberSub:"Move Log üyesi", t_moto:"Motosiklet", t_bike:"Bisiklet", t_run:"Koşu", t_walk:"Yürüyüş", t_other:"Diğer" },
  de: { tagline:"Routen · Aktivität · Live-Standort", user:"Benutzer", password:"Passwort", signin:"Anmelden", err:"Benutzername oder Passwort falsch", rides:"Routen", gps:"Karte", stats:"Statistik", profile:"Profil", watch:"Ansehen", loading:"Wird geladen…", failed:"Laden fehlgeschlagen.", noRides:"Noch keine Routenvideos.", noLoc:"Keine Standortdaten.", kmh:"km/h", online:"Online", offline:"Offline", totalRoutes:"Routen gesamt", lastRoute:"Letzte Route", tracked:"Verfolgte Personen", trackedList:"Verfolgte Personen", memberSub:"Move Log-Mitglied", t_moto:"Motorrad", t_bike:"Radfahren", t_run:"Laufen", t_walk:"Gehen", t_other:"Sonstige" },
  fr: { tagline:"Itinéraires · Activité · Position en direct", user:"Identifiant", password:"Mot de passe", signin:"Se connecter", err:"Identifiant ou mot de passe incorrect", rides:"Itinéraires", gps:"Carte", stats:"Stats", profile:"Profil", watch:"Lire", loading:"Chargement…", failed:"Échec du chargement.", noRides:"Aucune vidéo d'itinéraire.", noLoc:"Aucune position.", kmh:"km/h", online:"En ligne", offline:"Hors ligne", totalRoutes:"Itinéraires au total", lastRoute:"Dernier itinéraire", tracked:"Personnes suivies", trackedList:"Personnes suivies", memberSub:"Membre Move Log", t_moto:"Moto", t_bike:"Vélo", t_run:"Course", t_walk:"Marche", t_other:"Autre" },
  es: { tagline:"Rutas · Actividad · Ubicación en vivo", user:"Usuario", password:"Contraseña", signin:"Iniciar sesión", err:"Usuario o contraseña incorrectos", rides:"Rutas", gps:"Mapa", stats:"Stats", profile:"Perfil", watch:"Ver", loading:"Cargando…", failed:"Error al cargar.", noRides:"Aún no hay vídeos de rutas.", noLoc:"Sin ubicación.", kmh:"km/h", online:"En línea", offline:"Sin conexión", totalRoutes:"Rutas totales", lastRoute:"Última ruta", tracked:"Personas seguidas", trackedList:"Personas seguidas", memberSub:"Miembro de Move Log", t_moto:"Motocicleta", t_bike:"Ciclismo", t_run:"Correr", t_walk:"Caminar", t_other:"Otro" },
  it: { tagline:"Percorsi · Attività · Posizione live", user:"Utente", password:"Password", signin:"Accedi", err:"Utente o password errati", rides:"Percorsi", gps:"Mappa", stats:"Statistiche", profile:"Profilo", watch:"Guarda", loading:"Caricamento…", failed:"Caricamento non riuscito.", noRides:"Ancora nessun video.", noLoc:"Nessuna posizione.", kmh:"km/h", online:"Online", offline:"Offline", totalRoutes:"Percorsi totali", lastRoute:"Ultimo percorso", tracked:"Persone seguite", trackedList:"Persone seguite", memberSub:"Membro Move Log", t_moto:"Moto", t_bike:"Ciclismo", t_run:"Corsa", t_walk:"Camminata", t_other:"Altro" },
  pt: { tagline:"Rotas · Atividade · Localização ao vivo", user:"Usuário", password:"Senha", signin:"Entrar", err:"Usuário ou senha incorretos", rides:"Rotas", gps:"Mapa", stats:"Estatísticas", profile:"Perfil", watch:"Assistir", loading:"Carregando…", failed:"Falha ao carregar.", noRides:"Ainda sem vídeos de rota.", noLoc:"Sem localização.", kmh:"km/h", online:"Online", offline:"Offline", totalRoutes:"Total de rotas", lastRoute:"Última rota", tracked:"Pessoas seguidas", trackedList:"Pessoas seguidas", memberSub:"Membro Move Log", t_moto:"Motocicleta", t_bike:"Ciclismo", t_run:"Corrida", t_walk:"Caminhada", t_other:"Outro" },
  ru: { tagline:"Маршруты · Активность · Геопозиция", user:"Пользователь", password:"Пароль", signin:"Войти", err:"Неверный логин или пароль", rides:"Маршруты", gps:"Карта", stats:"Статистика", profile:"Профиль", watch:"Смотреть", loading:"Загрузка…", failed:"Ошибка загрузки.", noRides:"Пока нет видео маршрутов.", noLoc:"Нет данных о местоположении.", kmh:"км/ч", online:"В сети", offline:"Не в сети", totalRoutes:"Всего маршрутов", lastRoute:"Последний маршрут", tracked:"Отслеживаемые", trackedList:"Отслеживаемые люди", memberSub:"Участник Move Log", t_moto:"Мотоцикл", t_bike:"Велосипед", t_run:"Бег", t_walk:"Ходьба", t_other:"Другое" },
  ja: { tagline:"ルート · アクティビティ · 現在地", user:"ユーザー名", password:"パスワード", signin:"サインイン", err:"ユーザー名またはパスワードが違います", rides:"ルート", gps:"マップ", stats:"統計", profile:"プロフィール", watch:"再生", loading:"読み込み中…", failed:"読み込みに失敗しました。", noRides:"ルート動画はまだありません。", noLoc:"位置情報がありません。", kmh:"km/h", online:"オンライン", offline:"オフライン", totalRoutes:"ルート合計", lastRoute:"最新のルート", tracked:"追跡中の人数", trackedList:"追跡中の人", memberSub:"Move Log メンバー", t_moto:"バイク", t_bike:"サイクリング", t_run:"ランニング", t_walk:"ウォーキング", t_other:"その他" },
  zh: { tagline:"路线 · 活动 · 实时位置", user:"用户名", password:"密码", signin:"登录", err:"用户名或密码错误", rides:"路线", gps:"地图", stats:"统计", profile:"个人资料", watch:"播放", loading:"加载中…", failed:"加载失败。", noRides:"暂无路线视频。", noLoc:"暂无位置数据。", kmh:"公里/小时", online:"在线", offline:"离线", totalRoutes:"路线总数", lastRoute:"最新路线", tracked:"追踪人数", trackedList:"追踪的人", memberSub:"Move Log 会员", t_moto:"摩托车", t_bike:"骑行", t_run:"跑步", t_walk:"步行", t_other:"其他" },
  ko: { tagline:"경로 · 활동 · 실시간 위치", user:"사용자 이름", password:"비밀번호", signin:"로그인", err:"사용자 이름 또는 비밀번호가 올바르지 않습니다", rides:"경로", gps:"지도", stats:"통계", profile:"프로필", watch:"재생", loading:"불러오는 중…", failed:"불러오지 못했습니다.", noRides:"아직 경로 영상이 없습니다.", noLoc:"위치 데이터 없음.", kmh:"km/h", online:"온라인", offline:"오프라인", totalRoutes:"총 경로", lastRoute:"최근 경로", tracked:"추적 중인 사람", trackedList:"추적 중인 사람", memberSub:"Move Log 회원", t_moto:"오토바이", t_bike:"자전거", t_run:"달리기", t_walk:"걷기", t_other:"기타" },
  ar: { tagline:"المسارات · النشاط · الموقع المباشر", user:"اسم المستخدم", password:"كلمة المرور", signin:"تسجيل الدخول", err:"اسم المستخدم أو كلمة المرور غير صحيحة", rides:"المسارات", gps:"الخريطة", stats:"الإحصاءات", profile:"الملف", watch:"تشغيل", loading:"جارٍ التحميل…", failed:"فشل التحميل.", noRides:"لا توجد مقاطع مسارات بعد.", noLoc:"لا توجد بيانات موقع.", kmh:"كم/س", online:"متصل", offline:"غير متصل", totalRoutes:"إجمالي المسارات", lastRoute:"أحدث مسار", tracked:"الأشخاص المتتبَّعون", trackedList:"الأشخاص المتتبَّعون", memberSub:"عضو في Move Log", t_moto:"دراجة نارية", t_bike:"دراجة", t_run:"الجري", t_walk:"المشي", t_other:"أخرى" },
};
const LANG = (() => {
  const q = new URLSearchParams(location.search).get("lang");
  const cand = (q || localStorage.getItem("nd_lang") || navigator.language || "en").toLowerCase();
  const base = cand.split("-")[0];
  return I18N[cand] ? cand : (I18N[base] ? base : "en");
})();
const T = I18N[LANG];
const LOCALE = { en:"en-US", tr:"tr-TR", de:"de-DE", fr:"fr-FR", es:"es-ES", it:"it-IT", pt:"pt-BR", ru:"ru-RU", ja:"ja-JP", zh:"zh-CN", ko:"ko-KR", ar:"ar" }[LANG] || "en-US";
function applyI18n() {
  document.documentElement.lang = LANG;
  if (LANG === "ar") document.documentElement.dir = "rtl";
  document.querySelectorAll("[data-i18n]").forEach(e => e.textContent = T[e.dataset.i18n] || e.textContent);
  document.querySelectorAll("[data-i18n-ph]").forEach(e => e.placeholder = T[e.dataset.i18nPh] || "");
}
const fmtDate = (s) => { try { return new Intl.DateTimeFormat(LOCALE, { day:"numeric", month:"long", year:"numeric" }).format(new Date(s)); } catch { return s; } };

/* ---------------- DEMO MODU (App Store görselleri — sahte/yerel veri, kişisel veri YOK) ---------------- */
const DEMO = new URLSearchParams(location.search).get("demo") === "1";
const DEMO_NAMES = {
  en:["James Carter","Emma Hughes","Liam Foster","Olivia Reed"], tr:["Mehmet Demir","Elif Kaya","Ahmet Yıldız","Zeynep Şahin"],
  de:["Lukas Müller","Anna Schmidt","Jonas Weber","Lea Fischer"], fr:["Hugo Martin","Léa Dubois","Louis Bernard","Emma Laurent"],
  es:["Hugo García","Lucía Martín","Mateo López","Sofía Ruiz"], it:["Marco Rossi","Giulia Bianchi","Luca Romano","Sara Conti"],
  pt:["João Silva","Maria Souza","Pedro Costa","Ana Oliveira"], ru:["Иван Смирнов","Анна Иванова","Дмитрий Кузнецов","Мария Попова"],
  ja:["田中 健","佐藤 美咲","鈴木 大輔","高橋 結衣"], zh:["王伟","李娜","张强","刘洋"],
  ko:["김민준","이서연","박지훈","최수아"], ar:["أحمد محمد","سارة علي","خالد حسن","نور عبد الله"],
};
const DEMO_CITY = { en:[51.5074,-0.1278], tr:[41.0082,28.9784], de:[52.52,13.405], fr:[48.8566,2.3522], es:[40.4168,-3.7038], it:[41.9028,12.4964], pt:[-23.55,-46.633], ru:[55.7558,37.6173], ja:[35.6762,139.6503], zh:[31.2304,121.4737], ko:[37.5665,126.978], ar:[24.7136,46.6753] };
function demoData(path) {
  const nm = DEMO_NAMES[LANG] || DEMO_NAMES.en, types = ["moto","bike","run","walk","moto","bike"];
  const today = Date.now();
  if (path === "/api/rides" || path.startsWith("/api/rides?")) {
    return { rides: types.map((t, i) => ({ id: "d" + i, date: new Date(today - i * 5 * 864e5).toISOString().slice(0,10), type: t, mode: "flyover", size: (1.2 + i * 0.9) * 1048576 })) };
  }
  if (path.startsWith("/api/stats")) return { total_rides: 24, by_type: { moto: 11, bike: 7, run: 4, walk: 2 }, latest: { date: new Date(today).toISOString().slice(0,10) } };
  if (path.startsWith("/api/gps/live")) {
    const [la, lo] = DEMO_CITY[LANG] || DEMO_CITY.en;
    return { positions: nm.slice(1, 4).map((d, i) => ({ device: d, lat: la + (i - 1) * 0.012, lon: lo + (i - 1) * 0.014, speed_kmh: [0, 32, 0][i], online: i === 1, time: "" })) };
  }
  if (path.startsWith("/api/activities")) return { activities: [] };
  if (path === "/api/profile") return { name: demoUser(), avatar: { type: "initials" } };
  if (path === "/api/friends") return { friends: nm.slice(1, 4).map((d, i) => ({ username: d.toLowerCase().replace(/\s+/g, ""), name: d, avatar: { type: "initials" }, online: i === 1 })) };
  return {};
}
const demoUser = () => (DEMO_NAMES[LANG] || DEMO_NAMES.en)[0];

/* ---------------- TİPOGRAFİ / FONT SEÇİCİ (Premium) ---------------- */
const FONTS = [
  { id:"editorial", label:"Editorial", css:"ui-serif,'New York','Iowan Old Style',Palatino,Georgia,serif", free:true },
  { id:"classic",   label:"Classic",   css:"Georgia,'Times New Roman','Noto Serif',serif" },
  { id:"elegant",   label:"Elegant",   css:"'Palatino Linotype',Palatino,'Iowan Old Style','Book Antiqua',serif" },
  { id:"modern",    label:"Modern",    css:"-apple-system,'SF Pro Text','Segoe UI',system-ui,sans-serif" },
  { id:"rounded",   label:"Rounded",   css:"ui-rounded,'SF Pro Rounded','Hiragino Maru Gothic ProN',system-ui,sans-serif" },
];
const isPremium = () => localStorage.getItem("nd_premium") === "1" || DEMO;
function applyFont(id) {
  const f = FONTS.find(x => x.id === id) || FONTS[0];
  document.documentElement.style.setProperty("--serif", f.css);
  localStorage.setItem("nd_font", f.id);
}
function chooseFont(id) {
  const f = FONTS.find(x => x.id === id);
  if (f && !f.free && !isPremium()) { openPaywall(); return; }
  applyFont(id); loadProfile();
}
function openPaywall() { $("#paywall").classList.add("active"); }
function closePaywall() { $("#paywall").classList.remove("active"); }
function buyPremium() {
  // TODO: gerçek StoreKit IAP (Capacitor eklentisi) — şimdilik kilidi açar
  localStorage.setItem("nd_premium", "1"); closePaywall(); loadProfile();
}
applyFont(localStorage.getItem("nd_font") || "editorial");
const PREMIUM_T = {
  en:{font:"Typography",unlock:"Unlock all fonts",pdesc:"Choose the typeface you love. One-time purchase.",buy:"Unlock Premium",later:"Maybe later",premium:"PREMIUM"},
  tr:{font:"Tipografi",unlock:"Tüm fontların kilidini aç",pdesc:"Sevdiğin yazı tipini seç. Tek seferlik satın alma.",buy:"Premium'u Aç",later:"Belki sonra",premium:"PREMIUM"},
  de:{font:"Typografie",unlock:"Alle Schriften freischalten",pdesc:"Wähle deine Lieblingsschrift. Einmaliger Kauf.",buy:"Premium freischalten",later:"Später",premium:"PREMIUM"},
  fr:{font:"Typographie",unlock:"Débloquer toutes les polices",pdesc:"Choisissez votre police préférée. Achat unique.",buy:"Débloquer Premium",later:"Plus tard",premium:"PREMIUM"},
  es:{font:"Tipografía",unlock:"Desbloquea todas las fuentes",pdesc:"Elige tu tipografía favorita. Compra única.",buy:"Desbloquear Premium",later:"Más tarde",premium:"PREMIUM"},
  it:{font:"Tipografia",unlock:"Sblocca tutti i caratteri",pdesc:"Scegli il carattere che ami. Acquisto singolo.",buy:"Sblocca Premium",later:"Più tardi",premium:"PREMIUM"},
  pt:{font:"Tipografia",unlock:"Desbloqueie todas as fontes",pdesc:"Escolha sua fonte favorita. Compra única.",buy:"Desbloquear Premium",later:"Depois",premium:"PREMIUM"},
  ru:{font:"Типографика",unlock:"Откройте все шрифты",pdesc:"Выберите любимый шрифт. Разовая покупка.",buy:"Открыть Premium",later:"Позже",premium:"PREMIUM"},
  ja:{font:"書体",unlock:"すべての書体を解放",pdesc:"好きな書体を選べます。買い切り。",buy:"Premium を解放",later:"あとで",premium:"PREMIUM"},
  zh:{font:"字体",unlock:"解锁所有字体",pdesc:"选择你喜欢的字体。一次性购买。",buy:"解锁高级版",later:"以后",premium:"PREMIUM"},
  ko:{font:"서체",unlock:"모든 서체 잠금 해제",pdesc:"원하는 서체를 선택하세요. 1회 구매.",buy:"프리미엄 잠금 해제",later:"나중에",premium:"PREMIUM"},
  ar:{font:"الخطوط",unlock:"افتح كل الخطوط",pdesc:"اختر الخط الذي تحبه. شراء لمرة واحدة.",buy:"فتح Premium",later:"لاحقًا",premium:"PREMIUM"},
};
const PT = PREMIUM_T[LANG] || PREMIUM_T.en;
const FRIEND_T = {
  en:{friends:"Friends",addFriend:"Add friend",byUser:"Add by username",invite:"Invite link",copy:"Copy / Share",add:"Add",friendErr:"User not found",avTitle:"Profile picture",pickEmoji:"Choose an emoji",upload:"Upload a photo"},
  tr:{friends:"Arkadaşlar",addFriend:"Arkadaş ekle",byUser:"Kullanıcı adıyla ekle",invite:"Davet bağlantısı",copy:"Kopyala / Paylaş",add:"Ekle",friendErr:"Kullanıcı bulunamadı",avTitle:"Profil resmi",pickEmoji:"Emoji seç",upload:"Fotoğraf yükle"},
  de:{friends:"Freunde",addFriend:"Freund hinzufügen",byUser:"Per Benutzername",invite:"Einladungslink",copy:"Kopieren / Teilen",add:"Hinzufügen",friendErr:"Benutzer nicht gefunden",avTitle:"Profilbild",pickEmoji:"Emoji wählen",upload:"Foto hochladen"},
  fr:{friends:"Amis",addFriend:"Ajouter un ami",byUser:"Par identifiant",invite:"Lien d'invitation",copy:"Copier / Partager",add:"Ajouter",friendErr:"Utilisateur introuvable",avTitle:"Photo de profil",pickEmoji:"Choisir un emoji",upload:"Importer une photo"},
  es:{friends:"Amigos",addFriend:"Añadir amigo",byUser:"Por usuario",invite:"Enlace de invitación",copy:"Copiar / Compartir",add:"Añadir",friendErr:"Usuario no encontrado",avTitle:"Foto de perfil",pickEmoji:"Elige un emoji",upload:"Subir una foto"},
  it:{friends:"Amici",addFriend:"Aggiungi amico",byUser:"Per nome utente",invite:"Link d'invito",copy:"Copia / Condividi",add:"Aggiungi",friendErr:"Utente non trovato",avTitle:"Foto profilo",pickEmoji:"Scegli un'emoji",upload:"Carica una foto"},
  pt:{friends:"Amigos",addFriend:"Adicionar amigo",byUser:"Por nome de usuário",invite:"Link de convite",copy:"Copiar / Compartilhar",add:"Adicionar",friendErr:"Usuário não encontrado",avTitle:"Foto de perfil",pickEmoji:"Escolha um emoji",upload:"Enviar foto"},
  ru:{friends:"Друзья",addFriend:"Добавить друга",byUser:"По имени пользователя",invite:"Ссылка-приглашение",copy:"Копировать / Поделиться",add:"Добавить",friendErr:"Пользователь не найден",avTitle:"Фото профиля",pickEmoji:"Выберите эмодзи",upload:"Загрузить фото"},
  ja:{friends:"友だち",addFriend:"友だちを追加",byUser:"ユーザー名で追加",invite:"招待リンク",copy:"コピー / 共有",add:"追加",friendErr:"ユーザーが見つかりません",avTitle:"プロフィール写真",pickEmoji:"絵文字を選ぶ",upload:"写真をアップロード"},
  zh:{friends:"好友",addFriend:"添加好友",byUser:"按用户名添加",invite:"邀请链接",copy:"复制 / 分享",add:"添加",friendErr:"未找到用户",avTitle:"头像",pickEmoji:"选择表情",upload:"上传照片"},
  ko:{friends:"친구",addFriend:"친구 추가",byUser:"사용자 이름으로 추가",invite:"초대 링크",copy:"복사 / 공유",add:"추가",friendErr:"사용자를 찾을 수 없음",avTitle:"프로필 사진",pickEmoji:"이모지 선택",upload:"사진 업로드"},
  ar:{friends:"الأصدقاء",addFriend:"إضافة صديق",byUser:"بالاسم",invite:"رابط الدعوة",copy:"نسخ / مشاركة",add:"إضافة",friendErr:"المستخدم غير موجود",avTitle:"صورة الملف",pickEmoji:"اختر إيموجي",upload:"رفع صورة"},
};
const FT = FRIEND_T[LANG] || FRIEND_T.en;

/* ---------------- ikonlar (SVG, emoji yok) ---------------- */
const ICON = {
  moto: '<svg viewBox="0 0 24 24"><circle cx="5.5" cy="17" r="3"/><circle cx="18.5" cy="17" r="3"/><path d="M5.5 17h6l3-5h4M9 7h3l2.5 5"/></svg>',
  bike: '<svg viewBox="0 0 24 24"><circle cx="5.5" cy="17" r="3.2"/><circle cx="18.5" cy="17" r="3.2"/><path d="M5.5 17l4-7h5M9 7h4l3 10M14.5 10H8"/></svg>',
  run:  '<svg viewBox="0 0 24 24"><circle cx="14" cy="5" r="1.8"/><path d="M13 9l-3 3 2 3-1 5M13 9l3 2 3 0M10 12l-3 1"/></svg>',
  walk: '<svg viewBox="0 0 24 24"><circle cx="13" cy="5" r="1.8"/><path d="M13 8l-1 5 2 6M12 13l-3 6M13 10l3 2"/></svg>',
  other:'<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8"/><path d="M12 8v4l3 2"/></svg>',
};
const typeIcon = (t) => ICON[t] || ICON.other;
const typeLabel = (t) => T["t_" + (ICON[t] ? t : "other")];

// İsimden tutarlı renkli baş-harf avatarı (örnek profil resmi)
function avatar(name, size) {
  const parts = (name || "?").trim().split(/\s+/);
  const ini = (parts[0][0] || "?") + (parts.length > 1 ? parts[parts.length - 1][0] : "");
  let h = 0; for (const c of name || "") h = (h * 31 + c.charCodeAt(0)) % 360;
  // editöryel: susturulmuş mürekkep tonu + krem serif baş harf + ince halka
  const bg = `hsl(${h},16%,26%)`;
  return `<svg class="avatar" style="width:${size}px;height:${size}px" viewBox="0 0 100 100">
    <circle cx="50" cy="50" r="48" fill="${bg}" stroke="#1b1713" stroke-width="1.5"/>
    <text x="50" y="50" dy=".34em" text-anchor="middle" font-size="40" fill="#f4efe4" font-family="ui-serif,Georgia,'Times New Roman',serif">${ini.toUpperCase()}</text></svg>`;
}

async function api(path, opts = {}) {
  if (DEMO) return demoData(path);
  const r = await fetch(API + path, { ...opts, headers: { "Content-Type": "application/json", ...(TOKEN ? { Authorization: "Bearer " + TOKEN } : {}), ...(opts.headers || {}) } });
  if (r.status === 401) { logout(); throw new Error("401"); }
  if (!r.ok) throw new Error("HTTP " + r.status);
  return r.json();
}

// ---- auth ----
async function login() {
  $("#loginErr").textContent = "";
  try {
    const d = await fetch(API + "/auth/login", { method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ user: $("#u").value.trim(), password: $("#p").value }) }).then(r => r.ok ? r.json() : Promise.reject(r));
    TOKEN = d.token; localStorage.setItem("nd_token", TOKEN); enterApp();
  } catch (e) { $("#loginErr").textContent = T.err; }
}
function logout() { TOKEN = ""; localStorage.removeItem("nd_token"); show("login"); }
function enterApp() { show("app"); $("#title").textContent = T.rides; loadRides(); requestAnimationFrame(trackIndicator); }

// ---- kayan Liquid Glass gösterge ----
let indRAF;
function trackIndicator() {
  const bar = document.querySelector(".tabbar"), btn = bar && bar.querySelector("button.active"), ind = bar && bar.querySelector(".tab-ind");
  if (!btn || !ind) return;
  cancelAnimationFrame(indRAF); ind.style.transition = "none";
  const start = performance.now();
  (function step(now) { ind.style.transform = `translateX(${btn.offsetLeft}px)`; ind.style.width = btn.offsetWidth + "px"; if (now - start < 680) indRAF = requestAnimationFrame(step); })(start);
}
window.addEventListener("resize", trackIndicator);
window.addEventListener("orientationchange", () => setTimeout(trackIndicator, 300));

// ---- rides ----
async function loadRides() {
  const el = $("#rides"); el.innerHTML = `<div class='empty load'>${T.loading}</div>`;
  try {
    const { rides } = await api("/api/rides");
    if (!rides.length) { el.innerHTML = `<div class='empty'>${T.noRides}</div>`; return; }
    el.innerHTML = rides.map(r => `
      <div class="card">
        <div class="ic">${typeIcon(r.type)}</div>
        <div class="meta"><div class="t">${fmtDate(r.date)}</div>
          <div class="d">${typeLabel(r.type)} · ${(r.size/1024/1024).toFixed(1)} MB</div></div>
        <button class="play glass-btn" data-id="${r.id}" data-meta="${typeLabel(r.type)} · ${fmtDate(r.date)}">${T.watch}</button>
      </div>`).join("");
    el.querySelectorAll(".play").forEach(b => b.onclick = () => playVideo(b.dataset.id, b.dataset.meta));
  } catch (e) { el.innerHTML = `<div class='empty'>${T.failed}</div>`; }
}
async function playVideo(id, meta) {
  $("#vidMeta").textContent = T.loading; $("#player").classList.add("active");
  try {
    const r = await fetch(`${API}/api/rides/${id}/video`, { headers: { Authorization: "Bearer " + TOKEN } });
    $("#vid").src = URL.createObjectURL(await r.blob()); $("#vidMeta").textContent = meta; $("#vid").play().catch(() => {});
  } catch (e) { $("#vidMeta").textContent = T.failed; }
}

// ---- stats ----
async function loadStats() {
  const el = $("#stats"); el.innerHTML = `<div class='empty load'>${T.loading}</div>`;
  try {
    const s = await api("/api/stats");
    let h = `<div class="kv"><span>${T.totalRoutes}</span><b>${s.total_rides}</b></div>`;
    for (const [k, v] of Object.entries(s.by_type || {})) {
      const lbl = k === "diğer" ? T.t_other : (typeLabel(k));
      h += `<div class="kv"><span class="kvic">${typeIcon(k)}${lbl}</span><b>${v}</b></div>`;
    }
    if (s.latest) h += `<div class="kv"><span>${T.lastRoute}</span><b>${fmtDate(s.latest.date)}</b></div>`;
    el.innerHTML = h;
  } catch (e) { el.innerHTML = `<div class='empty'>${T.failed}</div>`; }
}

// ---- avatar render (emoji / foto / baş harf) ----
function renderAvatar(name, av, size) {
  av = av || { type: "initials" };
  if (av.type === "emoji") return `<span class="avatar emoji" style="width:${size}px;height:${size}px;font-size:${Math.round(size*0.6)}px">${av.value}</span>`;
  if (av.type === "photo" && av.value) return `<img class="avatar" style="width:${size}px;height:${size}px" src="${av.value.startsWith("http")||av.value.startsWith("data")?av.value:API+av.value}">`;
  return avatar(name, size);
}

// ---- profile (avatar düzenle + arkadaşlar + tipografi) ----
let MY = { name: "", avatar: { type: "initials" } };
async function loadProfile() {
  const el = $("#profile"); el.innerHTML = `<div class='empty load'>${T.loading}</div>`;
  try {
    let stats = {}, friends = [];
    try { MY = await api("/api/profile"); } catch { MY = { name: DEMO ? demoUser() : "", avatar: { type: "initials" } }; }
    try { stats = await api("/api/stats"); } catch {}
    try { friends = (await api("/api/friends")).friends || []; } catch {}
    const me = MY.name || (DEMO ? demoUser() : "");
    let h = `<div class="profhead">
        <button class="avwrap" id="editAv">${renderAvatar(me, MY.avatar, 96)}<span class="avedit"><svg viewBox="0 0 24 24"><path d="M4 20h4l10-10-4-4L4 16v4Z"/><path d="M13.5 6.5l4 4"/></svg></span></button>
        <div class="profname">${me}</div>
        <div class="profsub">${T.memberSub}</div>
      </div>
      <div class="profstats">
        <div class="ps"><b>${stats.total_rides ?? "–"}</b><span>${T.totalRoutes}</span></div>
        <div class="ps"><b>${friends.length}</b><span>${FT.friends}</span></div>
      </div>
      <div class="sechead">${FT.friends}</div>`;
    h += friends.map(f => `
        <div class="card person">
          ${renderAvatar(f.name || f.username, f.avatar, 46)}
          <div class="meta"><div class="t">${f.name || f.username}</div>
            <div class="d">@${f.username} · ${f.online ? T.online : T.offline}</div></div>
          <span class="dot ${f.online ? "on" : "off"}"></span>
        </div>`).join("");
    h += `<button class="rowbtn" id="addFriend"><svg viewBox="0 0 24 24"><circle cx="9" cy="8" r="3.4"/><path d="M3.5 20a5.5 5.5 0 0 1 11 0M18 8v6M21 11h-6"/></svg>${FT.addFriend}</button>`;
    // tipografi
    h += `<div class="sechead">${PT.font}</div>`;
    h += FONTS.map(f => {
      const sel = (localStorage.getItem("nd_font") || "editorial") === f.id;
      const locked = !f.free && !isPremium();
      return `<button class="fontrow${sel ? " sel" : ""}" data-font="${f.id}">
        <span style="font-family:${f.css}">${f.label}</span>
        ${locked ? `<span class="lock"><svg viewBox="0 0 24 24"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg></span>` : (sel ? `<span class="chk"><svg viewBox="0 0 24 24"><path d="M5 12l5 5 9-10"/></svg></span>` : "")}
      </button>`;
    }).join("");
    el.innerHTML = h;
    $("#editAv").onclick = openAvatarEditor;
    $("#addFriend").onclick = openAddFriend;
    el.querySelectorAll(".fontrow").forEach(b => b.onclick = () => chooseFont(b.dataset.font));
  } catch (e) { el.innerHTML = `<div class='empty'>${T.failed}</div>`; }
}

// ---- avatar editor (emoji seç / foto yükle) ----
const EMOJIS = ["🙂","😎","🧑","👩","🧔","👨‍🦰","🧑‍🦱","👱","🦊","🐺","🦁","🐯","🦅","🏍️","🚲","🏃","🏔️","🌊","⚡️","🔥","⭐️","🎯"];
function openAvatarEditor() {
  $("#emojiGrid").innerHTML = EMOJIS.map(e => `<button class="emojibtn">${e}</button>`).join("");
  $("#emojiGrid").querySelectorAll(".emojibtn").forEach(b => b.onclick = () => setAvatar({ type: "emoji", value: b.textContent }));
  $("#avEditor").classList.add("active");
}
function closeAvEditor() { $("#avEditor").classList.remove("active"); }
async function setAvatar(av) {
  MY.avatar = av;
  if (!DEMO) { try { await api("/api/profile", { method: "PUT", body: JSON.stringify({ avatar: av }) }); } catch {} }
  closeAvEditor(); loadProfile();
}
function pickPhoto() { $("#photoInput").click(); }
$("#photoInput") && ($("#photoInput").onchange = (e) => {
  const file = e.target.files[0]; if (!file) return;
  const rd = new FileReader();
  rd.onload = async () => {
    // küçült (max 512) -> dataURL; backend varsa yükle
    const img = new Image(); img.onload = async () => {
      const s = 512, c = document.createElement("canvas"); c.width = c.height = s;
      const ctx = c.getContext("2d"), r = Math.min(img.width, img.height);
      ctx.drawImage(img, (img.width - r) / 2, (img.height - r) / 2, r, r, 0, 0, s, s);
      const data = c.toDataURL("image/jpeg", 0.85);
      if (DEMO) { setAvatar({ type: "photo", value: data }); return; }
      try { const res = await api("/api/profile/photo", { method: "POST", body: JSON.stringify({ data }) }); setAvatar({ type: "photo", value: res.url }); }
      catch { setAvatar({ type: "photo", value: data }); }
    }; img.src = rd.result;
  };
  rd.readAsDataURL(file);
});

// ---- arkadaş ekle (kullanıcı adı veya davet linki) ----
function openAddFriend() { $("#friendErr").textContent = ""; $("#friendU").value = ""; $("#addFriendModal").classList.add("active"); refreshInvite(); }
function closeAddFriend() { $("#addFriendModal").classList.remove("active"); }
async function refreshInvite() {
  let link = "https://app.nickdegs.com/?invite=demo1234";
  if (!DEMO) { try { link = (await api("/api/invite", { method: "POST" })).link || link; } catch {} }
  $("#inviteLink").value = link;
}
async function submitFriend() {
  const u = $("#friendU").value.trim().replace(/^@/, "");
  if (!u) return;
  if (DEMO) { closeAddFriend(); return; }
  try { await api("/api/friends", { method: "POST", body: JSON.stringify({ username: u }) }); closeAddFriend(); loadProfile(); }
  catch { $("#friendErr").textContent = FT.friendErr; }
}
function copyInvite() { const i = $("#inviteLink"); i.select(); try { navigator.clipboard.writeText(i.value); } catch {} if (navigator.share) navigator.share({ url: i.value }).catch(() => {}); }

// ---- gps ----
async function loadGps() {
  if (!map) { map = L.map("map", { zoomControl: false }).setView([40.978, 37.924], 12);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", { maxZoom: 19 }).addTo(map); }
  setTimeout(() => map.invalidateSize(), 100);
  try {
    const { positions } = await api("/api/gps/live");
    $("#gpsInfo").innerHTML = positions.map(p => `<span class="gpschip"><span class="dot ${p.online ? "on" : "off"}"></span>${p.device} · ${p.speed_kmh} ${T.kmh}</span>`).join("") || `<div class='empty'>${T.noLoc}</div>`;
    positions.forEach(p => { if (markers[p.device]) markers[p.device].setLatLng([p.lat, p.lon]); else markers[p.device] = L.marker([p.lat, p.lon]).addTo(map).bindPopup(p.device); });
    if (positions[0]) map.setView([positions[0].lat, positions[0].lon], 14);
  } catch (e) { $("#gpsInfo").innerHTML = `<div class='empty'>${T.noLoc}</div>`; }
}

// ---- tabs ----
const LOADERS = { rides: loadRides, gps: loadGps, stats: loadStats, profile: loadProfile };
function switchTab(name) {
  document.querySelectorAll(".tab").forEach(t => t.classList.remove("active"));
  $("#tab-" + name).classList.add("active");
  document.querySelectorAll(".tabbar button").forEach(b => b.classList.toggle("active", b.dataset.tab === name));
  trackIndicator();
  $("#title").textContent = T[name];
  (LOADERS[name] || (() => {}))();
}

// ---- wire ----
applyI18n();
// modallar
(function initModals() {
  $("#avTitle").textContent = FT.avTitle; $("#uploadPhoto").textContent = FT.upload;
  $("#avClose").onclick = closeAvEditor; $("#uploadPhoto").onclick = pickPhoto;
  $("#afTitle").textContent = FT.addFriend; $("#byUserL").textContent = FT.byUser;
  $("#friendAdd").textContent = FT.add; $("#inviteL").textContent = FT.invite; $("#inviteCopy").textContent = FT.copy;
  $("#afClose").onclick = closeAddFriend; $("#friendAdd").onclick = submitFriend; $("#inviteCopy").onclick = copyInvite;
  $("#pwPremium").textContent = PT.premium; $("#pwDesc").textContent = PT.pdesc;
  $("#pwBuy").textContent = PT.buy; $("#pwLater").textContent = PT.later;
  $("#pwBuy").onclick = buyPremium; $("#pwLater").onclick = closePaywall;
  document.querySelectorAll(".modal.sheet").forEach(m => m.addEventListener("click", e => { if (e.target === m) m.classList.remove("active"); }));
})();
$("#loginBtn").onclick = login;
$("#p").addEventListener("keydown", e => { if (e.key === "Enter") login(); });
$("#logout").onclick = logout;
$("#closePlayer").onclick = () => { $("#vid").pause(); $("#vid").src = ""; $("#player").classList.remove("active"); };
document.querySelectorAll(".tabbar button").forEach(b => b.onclick = () => switchTab(b.dataset.tab));

// liquid glass ripple
document.addEventListener("pointerdown", (e) => {
  const btn = e.target.closest(".login-box button, .glass-btn, .iconbtn");
  if (!btn) return;
  const rect = btn.getBoundingClientRect(), rp = document.createElement("span");
  rp.className = "ripple"; const size = Math.max(rect.width, rect.height);
  rp.style.width = rp.style.height = size + "px"; rp.style.left = (e.clientX - rect.left) + "px"; rp.style.top = (e.clientY - rect.top) + "px";
  btn.appendChild(rp); setTimeout(() => rp.remove(), 600);
}, { passive: true });

if (TOKEN) api("/api/rides").then(enterApp).catch(() => show("login")); else show("login");
