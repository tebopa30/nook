import 'dart:typed_data';
import 'dart:js' as js;

void downloadImageWeb(Uint8List bytes, String fileName) {
  final script = """
    var blob = new Blob([new Uint8Array(${bytes.toList()})], {type: "image/png"});
    var url = window.URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    a.download = '$fileName';
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  """;
  js.context.callMethod('eval', [script]);
}
