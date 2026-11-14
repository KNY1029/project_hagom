import WidgetKit
import SwiftUI

/// 무료 Apple 계정용 독립형 하곰이 응원 위젯.
/// App Group이나 앱 데이터에 의존하지 않아 Personal Team으로 테스트할 수 있다.
struct HagomFreeWidgetEntry: TimelineEntry {
    let date: Date
}

struct HagomFreeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HagomFreeWidgetEntry {
        HagomFreeWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (HagomFreeWidgetEntry) -> Void) {
        completion(HagomFreeWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HagomFreeWidgetEntry>) -> Void) {
        let entry = HagomFreeWidgetEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 60))))
    }
}

struct HagomFreeWidgetEntryView: View {
    var entry: HagomFreeWidgetProvider.Entry

    var body: some View {
        HStack(spacing: 10) {
            Image("hagom_widget_stage_1")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 5) {
                Text("한 가지만 실천해도 충분해요🌱")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.22))
                    .lineLimit(3)
                Text("오늘도 따뜻한 응원")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white)
        .widgetURL(URL(string: "hagomwidget://openroom"))
    }
}

@main
struct HagomFreeWidget: Widget {
    let kind = "HagomFreeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HagomFreeWidgetProvider()) { entry in
            HagomFreeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("하곰이 응원 위젯")
        .description("하곰이 이미지와 따뜻한 응원 문구를 보여줘요.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
