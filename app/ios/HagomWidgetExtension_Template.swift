import WidgetKit
import SwiftUI

// 🐻 [iOS WidgetKit] 하곰이 마스코트 및 복약/습관 런처 위젯 정의
// home_widget 패키지와 완벽 호환되는 AppGroup UserDefaults 데이터 기반 렌더러

struct HagomWidgetEntry: TimelineEntry {
    let date: Date
    let badge: String
    let quote: String
    let sub: String
    let imageName: String
}

struct HagomWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HagomWidgetEntry {
        HagomWidgetEntry(
            date: Date(),
            badge: "1. 기대",
            quote: "유저가 접속해서 기록을 이어갈 것이라 믿고 웃어주는 모습",
            sub: "다정한 응원 푸시",
            imageName: "hagom_widget_stage_1"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HagomWidgetEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HagomWidgetEntry>) -> ()) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func loadEntry() -> HagomWidgetEntry {
        // AppGroup을 통해 플러터와 공유된 UserDefaults 읽기
        let sharedDefaults = UserDefaults(suiteName: "group.com.healthpharma.hagom_app")
        let badge = sharedDefaults?.string(forKey: "mascot_badge") ?? "하곰이의 응원"
        let quote = sharedDefaults?.string(forKey: "mascot_quote") ?? "한 가지만 실천해도 충분해요.\n오늘 약 하나만 챙겨도 대단한 거예요."
        let sub = sharedDefaults?.string(forKey: "mascot_sub") ?? "천천히 편안한 속도로 가요"
        let imageName = sharedDefaults?.string(forKey: "mascot_image") ?? "hagom_mascot"

        return HagomWidgetEntry(date: Date(), badge: badge, quote: quote, sub: sub, imageName: imageName)
    }
}

struct HagomWidgetEntryView: View {
    var entry: HagomWidgetProvider.Entry

    var body: some View {
        HStack(spacing: 12) {
            Image(entry.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.badge)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.48, green: 0.38, blue: 0.66)) // #7B61A8
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.95, green: 0.93, blue: 0.98))
                    .cornerRadius(4)

                Text(entry.quote)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.12, green: 0.16, blue: 0.22))
                    .lineLimit(2)

                Text(entry.sub)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.50))
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .widgetURL(URL(string: "hagomwidget://openroom"))
    }
}

@main
struct HagomWidgetBundle: WidgetBundle {
    var body: some Widget {
        HagomMascotWidget()
    }
}

struct HagomMascotWidget: Widget {
    let kind: String = "HagomMascotWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HagomWidgetProvider()) { entry in
            HagomWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("하곰이 응원 위젯")
        .description("오늘의 복약과 습관을 따뜻하게 챙겨주는 하곰이 위젯이에요.")
        .supportedFamilies([.systemMedium])
    }
}
