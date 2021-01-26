import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

Future<HttpClientResponse> postData(
  HttpClient httpClient,
  String url,
  List<Cookie> cookies,
  Map<String, String> headers,
  List<int> data,
) async {
  Uri uri = Uri.parse(url);

  HttpClientRequest req = await httpClient.postUrl(uri);

  if (cookies != null) {
    req.cookies.addAll(cookies);
  }

  if (headers != null) {
    headers.forEach((String key, String value) {
      req.headers.set(key, value, preserveHeaderCase: true);
    });
  }

  if (data != null) {
    req.add(data);
  }

  return await req.close();
}

Future<HttpClientResponse> postString(
  HttpClient httpClient,
  String url,
  List<Cookie> cookies,
  Map<String, String> headers,
  String str,
) async {
  List<int> strData;

  if (str != null) {
    if (headers == null) {
      headers = Map<String, String>();
    }
    if (!headers.containsKey('content-type')) {
      headers['content-type'] = 'text/plain';
    }
    strData = utf8.encode(str);
  }

  return await postData(
    httpClient,
    url,
    cookies,
    headers,
    strData,
  );
}

Future<HttpClientResponse> postJson(
  HttpClient httpClient,
  String url,
  List<Cookie> cookies,
  Map<String, String> headers,
  Map<String, dynamic> jsonObj,
) async {
  String jsonStr;

  if (jsonObj != null) {
    if (headers == null) {
      headers = Map<String, String>();
    }
    if (!headers.containsKey('content-type')) {
      headers['content-type'] = 'application/json';
    }
    jsonStr = json.encode(jsonObj);
  }

  return await postString(
    httpClient,
    url,
    cookies,
    headers,
    jsonStr,
  );
}

Future<Uint8List> readResponse(HttpClientResponse response) {
  final completer = Completer<Uint8List>();
  Uint8List contents = Uint8List(0);

  response.listen((data) {
    contents = Uint8List.fromList(contents + data);
  }, onDone: () {
    return completer.complete(contents);
  });

  return completer.future;
}

Future<String> readString(HttpClientResponse response) async {
  return utf8.decode(await readResponse(response));
}

Future<Map<String, dynamic>> readJson(HttpClientResponse response) async {
  return json.decode(await readString(response));
}
