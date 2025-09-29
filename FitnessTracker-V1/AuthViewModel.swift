import Foundation
import FirebaseAuth

final class AuthViewModel: ObservableObject {
  @Published var isAuthenticated = Auth.auth().currentUser != nil
  @Published var isBusy = false
  @Published var errorMessage: String?

  func refresh() { isAuthenticated = (Auth.auth().currentUser != nil) }

  // MARK: - Email/Password
  func signUp(email: String, password: String) {
    isBusy = true; errorMessage = nil
    Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
      DispatchQueue.main.async {
        self?.isBusy = false
        if let error = error { self?.errorMessage = error.localizedDescription; return }
        self?.isAuthenticated = (result?.user != nil)
      }
    }
  }

  func signIn(email: String, password: String) {
    isBusy = true; errorMessage = nil
    Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
      DispatchQueue.main.async {
        self?.isBusy = false
        if let error = error { self?.errorMessage = error.localizedDescription; return }
        self?.isAuthenticated = (result?.user != nil)
      }
    }
  }

  func sendPasswordReset(email: String) {
    isBusy = true; errorMessage = nil
    Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
      DispatchQueue.main.async {
        self?.isBusy = false
        if let error = error { self?.errorMessage = error.localizedDescription }
      }
    }
  }

  func signOut() {
    do { try Auth.auth().signOut(); isAuthenticated = false }
    catch { errorMessage = error.localizedDescription }
  }

  func deleteAccount(completion: @escaping (Bool)->Void) {
    Auth.auth().currentUser?.delete { [weak self] error in
      DispatchQueue.main.async {
        if let error = error { self?.errorMessage = error.localizedDescription; completion(false); return }
        self?.isAuthenticated = false
        completion(true)
      }
    }
  }
}
