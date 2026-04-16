//
//  OnboardingView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-15.
//
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var spendVM: SpendSenseViewModel
    @StateObject private var vm = OnboardingViewModel()

    @State private var isCreatingAccount = false
    @State private var accountErrorMsg   = ""
    @State private var showAccountError  = false

    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: 10) {
                HStack(spacing: 4) {
                    ForEach(0..<vm.totalSteps, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i <= vm.currentStep ? Color.ssAccent : Color.ssBorder)
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                            .animation(.easeInOut(duration: 0.3), value: vm.currentStep)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)

                HStack {
                    Text("Step \(vm.currentStep + 1) of \(vm.totalSteps)")
                        .font(SSFont.body(13)).foregroundColor(.ssTextSecondary)
                    Spacer()
                    Text(stepTitle)
                        .font(SSFont.body(13, weight: .medium)).foregroundColor(.ssAccent)
                }
                .padding(.horizontal, 24)
            }

            TabView(selection: $vm.currentStep) {
                OnboardingStep0(vm: vm).tag(0)
                OnboardingStep1(vm: vm).tag(1)
                OnboardingStep2(vm: vm).tag(2)
                OnboardingStep3(vm: vm).tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: vm.currentStep)

            if showAccountError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.ssDanger)
                    Text(accountErrorMsg).font(SSFont.body(13)).foregroundColor(.ssDanger)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            VStack(spacing: 0) {
                Divider().background(Color.ssBorder)

                HStack(spacing: 12) {
                    if vm.currentStep > 0 {
                        Button(action: vm.back) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left").font(.system(size: 13, weight: .bold))
                                Text("Back").font(SSFont.body(15, weight: .semibold))
                            }
                            .foregroundColor(.ssTextSecondary)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(Color.ssSurfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: handleNext) {
                        ZStack {
                            if isCreatingAccount {
                                ProgressView().tint(.black.opacity(0.6))
                            } else {
                                HStack(spacing: 8) {
                                    Text(vm.currentStep == vm.totalSteps - 1 ? "Get Started" : "Continue")
                                        .font(SSFont.body(16, weight: .semibold))
                                    Image(systemName: vm.currentStep == vm.totalSteps - 1 ? "checkmark" : "arrow.right")
                                        .font(.system(size: 13, weight: .bold))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .foregroundColor(.black.opacity(0.75))
                        .background(
                            vm.isCurrentStepValid && !isCreatingAccount
                                ? AnyView(LinearGradient.ssAccentGradient)
                                : AnyView(Color.ssBorder)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: vm.isCurrentStepValid ? .ssAccentGlow : .clear, radius: 8, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                    .disabled(!vm.isCurrentStepValid || isCreatingAccount)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color.ssSurface)
        }
        .background(Color.ssBackground.ignoresSafeArea())
    }

    private var stepTitle: String {
        switch vm.currentStep {
        case 0: return "Your Name"
        case 1: return "Create Account"
        case 2: return "Income & Savings"
        case 3: return "Categories"
        default: return ""
        }
    }

    func handleNext() {
        if vm.currentStep == vm.totalSteps - 1 {
            if vm.usedSocialSignUp {
                finishOnboarding(uid: FirebaseService.shared.currentUID ?? UUID().uuidString)
                return
            }

            isCreatingAccount = true
            showAccountError  = false

            Task { @MainActor in
                do {
                    let uid = try await FirebaseService.shared.signUp(
                        email: vm.email, password: vm.password)
                    finishOnboarding(uid: uid)
                } catch {
                    isCreatingAccount = false
                    accountErrorMsg   = error.localizedDescription
                    showAccountError  = true
                }
            }
        } else {
            vm.next()
        }
    }

    private func finishOnboarding(uid: String) {
        var profile = vm.buildProfile()
        profile.firebaseUID = uid
        spendVM.saveOnboardingProfile(profile)
        appState.pendingEmail       = vm.email
        appState.pendingFirebaseUID = uid
        isCreatingAccount           = false
        appState.completeOnboarding()
    }
}

struct OnboardingStep0: View {
    @ObservedObject var vm: OnboardingViewModel
    @FocusState private var focused: Bool

    @State private var ring1Scale: CGFloat = 0.6
    @State private var ring1Opacity: Double = 0
    @State private var ring2Scale: CGFloat = 0.4
    @State private var ring2Opacity: Double = 0
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .stroke(LinearGradient.ssAccentGradient.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 130, height: 130)
                        .scaleEffect(ring1Scale).opacity(ring1Opacity)

                    Circle()
                        .stroke(LinearGradient.ssAccentGradient.opacity(0.55), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(ring2Scale).opacity(ring2Opacity)

                    Circle()
                        .fill(Color.ssSurfaceElevated)
                        .frame(width: 80, height: 80)
                        .overlay(Circle().stroke(LinearGradient.ssAccentGradient.opacity(0.4), lineWidth: 1))
                        .shadow(color: .ssAccentGlow, radius: 18)

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(LinearGradient.ssAccentGradient)
                }
                .scaleEffect(logoScale).opacity(logoOpacity)
                .padding(.top, 24)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                        logoScale = 1.0; logoOpacity = 1.0; ring2Scale = 1.0; ring2Opacity = 1.0
                    }
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.25)) {
                        ring1Scale = 1.0; ring1Opacity = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            ring1Scale = 1.06; ring1Opacity = 0.5
                        }
                    }
                }

                VStack(spacing: 8) {
                    Text("Welcome to SpendSense 👋")
                        .font(SSFont.display(28, weight: .bold)).foregroundColor(.ssTextPrimary).multilineTextAlignment(.center)
                    Text("Let's start with your name so we can personalise your experience.")
                        .font(SSFont.body(15)).foregroundColor(.ssTextSecondary).multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Your name", systemImage: "person.fill")
                        .font(SSFont.body(13, weight: .medium)).foregroundColor(.ssTextSecondary)

                    TextField("e.g. Alex", text: $vm.name)
                        .font(SSFont.display(18)).foregroundColor(.ssTextPrimary)
                        .focused($focused)
                        .padding(16)
                        .background(Color.ssSurfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(focused ? Color.ssAccent.opacity(0.6) : Color.ssBorder, lineWidth: 1.5))
                }
                .padding(.horizontal, 2)

                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill").font(.system(size: 20)).foregroundColor(.ssAccent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Your data stays private").font(SSFont.body(13, weight: .semibold)).foregroundColor(.ssTextPrimary)
                        Text("Financial data is encrypted and stored on-device.")
                            .font(SSFont.body(12)).foregroundColor(.ssTextSecondary)
                    }
                }
                .padding(14)
                .background(Color.ssAccent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.ssAccent.opacity(0.2), lineWidth: 1))

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .onTapGesture { focused = false }
    }
}

