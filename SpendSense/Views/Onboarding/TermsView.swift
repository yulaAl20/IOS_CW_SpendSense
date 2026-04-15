//
//  TermsView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-15.
//

import SwiftUI

struct TermsView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @State private var hasScrolledToBottom = false
    @State private var accepted = false
    @State private var showDeclineAlert = false

    var body: some View {
        VStack(spacing: 0) {

            // Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(LinearGradient.ssAccentGradient)
                    Text("Terms & Privacy")
                        .font(SSFont.display(20, weight: .bold))
                        .foregroundColor(.ssTextPrimary)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)

                Text("Please read and accept our terms to continue")
                    .font(SSFont.body(14))
                    .foregroundColor(.ssTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                Divider()
                    .background(Color.ssBorder)
                    .padding(.top, 8)
            }

            // Scrollable terms
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    TermsSection(
                        title: "1. Data Collection & Usage",
                        icon: "server.rack",
                        text: "SpendSense collects financial data you enter manually, including income, expenses, and budget preferences. All data is stored locally on your device using Core Data. We do not transmit your financial information to external servers without your explicit consent.\n\nBy using this app, you acknowledge that the financial data you enter is your own and that SpendSense is not responsible for any inaccuracies in manually entered data."
                    )

                    TermsSection(
                        title: "2. Biometric Authentication",
                        icon: "faceid",
                        text: "SpendSense may use Face ID or Touch ID to protect sensitive financial actions such as modifying budget limits or approving high-value transactions. Biometric data is processed entirely by your device's secure enclave and is never accessed or stored by SpendSense."
                    )

                    TermsSection(
                        title: "3. Location Services",
                        icon: "location.fill",
                        text: "SpendSense requests access to your device location to deliver proactive budget alerts when you enter high-spending zones. Location data is used only on-device for notification triggers and is not transmitted or stored beyond the current session. You may disable location access at any time in iOS Settings."
                    )

                    TermsSection(
                        title: "4. Machine Learning & Analytics",
                        icon: "cpu.fill",
                        text: "SpendSense uses on-device machine learning (Core ML) to analyze your spending patterns and generate behavioral risk scores. This processing happens entirely on your device. No spending data is used to train external models or shared with third parties."
                    )

                    TermsSection(
                        title: "5. Notifications",
                        icon: "bell.fill",
                        text: "SpendSense will request permission to send you push notifications for budget warnings, location-based alerts, and spending insights. You may manage notification preferences at any time through iOS Settings. SpendSense will never send promotional or marketing notifications."
                    )

                    TermsSection(
                        title: "6. Financial Disclaimer",
                        icon: "exclamationmark.triangle.fill",
                        text: "SpendSense is a personal budgeting tool and does not constitute financial advice. The app's suggestions and risk scores are based on user-entered data and behavioral patterns. SpendSense is not a licensed financial institution and is not responsible for financial decisions made based on in-app information. Please consult a qualified financial advisor for professional guidance."
                    )

                    TermsSection(
                        title: "7. Liability",
                        icon: "shield.fill",
                        text: "SpendSense is provided 'as is' without any warranties. We are not liable for any data loss, financial loss, or damages arising from the use of this application. You are responsible for maintaining backups of your financial data."
                    )

                    TermsSection(
                        title: "8. Acceptance & Updates",
                        icon: "arrow.clockwise",
                        text: "By tapping 'I Agree & Continue', you confirm that you are at least 18 years of age and agree to these Terms of Use and Privacy Policy. We may update these terms periodically. Continued use of the app after updates constitutes your acceptance of the revised terms."
                    )

                    // Bottom spacer
                    Color.clear.frame(height: 20)
                        .background(
                            GeometryReader { geo in
                                Color.clear.onAppear {
                                    hasScrolledToBottom = true
                                }
                            }
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .background(Color.ssBackground)

            // Bottom action
            VStack(spacing: 0) {
                Divider().background(Color.ssBorder)

                VStack(spacing: 16) {
                    // Checkbox
                    Button(action: { accepted.toggle() }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(accepted ? Color.ssAccent : Color.ssBorder, lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                                if accepted {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.ssAccent)
                                        .frame(width: 22, height: 22)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.ssBackground)
                                }
                            }
                            Text("I have read and agree to the Terms of Use and Privacy Policy")
                                .font(SSFont.body(13))
                                .foregroundColor(.ssTextSecondary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    // Accept button
                    Button(action: {
                        guard accepted else { return }
                        appState.acceptTerms()
                    }) {
                        HStack {
                            Text("I Agree & Continue")
                                .font(SSFont.display(16, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(accepted ? Color.ssBackground : Color.ssTextTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            Group {
                                if accepted {
                                    LinearGradient.ssAccentGradient
                                        .cornerRadius(14)
                                } else {
                                    Color.ssSurfaceElevated
                                        .cornerRadius(14)
                                }
                            }
                        )
                    }
                    .disabled(!accepted)
                    .animation(.easeInOut(duration: 0.2), value: accepted)

                    Button("Decline") {
                        showDeclineAlert = true
                    }
                    .font(SSFont.body(13))
                    .foregroundColor(.ssTextTertiary)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(Color.ssSurface)
            }
        }
        .background(Color.ssBackground.ignoresSafeArea())
        .alert("Decline Terms?", isPresented: $showDeclineAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Exit App", role: .destructive) {
                exit(0)
            }
        } message: {
            Text("You must accept the terms to use SpendSense. The app will close if you decline.")
        }
    }
}

//  Terms Section
struct TermsSection: View {
    var title: String
    var icon: String
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.ssAccent)
                    .frame(width: 20)
                Text(title)
                    .font(SSFont.display(15, weight: .semibold))
                    .foregroundColor(.ssTextPrimary)
            }
            Text(text)
                .font(SSFont.body(13))
                .foregroundColor(.ssTextSecondary)
                .lineSpacing(5)
        }
        .padding(16)
        .background(Color.ssSurfaceElevated)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.ssBorder, lineWidth: 1)
        )
    }
}

#if DEBUG
struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsView()
            .environmentObject(AppStateViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif
