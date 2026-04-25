//
//  GoogleSignInHelper.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-25.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

@MainActor
final class GoogleSignInHelper {

    struct SignInResult {
        let uid: String
        let email: String
        let displayName: String
    }

    static let shared = GoogleSignInHelper()
    private init() {}

    /// Presents the Google Sign-In sheet and returns the Firebase UID on success.
    func signIn() async throws -> SignInResult {

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "GoogleSignIn", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing Firebase clientID."])
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "GoogleSignIn", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "No root view controller found."])
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "GoogleSignIn", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to retrieve Google ID token."])
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)

        return SignInResult(
            uid: authResult.user.uid,
            email: authResult.user.email ?? result.user.profile?.email ?? "",
            displayName: authResult.user.displayName ?? result.user.profile?.name ?? ""
        )
    }
}
