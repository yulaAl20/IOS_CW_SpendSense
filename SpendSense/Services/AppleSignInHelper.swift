//
//  AppleSignInHelper.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-25.
//
import AuthenticationServices
import CryptoKit
import FirebaseAuth

@MainActor
final class AppleSignInHelper: NSObject, ObservableObject {

    //Public result
    struct SignInResult {
        let uid: String
        let email: String
        let displayName: String
    }

    private var currentNonce: String?
    private var continuation: CheckedContinuation<SignInResult, Error>?

    /// Kicks off the Sign in with Apple sheet and returns the Firebase UID on success.
    func signIn() async throws -> SignInResult {
        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont

            let nonce = Self.randomNonceString()
            currentNonce = nonce

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }

    //  Nonce helpers

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess { fatalError("Unable to generate nonce.") }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

//  ASAuthorizationControllerDelegate

extension AppleSignInHelper: ASAuthorizationControllerDelegate {

    nonisolated func authorizationController(controller: ASAuthorizationController,
                                             didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            guard
                let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = appleIDCredential.identityToken,
                let idTokenString = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve Apple ID token."]))
                continuation = nil
                return
            }

            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: idTokenString,
                rawNonce: nonce
            )

            do {
                let result = try await Auth.auth().signIn(with: credential)

                // Apple only provides the name on the FIRST sign-in.
                let fullName = appleIDCredential.fullName
                let displayName = [fullName?.givenName, fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")

                let email = result.user.email
                    ?? appleIDCredential.email
                    ?? ""

                continuation?.resume(returning: SignInResult(
                    uid: result.user.uid,
                    email: email,
                    displayName: displayName
                ))
            } catch {
                continuation?.resume(throwing: error)
            }
            continuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController,
                                             didCompleteWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}
