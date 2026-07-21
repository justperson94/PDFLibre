import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

/// Lightweight i18n — two-language runtime switch (ko / en).
///
/// Access via `context.s` extension or `S.of(context)`.
class S {
  S(this._lang);

  final AppLanguage _lang;

  bool get _ko => _lang == AppLanguage.ko;

  // ── static helpers ──────────────────────────────────────────

  static S of(BuildContext context) => context.read<SettingsProvider>().s;

  // ── App-wide ────────────────────────────────────────────────

  String get appTagline =>
      _ko ? '빠르고 가벼운 데스크톱 PDF 도구' : 'Fast & lightweight desktop PDF tool';

  // ── Common ──────────────────────────────────────────────────

  String get cancel => _ko ? '취소' : 'Cancel';
  String get close => _ko ? '닫기' : 'Close';
  String get confirm => _ko ? '확인' : 'OK';
  String get save => _ko ? '저장' : 'Save';
  String get delete => _ko ? '삭제' : 'Delete';

  // ── File operations ─────────────────────────────────────────

  String get pickPdfFile => _ko ? 'PDF 파일 선택' : 'Select PDF file';
  String get pickSaveDirectory => _ko ? '저장 위치 선택' : 'Select save location';
  String get saveDialogTitle => _ko ? '저장' : 'Save';
  String get cannotOpenFile => _ko ? '파일을 열 수 없습니다' : 'Cannot open file';
  String get cannotOpenFilePeriod =>
      _ko ? '파일을 열 수 없습니다.' : 'Cannot open file.';
  String get onlyPdfAllowed =>
      _ko ? 'PDF 파일만 열 수 있습니다' : 'Only PDF files can be opened';
  String get pdfAlreadyOpen => _ko
      ? '이미 열린 PDF가 있습니다. 먼저 닫고 다시 시도하세요.'
      : 'A PDF is already open. Close it and try again.';
  String get fileNotFound => _ko ? '파일을 찾을 수 없습니다' : 'File not found';
  String get recentFileRemoved => _ko
      ? '파일을 열 수 없어 최근 목록에서 제거했습니다. 다시 선택해주세요.'
      : 'Could not open file. Removed from recent list. Please select again.';

  String saveFailed(String error) => _ko
      ? '저장 실패: 파일을 쓸 수 없습니다 ($error)'
      : 'Save failed: cannot write file ($error)';
  String get saveComplete => _ko ? 'PDF 저장이 완료되었습니다' : 'PDF saved successfully';

  // ── Empty state ─────────────────────────────────────────────

  String get openPdfButton => _ko ? 'PDF 파일 열기' : 'Open PDF file';
  String get multiFileMergeHint => _ko
      ? '여러 파일을 드래그하면 병합 화면으로 이동합니다'
      : 'Drop multiple files to open the merge screen';
  String get selectFilePrompt => _ko ? '파일을 선택해주세요' : 'Please select a file';
  String get recentFiles => _ko ? '최근 파일' : 'Recent files';

  // ── Feature chips ───────────────────────────────────────────

  String get rotate => _ko ? '회전' : 'Rotate';
  String get split => _ko ? '분할' : 'Split';
  String get merge => _ko ? '병합' : 'Merge';
  String get convert => _ko ? '변환' : 'Convert';

  // ── Empty state drop zone (drag feedback) ───────────────────

  String get dropHere => _ko ? 'PDF 파일을 여기에 놓으세요' : 'Drop PDF files here';
  String get dropDescription =>
      _ko ? 'PDF 파일을 드래그하여 열거나 병합할 수 있습니다' : 'Drag PDF files to open or merge';
  String get supportedFormat => _ko ? '지원 형식: .pdf' : 'Supported format: .pdf';

  // ── Toolbar ─────────────────────────────────────────────────

  String openFileTooltip(String prefix) =>
      _ko ? '다른 파일 열기 ($prefix+O)' : 'Open file ($prefix+O)';
  String get openLabel => _ko ? '열기' : 'Open';
  String get saveAsTooltip => _ko ? '다른 이름으로 저장' : 'Save as';
  String get closeDocTooltip => _ko ? '문서 닫기' : 'Close document';
  String undoTooltip(String prefix) =>
      _ko ? '실행 취소 ($prefix+Z)' : 'Undo ($prefix+Z)';
  String redoTooltip(String prefix) =>
      _ko ? '다시 실행 ($prefix+Shift+Z)' : 'Redo ($prefix+Shift+Z)';
  String get rotateLeft => _ko ? '왼쪽으로 회전' : 'Rotate left';
  String get rotateRight => _ko ? '오른쪽으로 회전' : 'Rotate right';
  String get splitLabel => _ko ? '분할' : 'Split';
  String get mergeLabel => _ko ? '병합' : 'Merge';
  String get convertToImage => _ko ? '이미지로 변환' : 'Convert to image';
  String get convertLabel => _ko ? '변환' : 'Convert';
  String settingsTooltip(String prefix) =>
      _ko ? '설정 ($prefix+,)' : 'Settings ($prefix+,)';
  String get settings => _ko ? '설정' : 'Settings';

