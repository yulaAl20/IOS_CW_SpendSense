//
//  SpendSenseWidgetLiveActivity.swift
//  SpendSenseWidget
//
//  Created by Yulani Alwis on 2026-04-15.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SpendSenseWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SpendSenseWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpendSenseWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension SpendSenseWidgetAttributes {
    fileprivate static var preview: SpendSenseWidgetAttributes {
        SpendSenseWidgetAttributes(name: "World")
    }
}

extension SpendSenseWidgetAttributes.ContentState {
    fileprivate static var smiley: SpendSenseWidgetAttributes.ContentState {
        SpendSenseWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SpendSenseWidgetAttributes.ContentState {
         SpendSenseWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SpendSenseWidgetAttributes.preview) {
   SpendSenseWidgetLiveActivity()
} contentStates: {
    SpendSenseWidgetAttributes.ContentState.smiley
    SpendSenseWidgetAttributes.ContentState.starEyes
}