struct OnboardingStep1: View {
    @ObservedObject var vm: OnboardingViewModel
    @EnvironmentObject var appState: AppStateViewModel
    @Environment(\.colorScheme) var scheme
    @FocusState private var focused: AccountField?

    enum AccountField { case email, password, confirm }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Create Your Account\n\(vm.name.isEmpty ? "" : "👋 \(vm.name)")")
                        .font(SSFont.display(26, weight: .bold)).foregroundColor(.ssTextPrimary)
                        .multilineTextAlignment(.center).lineSpacing(2)
                    Text("Choose how you'd like to sign up.")
                        .font(SSFont.body(15)).foregroundColor(.ssTextSecondary).multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                VStack(spacing: 0) {
                    accountInputRow(icon: "envelope.fill", placeholder: "Email address",
                                    text: $vm.email, isSecure: false, field: .email)
                    Divider().overlay(Color.ssBorder).padding(.leading, 54)
                    accountInputRow(icon: "lock.fill", placeholder: "Password  (min 6 chars)",
                                    text: $vm.password, isSecure: true, field: .password)
                    Divider().overlay(Color.ssBorder).padding(.leading, 54)
                    accountInputRow(icon: "lock.shield.fill", placeholder: "Confirm password",
                                    text: $vm.confirmPassword, isSecure: true, field: .confirm)
                }
                .background(Color.ssSurface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.ssBorder, lineWidth: scheme == .dark ? 0.5 : 1))

                if !vm.confirmPassword.isEmpty && vm.password != vm.confirmPassword {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.ssDanger)
                        Text("Passwords don't match").font(SSFont.body(13)).foregroundColor(.ssDanger)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
                }

                HStack(spacing: 12) {
                    Rectangle().fill(Color.ssBorder).frame(height: 0.5)
                    Text("or sign up with").font(SSFont.body(12)).foregroundColor(.ssTextTertiary).fixedSize()
                    Rectangle().fill(Color.ssBorder).frame(height: 0.5)
                }

                VStack(spacing: 12) {
                    socialButton(icon: "apple.logo", label: "Continue with Apple",
                                 fg: scheme == .dark ? Color.white : Color.black,
                                 bg: scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06),
                                 border: scheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.12)
                    ) { vm.usedSocialSignUp = true }

                    socialButton(icon: "globe", label: "Continue with Google",
                                 fg: Color.ssTextPrimary, bg: Color.ssSurface, border: Color.ssBorder
                    ) { vm.usedSocialSignUp = true }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .onTapGesture { focused = nil }
    }

    @ViewBuilder
    private func accountInputRow(icon: String, placeholder: String,
                                  text: Binding<String>, isSecure: Bool, field: AccountField) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(focused == field ? .ssAccent : .ssTextTertiary)
                .frame(width: 20).padding(.leading, 16)
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(.emailAddress).autocapitalization(.none).autocorrectionDisabled()
                }
            }
            .font(SSFont.body(15)).foregroundColor(.ssTextPrimary).accentColor(.ssAccent)
            .focused($focused, equals: field)
            .padding(.vertical, 16).padding(.trailing, 16)
        }
    }

    @ViewBuilder
    private func socialButton(icon: String, label: String,
                               fg: Color, bg: Color, border: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 17, weight: .medium)).foregroundColor(fg)
                Text(label).font(SSFont.body(15, weight: .medium)).foregroundColor(fg)
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(border, lineWidth: scheme == .dark ? 0.5 : 1))
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingStep2: View {
    @ObservedObject var vm: OnboardingViewModel
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Finances,\n\(vm.name.isEmpty ? "Friend" : vm.name) 💰")
                        .font(SSFont.display(30, weight: .bold)).foregroundColor(.ssTextPrimary)
                    Text("Tell us your monthly income to calculate smart budgets.")
                        .font(SSFont.body(15)).foregroundColor(.ssTextSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label("Monthly Income (Rs.)", systemImage: "banknote.fill")
                        .font(SSFont.body(13, weight: .medium)).foregroundColor(.ssTextSecondary)

                    HStack(spacing: 8) {
                        Text("Rs.").font(SSFont.mono(18, weight: .semibold)).foregroundColor(.ssAccent)
                        TextField("0", text: $vm.monthlyIncome)
                            .font(SSFont.mono(22, weight: .bold)).foregroundColor(.ssTextPrimary)
                            .keyboardType(.numberPad).focused($focused)
                    }
                    .padding(16)
                    .background(Color.ssSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(focused ? Color.ssAccent.opacity(0.6) : Color.ssBorder, lineWidth: 1.5))
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Savings Goal", systemImage: "target")
                            .font(SSFont.body(13, weight: .medium)).foregroundColor(.ssTextSecondary)
                        Spacer()
                        Text("\(Int(vm.savingsGoalPercent))%")
                            .font(SSFont.mono(16, weight: .bold)).foregroundColor(.ssAccent)
                    }
                    Slider(value: $vm.savingsGoalPercent, in: 5...50, step: 5).tint(.ssAccent)
                    HStack {
                        Text("5% (Minimal)").font(SSFont.body(11)).foregroundColor(.ssTextTertiary)
                        Spacer()
                        Text("50% (Aggressive)").font(SSFont.body(11)).foregroundColor(.ssTextTertiary)
                    }
                }

                if vm.incomeDouble > 0 {
                    VStack(spacing: 0) {
                        BreakdownRow(label: "Monthly Income",
                                     value: "Rs. \(Int(vm.incomeDouble).formatted())",
                                     color: .ssTextPrimary, isBold: true)
                        Divider().background(Color.ssBorder).padding(.horizontal, 16)
                        BreakdownRow(label: "Savings (\(Int(vm.savingsGoalPercent))%)",
                                     value: "Rs. \(Int(vm.savingsAmount).formatted())",
                                     color: .ssAccent)
                        Divider().background(Color.ssBorder).padding(.horizontal, 16)
                        BreakdownRow(label: "Spendable Budget",
                                     value: "Rs. \(Int(vm.spendableAmount).formatted())",
                                     color: .ssInfo, isBold: true)
                    }
                    .background(Color.ssSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.ssBorder, lineWidth: 1))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.spring(response: 0.4), value: vm.incomeDouble)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24).padding(.top, 32)
        }
        .onTapGesture { focused = false }
    }
}

