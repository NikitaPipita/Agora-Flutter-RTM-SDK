import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class RtmChannelWeb {
  final int clientIndex;
  final String channelId;
  final PluginEventChannel _channel;
  final StreamController _eventChannelController;

  RtmChannelWeb({
    required this.clientIndex,
    required this.channelId,
    required Registrar? registrar,
  })  : _channel = PluginEventChannel(
            'io.agora.rtm.client$clientIndex.channel$channelId',
            const StandardMethodCodec(),
            registrar),
        _eventChannelController = StreamController() {
    _channel.setController(_eventChannelController);
  }

  void sendEvent(dynamic event) {
    _eventChannelController.add(event);
  }

  Future<void> close() async {
    await _eventChannelController.close();
  }
}
