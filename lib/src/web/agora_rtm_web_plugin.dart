@JS()
library callable_function;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('agoraRtmOnEvent')
external set _agoraRtmOnEvent(void Function(dynamic event) f);

@JS()
external dynamic agoraRtmInvokeMethod(
    String method, String call, String? params);

mixin AgoraRtmWebPlugin {
  static final StreamController<Map<String, dynamic>>
      _agoraRtmEventStreamController = StreamController.broadcast();

  static Stream<Map<String, dynamic>> get agoraRtmEventStream =>
      _agoraRtmEventStreamController.stream;

  static void registerWith(Registrar registrar) {
    _agoraRtmOnEvent = allowInterop((dynamic event) {
      _agoraRtmEventStreamController
          .add(jsonDecode(event) as Map<String, dynamic>);
    });
  }

  static Future<Map<String, dynamic>> _sendMethodMessage(
      String call, String method, Map<String, dynamic>? arguments) async {
    final dynamic response = await promiseToFuture(agoraRtmInvokeMethod(
        method, call, arguments != null ? jsonEncode(arguments) : null));
    return jsonDecode(response) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> callMethodForStatic(
      String name, Map<String, dynamic>? arguments) {
    return _sendMethodMessage("static", name, arguments);
  }

  static Future<Map<String, dynamic>> callMethodForClient(
      String name, Map<String, dynamic> arguments) {
    return _sendMethodMessage("AgoraRtmClient", name, arguments);
  }

  static Future<Map<String, dynamic>> callMethodForChannel(
      String name, Map<String, dynamic> arguments) {
    return _sendMethodMessage("AgoraRtmChannel", name, arguments);
  }
}