struct OnboardingStep3: View {
    @ObservedObject var vm: OnboardingViewModel
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Spending\nCategories 🗂️")
                        .font(SSFont.display(30, weight: .bold)).foregroundColor(.ssTextPrimary)
                    Text("Select the categories that apply to your lifestyle.")
                        .font(SSFont.body(15)).foregroundColor(.ssTextSecondary)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(SpendingCategory.allCases.filter { $0.isExpenseCategory }) { cat in
                        CategoryToggleCard(
                            category: cat,
                            isSelected: vm.selectedCategories.contains(cat)
                        ) {
                            if vm.selectedCategories.contains(cat) {
                                vm.selectedCategories.remove(cat)
                            } else {
                                vm.selectedCategories.insert(cat)
                            }
                        }
                    }
                }

                if vm.selectedCategories.isEmpty {
                    Text("Please select at least one category")
                        .font(SSFont.body(13)).foregroundColor(.ssDanger)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24).padding(.top, 32)
        }
    }
}

struct BreakdownRow: View {
    var label: String; var value: String; var color: Color; var isBold: Bool = false
    var body: some View {
        HStack {
            Text(label).font(SSFont.body(14)).foregroundColor(.ssTextSecondary)
            Spacer()
            Text(value)
                .font(isBold ? SSFont.mono(15, weight: .bold) : SSFont.mono(15))
                .foregroundColor(color)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

struct CategoryToggleCard: View {
    var category: SpendingCategory; var isSelected: Bool; var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color.opacity(0.2) : Color.ssSurfaceElevated)
                        .frame(width: 46, height: 46)
                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? category.color : .ssTextTertiary)
                }
                Text(category.rawValue.components(separatedBy: " ").first ?? "")
                    .font(SSFont.body(13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .ssTextPrimary : .ssTextSecondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.ssSurfaceElevated : Color.ssSurface)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? category.color.opacity(0.5) : Color.ssBorder, lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingView()
                .environmentObject(AppStateViewModel())
                .environmentObject(SpendSenseViewModel())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
            OnboardingView()
                .environmentObject(AppStateViewModel())
                .environmentObject(SpendSenseViewModel())
                .preferredColorScheme(.light)
                .previewDisplayName("Light")
        }
    }
}
#endif
