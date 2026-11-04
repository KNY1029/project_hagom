package com.healthpharma.hagom_app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // 🚀 singleTop 모드에서 들어온 새로운 위젯 클릭 인텐트로 갱신!
        // 플러터 엔진이 최신 intent.data URI를 즉시 읽을 수 있게 보장합니다.
        setIntent(intent)
    }
}
