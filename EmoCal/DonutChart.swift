import SwiftUI

struct DonutChart: View {
    struct Segment: Identifiable {
        let id = UUID()
        var color: Color
        var value: Double
    }

    var segments: [Segment]
    var lineWidth: CGFloat = 24
    /// 隙間（ポイント指定）
    var gapPoints: CGFloat = 8
    /// 背景トラック
    var showTrack: Bool = false
    var trackColor: Color = .secondary.opacity(0.15)

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let r = size / 2.0
            let circumference = 2.0 * .pi * r

            let total = max(segments.map(\.value).reduce(0, +), 0.0001)
            var cursor = 0.0
            let slices: [(seg: Segment, start: Double, end: Double)] = segments.map { s in
                let frac = s.value / total
                defer { cursor += frac }
                return (s, cursor, cursor + frac)
            }

            // 丸端の出っ張りを円周比に換算
            let halfCapFrac = (lineWidth / 2.0) / circumference
            let gapFrac = max(0, gapPoints / circumference)
            let trimPad = gapFrac / 2.0 + halfCapFrac

            ZStack {
                if showTrack {
                    Circle().stroke(trackColor, lineWidth: lineWidth)
                }
                ForEach(slices, id: \.seg.id) { slice in
                    let from = min(max(0.0, slice.start + trimPad), 1.0)
                    let to   = max(0.0, min(1.0, slice.end   - trimPad))
                    if to > from {
                        Circle()
                            .trim(from: from, to: to)
                            .stroke(slice.seg.color,
                                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .shadow(color: slice.seg.color.opacity(0.45), radius: 6, y: 3)
                    }
                }
            }
            .padding(lineWidth / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