  // ── Viewer toolbar ──────────────────────────────────────────

  String get prevPage => _ko ? '이전 페이지' : 'Previous page';
  String get nextPage => _ko ? '다음 페이지' : 'Next page';
  String pageOf(int current, int total) =>
      _ko ? '페이지 $current / $total' : 'Page $current / $total';
  String get fitWidth => _ko ? '가로 맞춤' : 'Fit width';
  String get actualSize => _ko ? '원본 크기 (100%)' : 'Actual size (100%)';
  String get fitHeight => _ko ? '세로 맞춤' : 'Fit height';

  // ── View toggle ─────────────────────────────────────────────

  String get gridView => _ko ? '그리드 보기' : 'Grid view';
  String get listView => _ko ? '리스트 보기' : 'List view';

  // ── Sidebar ─────────────────────────────────────────────────

  String get page => _ko ? '페이지' : 'Page';
  String pageLabel(int n) => _ko ? '$n 페이지' : 'Page $n';

  // ── Status bar ──────────────────────────────────────────────

  String statusInfo(String fileSize, int pageCount) => _ko
      ? '|  $fileSize  |  $pageCount 페이지'
      : '|  $fileSize  |  $pageCount pages';

  // ── Error dialog ────────────────────────────────────────────

  String get errorDialogTitle => _ko ? '파일을 열 수 없습니다' : 'Cannot open file';
  String get errorDialogBody => _ko
      ? 'PDF 파일이 손상되었거나 지원하지 않는 형식입니다.\n다른 파일을 선택해 주세요.'
      : 'The PDF file is corrupted or in an unsupported format.\nPlease select another file.';
  String get pickAnotherFile => _ko ? '다른 파일 선택' : 'Select another file';

  // ── Password dialog ─────────────────────────────────────────

  String get passwordDialogTitle =>
      _ko ? '비밀번호가 필요한 PDF' : 'Password-protected PDF';
  String get passwordDialogSubtitle =>
      _ko ? '이 PDF를 열려면 비밀번호를 입력하세요.' : 'Enter the password to open this PDF.';
  String get passwordWrong =>
      _ko ? '비밀번호가 올바르지 않습니다. 다시 시도하세요.' : 'Incorrect password — please try again.';
  String get passwordLabel => _ko ? '비밀번호' : 'Password';
  String get passwordOpen => _ko ? '열기' : 'Open';
  String get passwordShow => _ko ? '비밀번호 표시' : 'Show password';
  String get passwordHide => _ko ? '비밀번호 숨기기' : 'Hide password';

  // ── Password manage (set / remove) ──────────────────────────

  String get passwordManageTooltip => _ko ? '암호 설정' : 'Password';
  String get passwordSetTitle => _ko ? '비밀번호 설정' : 'Set password';
  String get passwordRemoveTitle => _ko ? '비밀번호 제거' : 'Remove password';
  String get passwordSetSubtitle => _ko
      ? '이 PDF에 새 비밀번호를 설정합니다. 새 파일로 저장됩니다.'
      : 'Set a new password on this PDF. A new file will be saved.';
  String get passwordRemoveSubtitle => _ko
      ? '이 PDF에서 비밀번호를 제거합니다. 새 파일로 저장됩니다.'
      : 'Remove the password from this PDF. A new file will be saved.';
  String get passwordNew => _ko ? '새 비밀번호' : 'New password';
  String get passwordConfirm => _ko ? '비밀번호 확인' : 'Confirm password';
  String get passwordCurrent => _ko ? '현재 비밀번호' : 'Current password';
  String get passwordMismatch =>
      _ko ? '두 비밀번호가 일치하지 않습니다.' : 'The two passwords do not match.';
  String get passwordEmpty =>
      _ko ? '비밀번호를 입력하세요.' : 'Please enter a password.';
  String get passwordApply => _ko ? '적용' : 'Apply';
  String get passwordSaveAs =>
      _ko ? '암호화된 PDF로 저장' : 'Save encrypted PDF as…';
  String get passwordSaveAsRemoved =>
      _ko ? '비밀번호 제거한 PDF로 저장' : 'Save decrypted PDF as…';
  String get passwordSetSuccess =>
      _ko ? '비밀번호가 설정되었습니다.' : 'Password set.';
  String get passwordRemoveSuccess =>
      _ko ? '비밀번호가 제거되었습니다.' : 'Password removed.';
  String get passwordToolUnavailable => _ko
      ? '암호 변경 도구를 찾을 수 없습니다.'
      : 'Password tool unavailable in this build.';
  String get passwordOperationFailed =>
      _ko ? '암호 변경에 실패했습니다.' : 'Password operation failed.';

