// NickDegs kişisel uygulama — frontend (çerçeve-bağımsız)
const API = "https://kisisel-api.nickdegs.com";
let TOKEN = localStorage.getItem("nd_token") || "";
let map, markers = {};

const $ = (s) => document.querySelector(s);
const show = (id) => { document.querySelectorAll(".screen").forEach(s => s.classList.remove("active")); $("#" + id).classList.add("active"); };

async function api(path, opts = {}) {
  const r = await fetch(API + path, {
    ...opts,
    headers: { "Content-Type": "application/json", ...(TOKEN ? { Authorization: "Bearer " + TOKEN } : {}), ...(opts.headers || {}) },
  });
  if (r.status === 401) { logout(); throw new Error("401"); }
  if (!r.ok) throw new Error("HTTP " + r.status);
  return r.json();
}

// ---- auth ----
async function login() {
  $("#loginErr").textContent = "";
  try {
    const d = await fetch(API + "/auth/login", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ user: $("#u").value.trim(), password: $("#p").value }),
    }).then(r => r.ok ? r.json() : Promise.reject(r));
    TOKEN = d.token; localStorage.setItem("nd_token", TOKEN);
    enterApp();
  } catch (e) { $("#loginErr").textContent = "Kullanıcı adı veya parola hatalı"; }
}
function logout() { TOKEN = ""; localStorage.removeItem("nd_token"); show("login"); }

function enterApp() { show("app"); loadRides(); requestAnimationFrame(trackIndicator); }

// ---- kayan Liquid Glass gösterge: aktif sekmeyi canlı takip et (morf) ----
let indRAF;
function trackIndicator() {
  const bar = document.querySelector(".tabbar");
  const btn = bar && bar.querySelector("button.active");
  const ind = bar && bar.querySelector(".tab-ind");
  if (!btn || !ind) return;
  cancelAnimationFrame(indRAF);
  ind.style.transition = "none"; // her frame manuel → etiket açılırken birebir izler
  const start = performance.now();
  (function step(now) {
    ind.style.transform = `translateX(${btn.offsetLeft}px)`;
    ind.style.width = btn.offsetWidth + "px";
    if (now - start < 680) indRAF = requestAnimationFrame(step);
  })(start);
}
window.addEventListener("resize", trackIndicator);
window.addEventListener("orientationchange", () => setTimeout(trackIndicator, 300));

// ---- rides ----
async function loadRides() {
  const el = $("#rides"); el.innerHTML = "<div class='empty load'>Yükleniyor…</div>";
  try {
    const { rides } = await api("/api/rides");
    if (!rides.length) { el.innerHTML = "<div class='empty'>Henüz rota videosu yok.</div>"; return; }
    el.innerHTML = rides.map(r => `
      <div class="card">
        <div class="ic">${r.emoji}</div>
        <div class="meta"><div class="t">${r.date}</div>
          <div class="d">${(r.size/1024/1024).toFixed(1)} MB · ${r.mode}</div></div>
        <button class="play" data-id="${r.id}" data-meta="${r.emoji} ${r.date}">▶ İzle</button>
      </div>`).join("");
    el.querySelectorAll(".play").forEach(b => b.onclick = () => playVideo(b.dataset.id, b.dataset.meta));
  } catch (e) { el.innerHTML = "<div class='empty'>Yüklenemedi.</div>"; }
}

async function playVideo(id, meta) {
  // token'lı video: fetch -> blob (Authorization header gerektiği için)
  $("#vidMeta").textContent = "Yükleniyor…";
  $("#player").classList.add("active");
  try {
    const r = await fetch(`${API}/api/rides/${id}/video`, { headers: { Authorization: "Bearer " + TOKEN } });
    const blob = await r.blob();
    $("#vid").src = URL.createObjectURL(blob);
    $("#vidMeta").textContent = meta;
    $("#vid").play().catch(() => {});
  } catch (e) { $("#vidMeta").textContent = "Video yüklenemedi"; }
}

