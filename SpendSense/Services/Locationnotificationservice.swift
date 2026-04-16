//
//  Locationnotificationservice.swift
//  SpendSense
//
//  Created by COBSCCOMP242P-066 on 2026-04-16.
//

import Foundation
import CoreLocation
import MapKit
import UserNotifications

struct SpendingZone: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
}

final class LocationNotificationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = LocationNotificationService()

    private let manager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentZoneName: String? = nil

    var onDailyBudgetRemaining: (() -> Double)?

    let zones: [SpendingZone] = [
        SpendingZone(name: "One Galle Face Mall",  coordinate: CLLocationCoordinate2D(latitude: 6.9186,  longitude: 79.8476), radius: 250),
        SpendingZone(name: "Majestic City",        coordinate: CLLocationCoordinate2D(latitude: 6.8886,  longitude: 79.8554), radius: 180),
        SpendingZone(name: "Liberty Plaza",        coordinate: CLLocationCoordinate2D(latitude: 6.8978,  longitude: 79.8589), radius: 180),
        SpendingZone(name: "Odel",                 coordinate: CLLocationCoordinate2D(latitude: 6.9108,  longitude: 79.8607), radius: 180),
        SpendingZone(name: "Food Street Area",     coordinate: CLLocationCoordinate2D(latitude: 6.9271,  longitude: 79.8612), radius: 250),
        SpendingZone(name: "Crescat Boulevard",    coordinate: CLLocationCoordinate2D(latitude: 6.8939,  longitude: 79.8529), radius: 180),
        SpendingZone(name: "WTC Food Court",       coordinate: CLLocationCoordinate2D(latitude: 6.9326,  longitude: 79.8447), radius: 200),
    ]
// instead this , get from map --- FIX
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermissions() {
        manager.requestAlwaysAuthorization()
    }

    func startMonitoring() {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        let status = manager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }

        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }

        for zone in zones {
            let region = CLCircularRegion(
                center: zone.coordinate,
                radius: zone.radius,
                identifier: zone.name
            )
            region.notifyOnEntry = true
            region.notifyOnExit  = false
            manager.startMonitoring(for: region)
        }

        manager.startUpdatingLocation()
    }

    func stopMonitoring() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        manager.stopUpdatingLocation()
    }

    func simulateEntry(zone: SpendingZone) {
        let remaining = onDailyBudgetRemaining?() ?? 0
        DispatchQueue.main.async {
            self.currentZoneName = zone.name
        }
        SpendSenseNotificationService.shared.sendLocationAlert(
            zoneName: zone.name,
            remainingBudget: remaining
        )
    }

    func simulateFirstZoneEntry() {
        guard let first = zones.first else { return }
        simulateEntry(zone: first)
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let zone = zones.first(where: { $0.name == region.identifier }) else { return }
        let remaining = onDailyBudgetRemaining?() ?? 0
        DispatchQueue.main.async { self.currentZoneName = zone.name }
        SpendSenseNotificationService.shared.sendLocationAlert(
            zoneName: zone.name,
            remainingBudget: remaining
        )
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        DispatchQueue.main.async { self.currentZoneName = nil }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async { self.authorizationStatus = status }
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startMonitoring()
        }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("[Location] Monitoring failed for region \(region?.identifier ?? "?"): \(error)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Location] Manager error: \(error)")
    }

    func mapItem(for zone: SpendingZone) -> MKMapItem {
        let placemark = MKPlacemark(coordinate: zone.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = zone.name
        return item
    }
}
