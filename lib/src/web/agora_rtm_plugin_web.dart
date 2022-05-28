@JS()
library callable_function;

import 'dart:async';
import 'dart:convert';

import 'package:agora_rtm/src/web/rtm_channel_web.dart';
import 'package:agora_rtm/src/web/rtm_client_web.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('agoraRtmOnClientEvent')
external set _agoraRtmOnClientEvent(void Function(dynamic event) f);

@JS('agoraRtmOnChannelEvent')
external set _agoraRtmOnChannelEvent(void Function(dynamic event) f);

@JS()
external dynamic agoraRtmInvokeStaticMethod(
    String method, String? callArguments);

@JS()
external dynamic agoraRtmInvokeClientMethod(
    String method, String? callArguments);

@JS()
external dynamic agoraRtmInvokeChannelMethod(
    String method, String? callArguments);

class AgoraRtmPluginWeb {
  static Registrar? _registrar;

  var clients = Map<int, RtmClientWeb>();

  static void registerWith(Registrar registrar) {
    _registrar = registrar;

    final MethodChannel channel = MethodChannel(
      'io.agora.rtm',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = AgoraRtmPluginWeb();
    channel.setMethodCallHandler(pluginInstance._handleMethodCall);

    _agoraRtmOnClientEvent =
        allowInterop(pluginInstance._onAgoraRtmJsClientEvent);
    _agoraRtmOnChannelEvent =
        allowInterop(pluginInstance._onAgoraRtmJsChannelEvent);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    String? callType;
    if (call.arguments is Map) {
      callType = call.arguments['call'];
    }
    switch (callType) {
      case 'static':
        return _handleStaticMethod(call);
      case 'AgoraRtmClient':
        return _handleClientMethod(call);
      case 'AgoraRtmChannel':
        return _handleChannelMethod(call);
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              'agora_rtm for web doesn\'t implement call type \'$callType\'',
        );
    }
  }

  Future<dynamic> _sendStaticMethodMessage(
      String method, dynamic arguments) async {
    final dynamic response = await promiseToFuture(agoraRtmInvokeStaticMethod(
        method, arguments != null ? jsonEncode(arguments) : null));
    return jsonDecode(response);
  }

  Future<dynamic> _handleStaticMethod(MethodCall call) async {
    switch (call.method) {
      case 'createInstance':
        final res = await _sendStaticMethodMessage(call.method, call.arguments);
        final clientIndex = res['index'];
        if (res['errorCode'] == 0 &&
            clientIndex != null &&
            clientIndex is int) {
          clients[clientIndex] =
              RtmClientWeb(clientIndex: clientIndex, registrar: _registrar);
        }
        return res;
      default:
        return _sendStaticMethodMessage(call.method, call.arguments);
    }
  }

  Future<dynamic> _sendClientMethodMessage(
      String method, dynamic arguments) async {
    final dynamic response = await promiseToFuture(agoraRtmInvokeClientMethod(
        method, arguments != null ? jsonEncode(arguments) : null));
    return jsonDecode(response);
  }

  Future<dynamic> _handleClientMethod(MethodCall call) async {
    switch (call.method) {
      case 'destroy':
        final res = await _sendClientMethodMessage(call.method, call.arguments);
        final params = call.arguments['params'];

        final clientIndex = params['clientIndex'];

        if (res['errorCode'] == 0 &&
            clientIndex != null &&
            clientIndex is int) {
          final client = clients[clientIndex];
          await client?.close();
          clients.remove(clientIndex);
        }

        return res;
      case 'createChannel':
        final res = await _sendClientMethodMessage(call.method, call.arguments);

        final params = call.arguments['params'];
        final args = params['args'];

        final clientIndex = params['clientIndex'];
        final channelId = args['channelId'];

        if (res['errorCode'] == 0 &&
            clientIndex != null &&
            clientIndex is int &&
            channelId != null &&
            channelId is String) {
          clients[clientIndex]?.rtmChannels[channelId] = RtmChannelWeb(
            clientIndex: clientIndex,
            channelId: channelId,
            registrar: _registrar,
          );
        }
        return res;
      case 'releaseChannel':
        final res = await _sendClientMethodMessage(call.method, call.arguments);

        final params = call.arguments['params'];
        final args = params['args'];

        final clientIndex = params['clientIndex'];
        final channelId = args['channelId'];

        if (res['errorCode'] == 0 &&
            clientIndex != null &&
            clientIndex is int &&
            channelId != null &&
            channelId is String) {
          final client = clients[clientIndex];
          await client?.rtmChannels[channelId]?.close();
          client?.rtmChannels.remove(channelId);
        }

        return res;
      default:
        return _sendClientMethodMessage(call.method, call.arguments);
    }
  }

  Future<dynamic> _sendChannelMethodMessage(
      String method, dynamic arguments) async {
    final dynamic response = await promiseToFuture(agoraRtmInvokeChannelMethod(
        method, arguments != null ? jsonEncode(arguments) : null));
    return jsonDecode(response);
  }

  Future<dynamic> _handleChannelMethod(MethodCall call) async {
    switch (call.method) {
      default:
        return _sendChannelMethodMessage(call.method, call.arguments);
    }
  }

  Future<void> _onAgoraRtmJsClientEvent(dynamic event) async {
    final eventDecode = jsonDecode(event);
    final client = clients[eventDecode['clientIndex']];
    client?.sendEvent(eventDecode);
  }

  Future<void> _onAgoraRtmJsChannelEvent(dynamic event) async {
    final eventDecode = jsonDecode(event);
    final client = clients[eventDecode['clientIndex']];
    final channel = client?.rtmChannels[eventDecode['channelId']];
    channel?.sendEvent(eventDecode);
  }
}
