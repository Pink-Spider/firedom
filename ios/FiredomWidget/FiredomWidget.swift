// W1 홈 위젯 (iOS WidgetKit)
//
// 주의: 이 파일은 Xcode에서 Widget Extension 타겟을 추가한 뒤에만 빌드된다.
// 설정 방법은 docs/W1_홈위젯_iOS_설정.md 참조.
// 데이터는 App Group(group.app.firedom.firedom)의 UserDefaults로 공유된다.
// 금액은 절대 표시하지 않는다 (PRD W1 프라이버시 원칙).

import SwiftUI
import WidgetKit

private let appGroupId = "group.app.firedom.firedom"

struct FiredomEntry: TimelineEntry {
    let date: Date
    let ddayText: String
    let progress: Int
    let deviationText: String
}

struct FiredomProvider: TimelineProvider {
    func placeholder(in context: Context) -> FiredomEntry {
        FiredomEntry(date: Date(), ddayText: "자유까지 11년 3개월", progress: 34, deviationText: "계획보다 3개월 앞")
    }

    func getSnapshot(in context: Context, completion: @escaping (FiredomEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FiredomEntry>) -> Void) {
        completion(Timeline(entries: [loadEntry()], policy: .never))
    }

    private func loadEntry() -> FiredomEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        return FiredomEntry(
            date: Date(),
            ddayText: defaults?.string(forKey: "dday_text") ?? "계획을 만들어보세요",
            progress: defaults?.integer(forKey: "progress") ?? 0,
            deviationText: defaults?.string(forKey: "deviation_text") ?? ""
        )
    }
}

struct FiredomWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: FiredomEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("파이어덤")
                .font(.caption2)
                .foregroundColor(.orange)
            Text(entry.ddayText)
                .font(.headline)
                .minimumScaleFactor(0.7)
            ProgressView(value: Double(entry.progress), total: 100)
                .tint(.orange)
            if family != .systemSmall && !entry.deviationText.isEmpty {
                Text(entry.deviationText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(4)
    }
}

struct FiredomWidget: Widget {
    let kind: String = "FiredomWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FiredomProvider()) { entry in
            FiredomWidgetView(entry: entry)
        }
        .configurationDisplayName("FIRE D-day")
        .description("재정적 자유까지 남은 시간과 진행률 — 금액은 표시하지 않아요")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