  // ── Close confirmation ──────────────────────────────────────

  String get closeDocTitle => _ko ? '문서 닫기' : 'Close document';
  String get unsavedChanges => _ko
      ? '저장하지 않은 변경사항이 있습니다.\n그래도 닫으시겠습니까?'
      : 'You have unsaved changes.\nClose anyway?';

  // ── Progress dialog ─────────────────────────────────────────

  String get cancelling => _ko ? '취소 중...' : 'Cancelling...';
  String progressText(int current, int total) =>
      _ko ? '$current / $total 페이지 처리 중' : 'Processing page $current / $total';

  // ── Convert dialog ──────────────────────────────────────────

  String get convertTitle => _ko ? '이미지로 변환' : 'Convert to images';
  String get selectPagesForConvert =>
      _ko ? '변환할 페이지를 선택해주세요' : 'Please select pages to convert';
  String get dpiRangeError =>
      _ko ? 'DPI는 1~2400 사이의 값을 입력해주세요' : 'DPI must be between 1 and 2400';
  String get allPages => _ko ? '전체 페이지' : 'All pages';
  String get currentPage => _ko ? '현재 페이지' : 'Current page';
  String get pageRange => _ko ? '범위 지정' : 'Page range';
  String get pageSelection => _ko ? '페이지 선택' : 'Page selection';
  String totalPages(int count) => _ko ? '총 $count 페이지' : '$count pages total';
  String get rangeHint => _ko ? '예: 1-3, 5, 7-10' : 'e.g. 1-3, 5, 7-10';
  String get outputFormat => _ko ? '출력 포맷' : 'Output format';
  String get customInput => _ko ? '직접 입력' : 'Custom';
  String get resolutionDpi => _ko ? '해상도 (DPI)' : 'Resolution (DPI)';
  String get dpiValue => _ko ? 'DPI 값' : 'DPI value';
  String get quality => _ko ? '품질' : 'Quality';
  String get qualityLow => _ko ? '낮음' : 'Low';
  String get qualityHigh => _ko ? '높음' : 'High';
  String get convertAction => _ko ? '변환하기' : 'Convert';
  String get convertingImages =>
      _ko ? '이미지로 변환 중...' : 'Converting to images...';
  String convertedPages(int count) =>
      _ko ? '$count개 페이지를 이미지로 변환했습니다' : 'Converted $count pages to images';

  // ── Split dialog ────────────────────────────────────────────

  String get splitTitle => _ko ? 'PDF 분할' : 'Split PDF';
  String get selectPagesForSplit =>
      _ko ? '분할할 페이지를 선택해주세요' : 'Please select pages to split';
  String get splitMethod => _ko ? '분할 방식' : 'Split method';
  String get splitSinglePdf =>
      _ko ? '범위를 하나의 PDF로 추출' : 'Extract range as one PDF';
  String get splitSinglePdfDesc => _ko
      ? '선택한 페이지들을 하나의 새 PDF 파일로 만듭니다'
      : 'Creates a single new PDF with the selected pages';
  String get splitPerPage =>
      _ko ? '페이지별로 개별 PDF 생성' : 'Create individual PDFs per page';
  String get splitPerPageDesc => _ko
      ? '각 페이지를 별도의 PDF 파일로 분리합니다'
      : 'Separates each page into its own PDF file';
  String splitDefaultName(String baseName) =>
      _ko ? '${baseName}_분할.pdf' : '${baseName}_split.pdf';
  String splitPerPageName(String baseName) =>
      _ko ? '${baseName}_페이지별.pdf' : '${baseName}_pages.pdf';
  String get outputFile => _ko ? '출력 파일' : 'Output file';
  String get originalUnchanged =>
      _ko ? '원본 파일은 변경되지 않습니다' : 'Original file will not be modified';
  String get splitAction => _ko ? '분할하기' : 'Split';
  String get splittingPdf => _ko ? 'PDF 분할 중...' : 'Splitting PDF...';
  String splitComplete(int count) =>
      _ko ? '$count개 PDF로 분할했습니다' : 'Split into $count PDFs';
  String get splitSingleComplete =>
      _ko ? 'PDF 분할이 완료되었습니다' : 'PDF split complete';

