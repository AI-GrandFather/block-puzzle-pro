import Foundation
import Supabase
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var userEmail: String?
    @Published var lastError: String?
    @Published private(set) var isAuthenticating = false

    private let redirectURL = URL(string: "blockpuzzlepro://auth-callback")!
    private let cloudStore: CloudSaveStore

    init(cloudStore: CloudSaveStore) {
        self.cloudStore = cloudStore
        Task {
            await loadCachedSession()
        }
    }

    func loadCachedSession() async {
        if let current = try? await SupabaseService.shared.auth.session {
            session = current
            userEmail = current.user.email
            cloudStore.configure(session: current)
            await cloudStore.refresh(for: current)
        } else {
            cloudStore.configure(session: nil)
        }
    }

    func signInWithGoogle() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            try await SupabaseService.shared.auth.signInWithOAuth(
                provider: .google,
                redirectTo: redirectURL
            )
        } catch {
            lastError = error.localizedDescription
        }
    }

    func handleRedirect(url: URL) async {
        SupabaseService.shared.auth.handle(url)

        if let newSession = try? await SupabaseService.shared.auth.session {
            session = newSession
            userEmail = newSession.user.email
            lastError = nil
            cloudStore.configure(session: newSession)
            await cloudStore.refresh(for: newSession)
        }
    }

    func signOut() async {
        do {
            try await SupabaseService.shared.auth.signOut()
            session = nil
            userEmail = nil
            cloudStore.configure(session: nil)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func clearError() {
        lastError = nil
    }
}
