import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'rtm_channel_web.dart';

class RtmClientWeb {
  final int clientIndex;
  final PluginEventChannel _channel;
  final StreamController _eventChannelController;
  final Map<String, RtmChannelWeb> rtmChannels;

  RtmClientWeb({
    required this.clientIndex,
    required Registrar? registrar,
  })  : _channel = PluginEventChannel('io.agora.rtm.client$clientIndex',
            const StandardMethodCodec(), registrar),
        _eventChannelController = StreamController(),
        rtmChannels = {} {
    _channel.setController(_eventChannelController);
  }

  void sendEvent(dynamic event) {
    _eventChannelController.add(event);
  }

  Future<void> close() async {
    await Future.wait([
      _eventChannelController.close(),
      for (final e in rtmChannels.entries) e.value.close(),
    ]);
  }
}
