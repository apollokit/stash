import SwiftUI
import Combine

struct AuthView: View {
    @EnvironmentObject var supabase: SupabaseService

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "121826")
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Stash")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(Color(hex: "838CF1"))

                        Text("Save and organize your web content")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)

                    Spacer()

                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color(hex: "212936"))
                            .cornerRadius(8)
                            .foregroundColor(.white)

                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color(hex: "212936"))
                            .cornerRadius(8)
                            .foregroundColor(.white)

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: handleAuth) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text(isSignUp ? "Sign Up" : "Sign In")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "838CF1"))
                        .disabled(isLoading)

                        Button(action: { isSignUp.toggle() }) {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "838CF1"))
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func handleAuth() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                if isSignUp {
                    try await supabase.signUp(email: email, password: password)
                    errorMessage = "Check your email for confirmation link"
                    isSignUp = false
                } else {
                    try await supabase.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
