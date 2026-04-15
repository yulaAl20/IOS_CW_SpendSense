//
//  AuthFeatureRow.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-02.

import SwiftUI

struct AuthFeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }
            Text(text)
                .font(SSFont.body(14))
                .foregroundColor(.ssTextSecondary)
            Spacer()
        }
    }
}