  // ── Merge screen ────────────────────────────────────────────

  String cannotOpenFilePath(String path) =>
      _ko ? '파일을 열 수 없습니다: $path' : 'Cannot open file: $path';
  String get selectPagesForMerge =>
      _ko ? '병합할 페이지를 선택해주세요' : 'Please select pages to merge';
  String get mergePdf => _ko ? 'PDF 병합' : 'Merge PDFs';
  String get mergingPdf => _ko ? 'PDF 병합 중...' : 'Merging PDFs...';
  String mergedPages(int count) =>
      _ko ? '$count개 페이지를 병합했습니다' : 'Merged $count pages';
  String get mergeError =>
      _ko ? '병합 중 오류가 발생했습니다' : 'An error occurred during merge';
  String get dropFilesHere => _ko ? 'PDF 파일을 여기에 놓으세요' : 'Drop PDF files here';
  String get addFilesPrompt =>
      _ko ? '병합할 PDF 파일을 추가해주세요' : 'Add PDF files to merge';
  String get addFilesHint => _ko
      ? '상단의 "파일 추가" 버튼으로 여러 PDF를 선택할 수 있습니다'
      : 'Use the "Add files" button above to select multiple PDFs';
  String get addFiles => _ko ? '파일 추가' : 'Add files';
  String get goBack => _ko ? '돌아가기' : 'Go back';
  String get fileList => _ko ? '파일 목록' : 'File list';
  String fileCount(int count) => _ko ? '$count개 파일' : '$count files';
  String filePageInfo(int pageCount, String size) =>
      _ko ? '$pageCount 페이지 · $size' : '$pageCount pages · $size';
  String get removeFile => _ko ? '파일 제거' : 'Remove file';
  String filePageSelection(String name) =>
      _ko ? '$name — 페이지 선택' : '$name — select pages';
  String get selectAll => _ko ? '전체 선택' : 'Select all';
  String get clearSelection => _ko ? '선택 해제' : 'Clear selection';
  String selectedPages(int selected, int total) => _ko
      ? '선택된 페이지: $selected / $total'
      : 'Selected pages: $selected / $total';
  String get mergeAction => _ko ? '병합하기' : 'Merge';

  // ── Merge mode tabs (파일 순서 / 페이지 혼합) ─────────────────

  String get modeFileOrder => _ko ? '파일 순서' : 'File order';
  String get modePageMix => _ko ? '페이지 혼합' : 'Page mix';

  // ── Page mix: source tray ──────────────────────────────────

  String get rangeInputHint =>
      _ko ? '예: 1-3, 5, 7-10' : 'e.g. 1-3, 5, 7-10';
  String get addAll => _ko ? '전체 추가' : 'Add all';
  String get addSelection => _ko ? '선택 추가' : 'Add selection';
  String get addRange => _ko ? '범위 추가' : 'Add range';
  String selectedCount(int count) =>
      _ko ? '$count 선택' : '$count selected';
  String pageMeta(int pageCount, String size) =>
      _ko ? '$pageCount 페이지 · $size' : '$pageCount pages · $size';
  String get collapseTray => _ko ? '접기' : 'Collapse';
  String get expandTray => _ko ? '펼치기' : 'Expand';
  String get removeSource => _ko ? '소스 제거' : 'Remove source';
  String get invalidRange => _ko ? '범위 형식이 올바르지 않습니다' : 'Invalid range format';

  // ── Page mix: output canvas ────────────────────────────────

