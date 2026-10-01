import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// 스토어 스크린샷 촬영 드라이버. 실행은 `tool/screenshots.sh`.
///
/// `integration_test/screenshots_test.dart`가 호출한 takeScreenshot의 결과를
/// `store_assets/screenshots/PREFIX/LOCALE/NAME.png`로 저장한다.
Future<void> main() => integrationDriver(
      onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final file = File('store_assets/screenshots/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        stdout.writeln('저장: ${file.path} (${bytes.length ~/ 1024}KB)');
        return true;
      },
    );
