//
//  SpendSenseWidgetBundle.swift
//  SpendSenseWidget
//
//  Created by Yulani Alwis on 2026-04-15.
//

import WidgetKit
import SwiftUI

@main
struct SpendSenseWidgetBundle: WidgetBundle {
    var body: some Widget {
        SpendSenseWidget()
        SpendSenseWidgetControl()
        SpendSenseWidgetLiveActivity()
    }
}
