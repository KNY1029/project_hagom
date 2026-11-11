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

## Mac에서 앱 설치까지

프로젝트를 처음 받는 경우:

```bash
git clone -b dev/kny https://github.com/KNY1029/project_hagom.git
cd project_hagom/app
flutter pub get
cd ios
pod install
open Runner.xcworkspace
```

Xcode에서 `Runner`와 Widget Extension의 `Signing & Capabilities`에 같은 App Group을 추가한 뒤, 아이폰을 연결하고 Team을 선택한다. 개발용으로 앱만 설치하려면:

```bash
cd ~/project_hagom/app
flutter devices
flutter run -d <아이폰 장치 ID>
```

`<아이폰 장치 ID>`는 `flutter devices` 결과의 값을 그대로 넣는다. 무료 Apple 계정으로 Xcode에서 설치한 개발용 앱은 Personal Team 프로비저닝 제한 때문에 보통 7일 후 다시 빌드·설치해야 한다.

## Windows에서 Sideloadly로 설치하는 경우

Windows에서 설치하려면 먼저 Mac 또는 macOS CI에서 iOS용 IPA를 만들어야 한다. Xcode에서 `Product > Archive`를 실행한 뒤 `Distribute App`에서 개발용 또는 Ad Hoc 방식으로 export하면 `.ipa`가 생성된다. 그 IPA를 Windows로 옮긴다.

Windows에서는 다음 순서로 설치한다.

1. Sideloadly와 Windows용 iTunes/iCloud를 설치한다.
2. 아이폰을 USB로 연결하고 컴퓨터를 신뢰한다.
3. Sideloadly에 IPA를 끌어 넣는다.
4. 본인의 Apple ID로 로그인하고 `Start`를 누른다.
5. 아이폰에서 개발자 모드를 켜고, 설치된 앱을 실행한다.

무료 Apple ID로 Sideloadly에서 재서명한 앱은 일반적으로 7일마다 다시 설치해야 한다. 다른 사람에게 IPA 파일만 전달해도 그대로 실행되는 것은 아니며, 각 기기와 Apple ID에 맞춰 다시 서명해야 한다.

## 현재 지원 범위

Flutter 앱 화면과 App Group 연결 기반은 준비되어 있다. `HagomWidgetExtension_Template.swift`는 현재 하곰이 마스코트용 WidgetKit 예시이며, 복약·습관·달력 위젯을 iOS에서도 모두 제공하려면 Widget Extension 안에 각 위젯을 추가 구현해야 한다. Android의 위젯 크기 설정(`2x1`, `4x4`)은 iOS에 그대로 적용되지 않는다.
