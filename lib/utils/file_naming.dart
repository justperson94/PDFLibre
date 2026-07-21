import 'dart:io';
import 'dart:math';

/// [path]에 파일이 없으면 그대로, 있으면 확장자 앞에 " (2)", " (3)"…을
/// 붙여 비어 있는 경로를 반환한다.
///
/// 변환/개별 분할처럼 디렉토리에 여러 파일을 직접 쓰는 흐름에서 기존 파일을
/// 조용히 덮어쓰는 것을 막는다. 파일명 규칙에 {페이지} 토큰이 없어 같은 실행
/// 안에서 이름이 겹치는 경우에도 앞서 쓴 파일이 보존된다.
String uniqueOutputPath(String path) {
  if (!File(path).existsSync()) return path;

  // 경로 구분자는 플랫폼에 따라 '/'와 '\'가 섞일 수 있다.
  final sep = max(path.lastIndexOf('/'), path.lastIndexOf(r'\'));
  final dot = path.lastIndexOf('.');
  final hasExt = dot > sep + 1;
  final stem = hasExt ? path.substring(0, dot) : path;
  final ext = hasExt ? path.substring(dot) : '';

  for (var n = 2; ; n++) {
    final candidate = '$stem ($n)$ext';
    if (!File(candidate).existsSync()) return candidate;
  }
}