// ---- activities ----
async function loadActs() {
  const el = $("#acts"); el.innerHTML = "<div class='empty load'>Yükleniyor…</div>";
  try {
    const { activities } = await api("/api/activities");
    el.innerHTML = activities.length
      ? activities.map(a => `<div class="summary">${a.summary}</div>`).join("")
      : "<div class='empty'>Aktivite özeti yok.</div>";
  } catch (e) { el.innerHTML = "<div class='empty'>Yüklenemedi.</div>"; }
}

// ---- stats ----
async function loadStats() {
  const el = $("#stats"); el.innerHTML = "<div class='empty load'>Yükleniyor…</div>";
  try {
    const s = await api("/api/stats");
    let h = `<div class="kv"><span>Toplam rota</span><b>${s.total_rides}</b></div>`;
    for (const [k, v] of Object.entries(s.by_type || {}))
      h += `<div class="kv"><span>${k}</span><b>${v}</b></div>`;
    if (s.latest) h += `<div class="kv"><span>Son rota</span><b>${s.latest.date}</b></div>`;
    el.innerHTML = h;
  } catch (e) { el.innerHTML = "<div class='empty'>Yüklenemedi.</div>"; }
}

// ---- gps ----
async function loadGps() {
  if (!map) {
    map = L.map("map", { zoomControl: false }).setView([40.978, 37.924], 12);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", { maxZoom: 19 }).addTo(map);
  }
  setTimeout(() => map.invalidateSize(), 100);
  try {
    const { positions } = await api("/api/gps/live");
    const info = positions.map(p => `<span class="gpschip"><span class="dot ${p.online ? "on" : "off"}"></span>${p.device} · ${p.speed_kmh} km/s</span>`).join("");
    $("#gpsInfo").innerHTML = info || "<div class='empty'>Konum yok.</div>";
    positions.forEach(p => {
      if (markers[p.device]) markers[p.device].setLatLng([p.lat, p.lon]);
      else markers[p.device] = L.marker([p.lat, p.lon]).addTo(map).bindPopup(p.device);
    });
    if (positions[0]) map.setView([positions[0].lat, positions[0].lon], 14);
  } catch (e) { $("#gpsInfo").innerHTML = "<div class='empty'>GPS alınamadı.</div>"; }
}

// ---- tabs ----
const LOADERS = { rides: loadRides, acts: loadActs, gps: loadGps, stats: loadStats };
const TITLES = { rides: "Rotalarım", acts: "Aktivite", gps: "Canlı GPS", stats: "İstatistik" };
function switchTab(name) {
  document.querySelectorAll(".tab").forEach(t => t.classList.remove("active"));
  $("#tab-" + name).classList.add("active");
  document.querySelectorAll(".tabbar button").forEach(b => b.classList.toggle("active", b.dataset.tab === name));
  trackIndicator();
  $("#title").textContent = TITLES[name];
  (LOADERS[name] || (() => {}))();
}

// ---- wire ----
$("#loginBtn").onclick = login;
$("#p").addEventListener("keydown", e => { if (e.key === "Enter") login(); });
$("#logout").onclick = logout;
$("#closePlayer").onclick = () => { $("#vid").pause(); $("#vid").src = ""; $("#player").classList.remove("active"); };
document.querySelectorAll(".tabbar button").forEach(b => b.onclick = () => switchTab(b.dataset.tab));

// ---- liquid glass: basınca sıvı dalga (dokunma noktasından) ----
document.addEventListener("pointerdown", (e) => {
  const btn = e.target.closest(".login-box button, .card .play, .glass-btn, header button, #closePlayer");
  if (!btn) return;
  const rect = btn.getBoundingClientRect();
  const rp = document.createElement("span");
  rp.className = "ripple";
  const size = Math.max(rect.width, rect.height);
  rp.style.width = rp.style.height = size + "px";
  rp.style.left = (e.clientX - rect.left) + "px";
  rp.style.top = (e.clientY - rect.top) + "px";
  btn.appendChild(rp);
  setTimeout(() => rp.remove(), 600);
}, { passive: true });

// auto-login if token
if (TOKEN) api("/api/rides").then(enterApp).catch(() => show("login"));
else show("login");
