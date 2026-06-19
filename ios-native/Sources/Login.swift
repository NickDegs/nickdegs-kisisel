import SwiftUI

struct LoginView: View {
    @EnvironmentObject var store: Store
    @State private var user = ""; @State private var pass = ""
    @State private var float = false
    @State private var shown = false
    var body: some View {
        ZStack {
            AuroraBackground()
            VStack(spacing: 0) {
                // Marka rozeti (yüzen, cam)
                Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Brand.gradient)
                    .frame(width: 84, height: 84)
                    .glassPanel(24)
                    .offset(y: float ? -7 : 0)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: float)
                    .padding(.bottom, 18)
                Text("Move Log").font(.system(size: 40, weight: .heavy))
                Text(L("Rotalar · Aktivite · Canlı konum","Routes · Activity · Live location"))
                    .font(.subheadline).foregroundStyle(.secondary).padding(.top, 4).padding(.bottom, 26)

                VStack(spacing: 12) {
                    TextField(L("Kullanıcı","Username"), text: $user)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Divider()
                    SecureField(L("Parola","Password"), text: $pass)
                }
                .padding(16).glassPanel(18)

                if store.loginError {
                    Text(L("Kullanıcı adı veya parola hatalı","Incorrect username or password"))
                        .font(.footnote).foregroundStyle(.red).padding(.top, 12)
                }

                Button(L("Giriş yap","Sign in")) {
                    Task { await store.login(user.trimmingCharacters(in: .whitespaces), pass) }
                }
                .buttonStyle(.glassyProminent()).padding(.top, 22)
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
