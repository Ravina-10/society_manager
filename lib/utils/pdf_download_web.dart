import 'dart:html' as html;
import 'dart:typed_data';

class WebDownloader {
  static void downloadBytes(Uint8List bytes, String filename, String mimeType) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  static void pickFileWeb(Function(String dataUrl, String filename) onSelected) {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*,application/pdf';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        reader.readAsDataUrl(file);
        reader.onLoadEnd.listen((e) {
          final String? result = reader.result as String?;
          if (result != null) {
            onSelected(result, file.name);
          }
        });
      }
    });
  }
}
