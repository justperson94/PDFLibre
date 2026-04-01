/// PDF 파일 정보 모델
class PdfFileInfo {
  final String filePath;
  final String fileName;
  final String fileSize;
  final int pageCount;

  const PdfFileInfo({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
  });
}
