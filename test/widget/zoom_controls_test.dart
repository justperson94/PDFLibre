import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdflibre/widgets/viewer/zoom_controls.dart';

import 'test_harness.dart';

void main() {
  group('ZoomControls', () {
    testWidgets('범위 안의 줌 값은 그대로 슬라이더에 반영된다', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(Scaffold(body: ZoomControls(zoom: 150, onChanged: (_) {}))),
      );
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 150);
      expect(find.text('150%'), findsOneWidget);
    });

    testWidgets('25% 미만 줌(가로 맞춤 등)에서도 크래시 없이 클램프된다', (tester) async {
      // pdfrx의 실제 줌 범위는 10%~800%라 슬라이더 범위(25~400)를 벗어날 수
      // 있다. 클램프가 없으면 debug에서 Slider assertion으로 크래시한다.
      await tester.pumpWidget(
        wrapWithApp(Scaffold(body: ZoomControls(zoom: 18, onChanged: (_) {}))),
      );
      expect(tester.takeException(), isNull);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 25);
      // 라벨은 실제 줌 값을 그대로 보여준다.
      expect(find.text('18%'), findsOneWidget);
    });

    testWidgets('400% 초과 줌에서도 크래시 없이 클램프된다', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(Scaffold(body: ZoomControls(zoom: 800, onChanged: (_) {}))),
      );
      expect(tester.takeException(), isNull);
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 400);
      expect(find.text('800%'), findsOneWidget);
    });
  });
}
