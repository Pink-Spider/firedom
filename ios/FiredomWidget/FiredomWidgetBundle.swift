// W1 홈 위젯 번들 (WidgetKit 진입점)
//
// Xcode의 Widget Extension 템플릿이 생성한 파일. 진입점(@main)은 여기 하나뿐이고,
// 실제 위젯 구현은 FiredomWidget.swift에 있다.
//
// 템플릿이 함께 만든 FiredomWidgetControl(제어 센터 위젯)과
// FiredomWidgetLiveActivity(라이브 액티비티)는 파이어덤에서 쓰지 않으므로 등록하지 않는다.

import SwiftUI
import WidgetKit

@main
struct FiredomWidgetBundle: WidgetBundle {
    var body: some Widget {
        FiredomWidget()
    }
}
