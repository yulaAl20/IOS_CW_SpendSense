//
//  SpendingZonesMapView.swift
//  SpendSense
//
//  Created by Yulani Alwis on 2026-04-16.
//

import SwiftUI
import MapKit

struct SpendingZonesMapView: View {
    @ObservedObject private var locationService = LocationNotificationService.shared

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 6.9108, longitude: 79.8607),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        ZStack {
            Color.ssBackground.ignoresSafeArea()

            VStack(spacing: 14) {
                Map(
                    coordinateRegion: $region,
                    showsUserLocation: true,
                    annotationItems: locationService.zones
                ) { zone in
                    MapAnnotation(coordinate: zone.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.ssAccent)

                            Text(zone.name)
                                .font(SSFont.body(10, weight: .semibold))
                                .foregroundColor(.ssTextPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.ssSurface.opacity(0.9))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.ssBorder, lineWidth: 1)
                                )
                        }
                    }
                }
                .frame(height: 280)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ssBorder, lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("High-spending areas", systemImage: "location.fill")
                            .font(SSFont.display(15, weight: .bold))
                            .foregroundColor(.ssTextPrimary)

                        Spacer()

                        if let zone = locationService.currentZoneName {
                            Text("In: \(zone)")
                                .font(SSFont.body(12, weight: .semibold))
                                .foregroundColor(.ssAccent)
                        }
                    }

                    Text("Tap below to simulate entering a high-spending zone and receive a push notification alert.")
                        .font(SSFont.body(12))
                        .foregroundColor(.ssTextTertiary)

                    Button {
                        locationService.simulateFirstZoneEntry()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "location.viewfinder")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Simulate zone entry")
                                .font(SSFont.body(14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient.ssAccentGradient)
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Color.ssSurface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.ssBorder, lineWidth: 1))
                .padding(.horizontal, 20)

                List {
                    ForEach(locationService.zones) { zone in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(zone.name)
                                    .font(SSFont.body(14, weight: .semibold))
                                    .foregroundColor(.ssTextPrimary)
                                Text("Radius: \(Int(zone.radius))m")
                                    .font(SSFont.body(12))
                                    .foregroundColor(.ssTextSecondary)
                            }

                            Spacer()

                            Button("Open") {
                                locationService.mapItem(for: zone).openInMaps(launchOptions: nil)
                            }
                            .font(SSFont.body(12, weight: .semibold))
                            .foregroundColor(.ssAccent)
                        }
                        .listRowBackground(Color.ssSurface)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.ssBackground)
            }
        }
        .navigationTitle("Spending Zones")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#if DEBUG
struct SpendingZonesMapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SpendingZonesMapView()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
