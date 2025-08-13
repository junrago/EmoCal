import SwiftUI

struct ContentView: View {
    @State private var monthAnchor = Date()
    @Binding var feelings: [DateComponents: Feeling]
    @Binding var notes: [DateComponents: String]

    @State private var sheetDate = Date()
    @State private var showSheet = false
    @State private var tempNote = ""
    @State private var tempEmotion: Emotion? = nil
    @State private var tempIntensity: Intensity = .very

    var body: some View {
        VStack(spacing: 0) {
            header.padding(.bottom, 60)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdaySymbols(), id: \.self) { s in
                    Text(s).font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 15)

            let grid = monthGrid(for: monthAnchor)
            let weeks = grid.chunked(into: 7)

            VStack(spacing: 16) {
                ForEach(weeks.indices, id: \.self) { w in
                    let week = weeks[w]
                    ZStack(alignment: .top) {
                        weekBand(for: week)
                        HStack(spacing: 6) {
                            ForEach(week, id: \.self) { d in
                                let comps = d.map { key(for: $0) }
                                let feeling = comps.flatMap { feelings[$0] }
                                let note = comps.flatMap { notes[$0] } ?? ""

                                DayCell(
                                    date: d,
                                    color: feeling?.emotion.color,
                                    opacity: feeling.map { $0.intensity.rawValue } ?? 1.0,
                                    noteExists: !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                )
                                .frame(height: 30)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    guard let date = d else { return }
                                    sheetDate = date
                                    let k = key(for: date)
                                    tempEmotion = feelings[k]?.emotion
                                    tempIntensity = feelings[k]?.intensity ?? .very
                                    tempNote = notes[k] ?? ""
                                    showSheet = true
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 0)
        }
        .padding(.top, 40)
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 20) {
                Text(dateTitle(sheetDate)).font(.headline)

                // 感情
                HStack(spacing: 12) {
                    ForEach(Emotion.allCases, id: \.self) { e in
                        Button { tempEmotion = e } label: {
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(e.color.opacity(tempEmotion == e ? 1.0 : 0.6))
                                    .frame(width: 28, height: 28)
                                Text(e.label).font(.caption2)
                            }
                        }.buttonStyle(.plain)
                    }
                }

                // 強度
                if let chosen = tempEmotion {
                    VStack(spacing: 8) {
                        Text("Intensity").font(.caption).foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            ForEach(Intensity.allCases, id: \.self) { level in
                                Button { tempIntensity = level } label: {
                                    Circle()
                                        .fill(chosen.color.opacity(level.rawValue))
                                        .overlay(
                                            Circle().stroke(level == tempIntensity ? Color.primary.opacity(0.25) : .clear, lineWidth: 2)
                                        )
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(level.label)
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                // メモ
                VStack(alignment: .leading, spacing: 6) {
                    Text("Memo").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $tempNote)
                        .frame(minHeight: 120)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                }
                .padding(.horizontal)

                HStack {
                    Button("Save") {
                        let k = key(for: sheetDate)
                        if let e = tempEmotion {
                            feelings[k] = Feeling(emotion: e, intensity: tempIntensity)
                        } else {
                            feelings.removeValue(forKey: k)
                        }
                        let trimmed = tempNote.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty { notes.removeValue(forKey: k) } else { notes[k] = trimmed }
                        showSheet = false
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Clear", role: .destructive) {
                        let k = key(for: sheetDate)
                        feelings.removeValue(forKey: k)
                        notes.removeValue(forKey: k)
                        showSheet = false
                    }
                    .buttonStyle(.bordered)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: parts

    private var header: some View {
        HStack {
            Button {
                monthAnchor = Calendar.current.date(byAdding: .month, value: -1, to: monthAnchor)!
            } label: { Image(systemName: "chevron.left").foregroundColor(.gray) }
            Spacer()
            Text(monthTitle(for: monthAnchor)).font(.title3.bold())
            Spacer()
            Button {
                monthAnchor = Calendar.current.date(byAdding: .month, value: 1, to: monthAnchor)!
            } label: { Image(systemName: "chevron.right").foregroundColor(.gray) }
        }
        .padding(.horizontal, 12)
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    }

    // 週の帯（強度で透明度ブレンド）
    private func weekBand(for week: [Date?]) -> some View {
        let colors: [Color] = week.map { d in
            guard let d else { return .clear }
            if let f = feelings[key(for: d)] {
                return f.emotion.color.opacity(0.55 * f.intensity.rawValue)
            }
            return .clear
        }
        let gradient = LinearGradient(colors: colors.isEmpty ? [.clear] : colors,
                                      startPoint: .leading, endPoint: .trailing)
        return gradient
            .frame(height: 12)
            .blur(radius: 10)
            .compositingGroup()
            .mask(RoundedRectangle(cornerRadius: 10))
            .offset(y: 30)
            .allowsHitTesting(false)
    }

    // MARK: date helpers

    private func monthTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = .init(identifier: "en_US_POSIX")
        f.calendar = .init(identifier: .gregorian)
        f.dateFormat = "LLLL  yyyy"
        return f.string(from: date)
    }

    private func dateTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = .init(identifier: "en_US_POSIX")
        f.calendar = .init(identifier: .gregorian)
        f.dateFormat = "MMM d, yyyy (EEE)"
        return f.string(from: date)
    }

    private func weekdaySymbols() -> [String] {
        var cal = Calendar(identifier: .gregorian); cal.locale = Locale(identifier: "en_US")
        let base = cal.shortStandaloneWeekdaySymbols
        let start = cal.firstWeekday - 1
        return Array(base[start...] + base[..<start]).map { String($0.prefix(2)).uppercased() }
    }

    private func monthGrid(for anchor: Date) -> [Date?] {
        let cal = Calendar(identifier: .gregorian)
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: anchor))!
        let days = cal.range(of: .day, in: .month, for: startOfMonth)!.count
        let firstWD = cal.component(.weekday, from: startOfMonth)
        let offset = (firstWD - cal.firstWeekday + 7) % 7

        var grid = Array<Date?>(repeating: nil, count: offset)
        for d in 0..<days { grid.append(cal.date(byAdding: .day, value: d, to: startOfMonth)!) }
        while grid.count % 7 != 0 { grid.append(nil) }
        return grid
    }

    private func key(for date: Date) -> DateComponents {
        var cal = Calendar(identifier: .gregorian); cal.timeZone = .current
        return cal.dateComponents([.year, .month, .day], from: date)
    }
}

// 1日セル
private struct DayCell: View {
    let date: Date?
    let color: Color?
    let opacity: Double
    let noteExists: Bool

    var body: some View {
        ZStack(alignment: .top) {
            if let d = date {
                let day = Calendar.current.component(.day, from: d)
                let isToday = Calendar.current.isDateInToday(d)

                RoundedRectangle(cornerRadius: 8)
                    .fill(isToday ? Color.gray.opacity(0.12) : Color.clear)

                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        if noteExists {
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundStyle((color ?? .gray).opacity(opacity))
                        }
                    }
                    .padding(.top, 2)

                    Spacer(minLength: 0)
                    Text("\(day)").font(.callout).foregroundStyle(.primary)
                }
                .padding(.vertical, 2)

                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday ? Color.gray : .clear, lineWidth: 1)
            } else {
                Color.clear
            }
        }
    }
}

// 配列を等分
private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0+size, count)]) }
    }
}
