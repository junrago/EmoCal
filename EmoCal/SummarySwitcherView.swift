import SwiftUI

struct SummarySwitcherView: View {
    @Binding var feelings: [DateComponents: Feeling]
    @Binding var notes: [DateComponents: String]

    enum SummaryMode { case week, month }
    @State private var mode: SummaryMode = .week

    var body: some View {
        VStack(spacing: 12) {
            // トグル
            HStack(spacing: 12) {
                CapsuleToggle(title: "Weekly", isOn: mode == .week) { mode = .week }
                CapsuleToggle(title: "Monthly", isOn: mode == .month) { mode = .month }
            }
            .padding(.top, 8)

            // 中身
            if mode == .week {
                WeeklySummaryView(feelings: $feelings, notes: $notes)
            } else {
                MonthlySummaryView(feelings: $feelings, notes: $notes)
            }
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
    }

    // 小さなカプセルボタン
    private func CapsuleToggle(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isOn ? .primary : .secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Capsule().fill(isOn ? Color.primary.opacity(0.1) : .clear))
        }
        .buttonStyle(.plain)
    }
}
