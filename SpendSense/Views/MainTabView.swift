//
//  MainTabView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-02.
//


import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppStateViewModel
    @EnvironmentObject var vm: SpendSenseViewModel
    @State private var showAddSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch appState.selectedTab {
                case .home:
                    NavigationStack {
                        HomeView()
                    }
                case .budget:
                    BudgetView()
                case .add:
                    EmptyView()
                case .insights:
                    InsightsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            CustomTabBar(showAddSheet: $showAddSheet)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAddSheet) {
            AddTransactionSheet()
                .environmentObject(vm)
        }
    }
}

// Custom Tab Bar
struct CustomTabBar: View {
    @EnvironmentObject var appState: AppStateViewModel
    @Binding var showAddSheet: Bool
    @Namespace private var namespace

    var body: some View {
        HStack {
            ForEach(TabItem.allCases, id: \.self) { tab in
                if tab == .add {
                    Button(action: { showAddSheet = true }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.ssAccentGradient)
                                .frame(width: 56, height: 56)
                                .shadow(color: .ssAccent.opacity(0.5), radius: 12, x: 0, y: 4)
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .offset(y: -20)
                } else {
                    TabBarItem(
                        tab: tab,
                        isSelected: appState.selectedTab == tab,
                        namespace: namespace
                    ) {
                        appState.selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .background(
            Capsule()
                .fill(Color.ssSurface.opacity(0.8))
                .frame(height: 70)
                .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                .shadow(radius: 20)
        )
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// Tab Bar Item
struct TabBarItem: View {
    var tab: TabItem
    var isSelected: Bool
    let namespace: Namespace.ID
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(Color.ssAccent.opacity(0.3))
                            .matchedGeometryEffect(id: "highlight", in: namespace)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .secondary)
                }
                .frame(height: 40)
                
                Text(tab.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .animation(.spring(), value: isSelected)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
}
#if DEBUG
struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabBar(showAddSheet: .constant(false))
            .environmentObject(AppStateViewModel())
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
#endif
