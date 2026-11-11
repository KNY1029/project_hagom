# iOS WidgetKit 설정

현재 저장소에는 WidgetKit 렌더러 초안(`HagomWidgetExtension_Template.swift`)과 앱-위젯 공유용 App Group 설정이 포함되어 있다.

Mac에서 Xcode로 최종 연결할 때:

1. `Runner.xcworkspace`를 연다.
2. `File > New > Target... > Widget Extension`으로 Widget Extension 타깃을 추가한다.
3. 생성된 Swift 파일을 `HagomWidgetExtension_Template.swift`의 구현으로 교체한다.
4. Runner와 Widget Extension 양쪽의 `Signing & Capabilities`에 App Groups를 추가하고 다음 그룹을 선택한다.
   `group.com.healthpharma.hagom_app`
5. Widget Extension의 `kind`와 Flutter의 iOS 위젯 이름을 동일하게 맞춘다.
6. Apple Developer 계정에서 App Group을 등록하고 실제 iPhone에서 서명 빌드한다.

앱 코드에서는 `HomeWidget.setAppGroupId('group.com.healthpharma.hagom_app')`를 호출하도록 연결되어 있다. Windows에서는 이 파일과 프로젝트 설정을 준비할 수 있지만, Xcode 타깃 생성·서명·iPhone 설치는 Mac 또는 macOS CI가 필요하다.
