import SwiftUI

struct RootTabView: View {
    @State private var feelings: [DateComponents: Feeling] = [:]
    @State private var notes: [DateComponents: String] = [:]

    enum Tab { case calendar, summary }
    @State private var selected: Tab = .calendar

    var body: some View {
        TabView(selection: $selected) {
            NavigationStack {
                ContentView(feelings: $feelings, notes: $notes)
                    .navigationTitle("Calendar")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("Calendar", systemImage: "calendar") }
            .tag(Tab.calendar)

            NavigationStack {
                SummarySwitcherView(feelings: $feelings, notes: $notes)
            }
            .tabItem { Label("Summary", systemImage: "chart.pie.fill") }
            .tag(Tab.summary)
        }
        .tint(.black)
    }
}

#Preview { RootTabView() }