  String get outputEmptyTitle =>
      _ko ? '출력 페이지가 비어 있습니다' : 'Output is empty';
  String get outputEmptyHint => _ko
      ? '위 트레이에서 페이지를 선택해 추가하거나, 드래그해 이곳에 놓으세요'
      : 'Select pages in the tray above and add them, or drag them here';
  String outputPageCount(int count) =>
      _ko ? '출력 페이지: $count개' : 'Output pages: $count';
  String outputPageAndSourceCount(int pages, int sources) => _ko
      ? '출력 페이지: $pages개 · 소스 $sources개'
      : 'Output pages: $pages · Sources: $sources';
  String get clearOutput => _ko ? '출력 비우기' : 'Clear output';
  String pageLabelShort(String name, int page) =>
      _ko ? '$name · p.$page' : '$name · p.$page';
  String pageLabelRotated(String name, int page, int degrees) => _ko
      ? '$name · p.$page · $degrees°'
      : '$name · p.$page · $degrees°';
  String get rotateCounterClockwise =>
      _ko ? '반시계방향 회전' : 'Rotate counterclockwise';
  String get rotateClockwise => _ko ? '시계방향 회전' : 'Rotate clockwise';
  String get removeOutputPage => _ko ? '출력에서 제거' : 'Remove from output';

  // ── Edit commands ───────────────────────────────────────────

  String rotateCommand(int page, bool clockwise) => _ko
      ? '$page페이지 ${clockwise ? "시계방향" : "반시계방향"} 회전'
      : 'Rotate page $page ${clockwise ? "clockwise" : "counterclockwise"}';
  String reorderCommand(int from, int to) =>
      _ko ? '$from페이지 → $to번째로 이동' : 'Move page $from → position $to';

  // ── Settings dialog ─────────────────────────────────────────

  String get settingsTitle => _ko ? '설정' : 'Settings';
  String get tabGeneral => _ko ? '일반' : 'General';
  String get tabDefaults => _ko ? '출력 설정' : 'Output';
  String get tabAbout => _ko ? '정보' : 'About';

  // Settings > General
  String get theme => _ko ? '테마' : 'Theme';
  String get themeDescription =>
      _ko ? '앱의 전반적인 색상 모드를 선택하세요' : 'Choose the color mode for the app';
  String get themeSystem => _ko ? '시스템 설정 따르기' : 'Follow system';
  String get themeLight => _ko ? '라이트' : 'Light';
  String get themeDark => _ko ? '다크' : 'Dark';
  String get darkModePhase4 =>
      _ko ? '다크 모드는 Phase 4에서 제공됩니다' : 'Dark mode coming in Phase 4';
  String get language => _ko ? '언어' : 'Language';
  String get languageDescription =>
      _ko ? '앱에서 사용할 언어를 선택하세요' : 'Choose the app language';

  // Settings > Defaults
  String get saveLocation => _ko ? '저장 위치' : 'Save location';
  String get saveLocationDesc => _ko
      ? '저장 다이얼로그에서 처음 열리는 폴더를 지정합니다'
      : 'Set the default folder for the save dialog';
  String get askEveryTime => _ko ? '매번 묻기 (현재 동작)' : 'Ask every time (current)';
  String get useFixedFolder => _ko ? '지정한 폴더 사용' : 'Use fixed folder';
  String get pickFolder => _ko ? '폴더 선택' : 'Select folder';
  String get filenameRules => _ko ? '파일명 규칙' : 'Filename rules';
  String get filenameRulesDesc => _ko
      ? '각 작업에서 생성되는 기본 파일명 규칙. 토큰: {원본} {페이지} {날짜}'
      : 'Default filename rules per operation. Tokens: {원본} {페이지} {날짜}';
  String get ruleSave => _ko ? '저장' : 'Save';
  String get ruleSplit => _ko ? '분할' : 'Split';
  String get ruleConvert => _ko ? '이미지 변환' : 'Image convert';
  String get ruleMissingPageToken => _ko
      ? '{페이지} 토큰이 없어 파일명이 겹칠 수 있습니다. 겹치는 파일에는 번호가 자동으로 붙습니다.'
      : 'No {페이지} token — names may collide; duplicates get a number suffix.';
  String get resetDefaults => _ko ? '기본값으로 초기화' : 'Reset to defaults';
  String get resetDefaultsDone => _ko ? '출력 설정이 초기화되었습니다' : 'Output settings reset';

  // Settings > About
  String get version => _ko ? '버전' : 'Version';
  String get platform => _ko ? '플랫폼' : 'Platform';
  String get githubCopied =>
      _ko ? 'GitHub 주소를 클립보드에 복사했습니다' : 'GitHub URL copied to clipboard';
  String get openSourceLicenses => _ko ? '오픈소스 라이선스' : 'Open-source licenses';
  String get viewLicenses => _ko ? '라이선스 보기' : 'View licenses';
}

/// Shortcut extension for widget trees.
extension StringsContext on BuildContext {
  S get s => watch<SettingsProvider>().s;
  S get sRead => read<SettingsProvider>().s;
}
