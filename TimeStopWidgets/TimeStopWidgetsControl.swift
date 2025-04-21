import SwiftUI
import WidgetKit
import AppIntents

// Main widget configuration
struct TimeStopWidgetsControl: WidgetConfiguration {
    var body: some WidgetConfiguration {
        ControlWidgetConfiguration {
            // Individual controls - no conditional logic in the result builder
            controlFor(id: "startFocus", title: "专注", label: "开始专注")
            controlFor(id: "quickFocus15", title: "15分钟", label: "15分钟")
            controlFor(id: "quickFocus25", title: "25分钟", label: "25分钟")
            controlFor(id: "quickFocus30", title: "30分钟", label: "30分钟")
            controlFor(id: "quickFocus45", title: "45分钟", label: "45分钟")
            controlFor(id: "quickFocus60", title: "60分钟", label: "60分钟")
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("专注控制")
        .description("快速启动或者停止专注计时")
    }
    
    // Generic control builder to avoid repetition
    @ViewBuilder
    private func controlFor(id: String, title: String, label: String) -> some View {
        Control {
            TimeStopButtonIntent(id: id, title: title)
        } label: {
            Label(label, systemImage: "timer")
        }
    }
}

// Fix for the AppIntent protocol implementation
struct TimeStopButtonIntent: AppIntent, ControlIntent {
    static var title: LocalizedStringResource = "TimeStop控制"
    
    @Parameter(title: "Action ID")
    var id: String
    
    @Parameter(title: "Button Title")
    var title: String
    
    init() {
        self.id = ""
        self.title = ""
    }
    
    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
    
    // AppIntent protocol requirement for iOS 17.6+
    func perform() async throws -> IntentResult {
        // Handle different actions based on id
        switch id {
        case "startFocus":
            // Start focus timer
            print("Starting focus timer")
        case "quickFocus15":
            print("Starting 15 minute quick focus")
        case "quickFocus25":
            print("Starting 25 minute quick focus")
        case "quickFocus30":
            print("Starting 30 minute quick focus")
        case "quickFocus45":
            print("Starting 45 minute quick focus")
        case "quickFocus60":
            print("Starting 60 minute quick focus")
        default:
            print("Unknown action: \(id)")
        }
        
        return .result()
    }
} 