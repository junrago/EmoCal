import SwiftUI

struct MonthlySummaryView: View {
    @Binding var feelings: [DateComponents: Feeling]
    @Binding var notes: [DateComponents: String]

    @State private var monthAnchor = Date()
    private let cal = Calendar(identifier: .gregorian)

    private var monthStart: Date {
        cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor))!
    }
    private var monthEnd: Date {
        cal.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
    }

    private var daysOfMonth: [Date] {
        let range = cal.range(of: .day, in: .month, for: monthStart)!
        return range.compactMap { day in cal.date(byAdding: .day, value: day - 1, to: monthStart) }
    }

    // 集計（Intensity込み）
    private var sums: [Emotion: Double] {
        var dict: [Emotion: Double] = [:]
        for d in daysOfMonth {
            if let f = feelings[key(for: d)] {
                dict[f.emotion, default: 0] += f.intensity.rawValue
            }
        }
        return dict
    }
    private var total: Double { sums.values.reduce(0, +) }
    private var dominant: (emotion: Emotion, ratio: Double)? {
        guard let (emo, v) = sums.max(by: { $0.value < $1.value }), total > 0 else { return nil }
        return (emo, v / total)
    }

    private func bestDay(for emo: Emotion) -> (date: Date?, note: String?) {
        var best: (date: Date, score: Double)? = nil
        for d in daysOfMonth {
            if let f = feelings[key(for: d)], f.emotion == emo {
                let s = f.intensity.rawValue
                if best == nil || s > best!.score { best = (d, s) }
            }
        }
        if let b = best { return (b.date, notes[key(for: b.date)]) }
        return (nil, nil)
    }

    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー（Weeklyと同じ形式）
            HStack {
                Button { monthAnchor = cal.date(byAdding: .month, value: -1, to: monthAnchor)! } label: {
                    Image(systemName: "chevron.left").foregroundColor(.gray).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: 6) {
                    Text("Monthly Summary").font(.title3.weight(.semibold))
                    Text("\(rangeTitle(from: monthStart, to: monthEnd))")
                        .font(.system(size: 18, weight: .thin))
                }
                Spacer()
                Button { monthAnchor = cal.date(byAdding: .month, value: 1, to: monthAnchor)! } label: {
                    Image(systemName: "chevron.right").foregroundColor(.gray).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            // ドーナツ
            DonutChart(
                segments: Emotion.allCases.map { .init(color: $0.color, value: sums[$0] ?? 0) },
                lineWidth: 22,
                gapPoints: 8,
                showTrack: false
            )
            .frame(width: 220, height: 220)
            .overlay {
                VStack(spacing: 6) {
                    Text(dominant?.emotion.label ?? "No data")
                        .font(.title2.weight(.semibold))
                    Text(total == 0 ? "0%" : "\(Int((dominant?.ratio ?? 0) * 100))%")
                        .font(.title2.weight(.bold))
                }
            }
            .padding(.top, 8)

            // Most day カード
            let grid = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
            LazyVGrid(columns: grid, spacing: 16) {
                SummaryCard(title: "Most fun day",   emo: .fun,     info: bestDay(for: .fun))
                SummaryCard(title: "Most happy day", emo: .joy,     info: bestDay(for: .joy))
                SummaryCard(title: "Most sad day",   emo: .sadness, info: bestDay(for: .sadness))
                SummaryCard(title: "Most angry day", emo: .anger,   info: bestDay(for: .anger))
            }
            .padding(.horizontal, 16)

            Spacer()
        }
    }

    // MARK: - Subviews

    private struct SummaryCard: View {
        let title: String
        let emo: Emotion
        let info: (date: Date?, note: String?)

        private var formatter: DateFormatter {
            let f = DateFormatter()
            f.locale = .init(identifier: "en_US_POSIX")
            f.calendar = .init(identifier: .gregorian)
            f.dateFormat = "M/d"
            return f
        }

        var body: some View {
            VStack(spacing: 8) {
                Text(title).font(.subheadline.weight(.semibold))
                if let d = info.date {
                    Text(formatter.string(from: d)).font(.subheadline)
                } else {
                    Text("—").font(.subheadline)
                }
                if let n = info.note, !n.isEmpty {
                    Text(n).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                } else {
                    Text("No memo").font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    private func key(for date: Date) -> DateComponents {
        cal.dateComponents([.year, .month, .day], from: date)
    }
    private func rangeTitle(from: Date, to: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.calendar = cal
        f.dateFormat = "yyyy/M/d"
        return "\(f.string(from: from))〜\(f.string(from: to))"
    }
}
