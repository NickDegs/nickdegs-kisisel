import SwiftUI

struct LoginView: View {
    @EnvironmentObject var store: Store
    @AppStorage("nd_scheme") var scheme = "dark"
    @State private var cc = "+90"
    @State private var phone = ""
    @State private var code = ""
    @State private var codeSent = false
    @State private var busy = false
    @State private var float = false
    @State private var shown = false
    @FocusState private var focus: Field?
    enum Field { case phone, code }

    private var fullPhone: String {
        let c = cc.hasPrefix("+") ? cc : "+" + cc
        return c + phone.filter(\.isNumber)
    }

    var body: some View {
        ZStack {
            AuroraBackground()
            VStack(spacing: 0) {
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Brand.gradient)
                    .frame(width: 84, height: 84)
                    .glassPanel(24)
                    .offset(y: float ? -7 : 0)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: float)
                    .padding(.bottom, 18)
                Text("Move Log").font(.system(size: 40, weight: .heavy))
                Text(L("Rotalar · Aktivite · Canlı konum", "Routes · Activity · Live location"))
                    .font(.subheadline).foregroundStyle(.secondary).padding(.top, 4).padding(.bottom, 26)

                if !codeSent {
                    // 1) Telefon numarası
                    HStack(spacing: 10) {
                        TextField("+90", text: $cc)
                            .frame(width: 64)
                            .multilineTextAlignment(.center)
                            .keyboardType(.phonePad)
                        Divider().frame(height: 22)
                        TextField(L("Telefon numarası", "Phone number"), text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .focused($focus, equals: .phone)
                    }
                    .padding(16).glassPanel(18)

                    if store.loginError {
                        Text(L("Numara gönderilemedi, tekrar dene", "Couldn't send, try again"))
                            .font(.footnote).foregroundStyle(.red).padding(.top, 12)
                    }

                    Button {
                        busy = true
                        Task {
                            let ok = await store.smsStart(fullPhone)
                            busy = false
                            if ok { withAnimation { codeSent = true }; focus = .code }
                        }
                    } label: {
                        HStack { if busy { ProgressView().tint(.white) }
                            Text(L("Kod gönder", "Send code")) }
                    }
                    .buttonStyle(.glassyProminent())
                    .disabled(busy || phone.filter(\.isNumber).count < 7)
                    .padding(.top, 22)

                    Text(L("Telefon numaranıza SMS ile tek kullanımlık kod göndereceğiz.",
                           "We'll text a one-time code to your phone."))
                        .font(.caption2).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.top, 14)

                } else {
                    // 2) SMS kodu
                    Text(L("Kod gönderildi: ", "Code sent to: ") + fullPhone)
                        .font(.footnote).foregroundStyle(.secondary).padding(.bottom, 12)

                    TextField(L("6 haneli kod", "6-digit code"), text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .focused($focus, equals: .code)
                        .padding(16).glassPanel(18)

                    if store.loginError {
                        Text(L("Kod hatalı veya süresi doldu", "Incorrect or expired code"))
                            .font(.footnote).foregroundStyle(.red).padding(.top, 12)
                    }

                    Button {
                        busy = true
                        Task { await store.smsVerify(fullPhone, code.filter(\.isNumber)); busy = false }
                    } label: {
                        HStack { if busy { ProgressView().tint(.white) }
                            Text(L("Doğrula ve gir", "Verify & sign in")) }
                    }
                    .buttonStyle(.glassyProminent())
                    .disabled(busy || code.filter(\.isNumber).count < 4)
                    .padding(.top, 22)

                    HStack(spacing: 18) {
                        Button(L("Numarayı değiştir", "Change number")) {
                            withAnimation { codeSent = false; code = ""; store.loginError = false }
                        }
                        Button(L("Tekrar gönder", "Resend")) {
                            Task { _ = await store.smsStart(fullPhone) }
                        }
                    }
                    .font(.footnote).foregroundStyle(Brand.accent).padding(.top, 16)
                }
            }
            .padding(28).frame(maxWidth: 400)
            .scaleEffect(shown ? 1 : 0.96)
            .opacity(shown ? 1 : 0)
            .blur(radius: shown ? 0 : 6)
        }
        .onAppear {
            float = true
            withAnimation(.smooth(duration: 0.6)) { shown = true }
        }
        .task {
            // CI/iPad doğrulaması: launch-arg ile gerçek giriş (kullanıcı bu yolu tetikleyemez)
            if let c = AppEnv.autoLogin, store.token.isEmpty { await store.login(c.user, c.pass) }
        }
    }
}
