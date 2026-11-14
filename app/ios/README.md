# iOS WidgetKit 설정

Xcode 프로젝트에는 `HagomFreeWidgetExtension` 위젯 확장 타깃이 포함되어 있다. 이 위젯은 하곰이 이미지와 고정 응원 문구를 표시하는 독립형 위젯이며, 앱 데이터 공유나 App Groups 기능을 사용하지 않는다. 따라서 무료 Apple 계정(Personal Team)으로 개발용 앱과 함께 서명해 설치할 수 있다.

Mac에서 `Runner.xcworkspace`를 열면 `Runner`와 `HagomFreeWidgetExtension` scheme을 선택할 수 있다. 앱을 실행하면 확장도 함께 설치되며, iPhone 홈 화면을 길게 누르고 `위젯 추가`에서 `하곰이 응원 위젯`을 선택하면 된다. 위젯은 작은 크기와 중간 크기를 지원한다.

현재 무료 계정용 위젯은 앱의 복약·습관·설정 데이터와 연동하지 않는다. App Groups 기반 공유 및 동적 문구는 유료 Apple Developer Program 기능과 서명 조건을 확인한 뒤 별도로 연결해야 한다.

## Mac에서 앱 설치까지

프로젝트를 처음 받는 경우:

```bash
git clone -b main https://github.com/KNY1029/project_hagom.git
cd project_hagom/app
flutter pub get
cd ios
pod install
open Runner.xcworkspace
```

Xcode에서 `Runner` scheme을 선택하고 `Signing & Capabilities`에서 Personal Team을 지정한 뒤 아이폰을 연결한다. 위젯 확장은 Runner에 포함되어 함께 설치된다. 개발용으로 앱을 설치하려면:

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

무료 계정용 하곰이 응원 위젯 타깃과 Runner 통합이 준비되어 있다. 복약·습관·달력 위젯이나 앱 데이터 기반 문구는 현재 포함하지 않는다. Android 위젯 크기 설정(`2x1`, `4x4`)은 iOS에 그대로 적용되지 않는다.
