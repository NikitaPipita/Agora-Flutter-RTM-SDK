import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:integration_test_app/main.dart' as app;

import 'utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Main Agora RTM tests', () {
    testWidgets('Receiving messages from multiple clients', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final test1Client = await createClient();
      await test1Client.login(null, 'test-1');

      Map<String, String>? receivedTest1Message;
      test1Client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
        receivedTest1Message = {peerId: message.text};
      };

      final test2Client = await createClient();
      await test2Client.login(null, 'test-2');

      Map<String, String>? receivedTest2Message;
      test2Client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
        receivedTest2Message = {peerId: message.text};
      };

      final test3Client = await createClient();
      await test3Client.login(null, 'test-3');

      await test3Client.sendMessageToPeer(
          'test-1', AgoraRtmMessage.fromText('Test message from test-3'));
      await test3Client.sendMessageToPeer(
          'test-2', AgoraRtmMessage.fromText('Test message from test-3'));

      await Future.delayed(const Duration(seconds: 2));

      expect(receivedTest1Message, {'test-3': 'Test message from test-3'});
      expect(receivedTest2Message, {'test-3': 'Test message from test-3'});
    });

    testWidgets('Stop receiving messages after logout', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final mainClient = await createClient();
      await mainClient.login(null, 'test-1');

      Map<String, String>? receivedMessage;
      mainClient.onMessageReceived = (AgoraRtmMessage message, String peerId) {
        receivedMessage = {peerId: message.text};
      };

      final test2Client = await createClient();
      await test2Client.login(null, 'test-2');

      await test2Client.sendMessageToPeer(
          'test-1', AgoraRtmMessage.fromText('Test message from test-2'));

      await Future.delayed(const Duration(seconds: 2));

      expect(receivedMessage, {'test-2': 'Test message from test-2'});

      receivedMessage = null;
      await mainClient.logout();

      if (kIsWeb) {
        await test2Client.sendMessageToPeer(
            'test-1', AgoraRtmMessage.fromText('Test message from test-2'));
      } else {
        try {
          await test2Client.sendMessageToPeer(
              'test-1', AgoraRtmMessage.fromText('Test message from test-2'));
        } on AgoraRtmClientException catch (e) {
          if (e.code != 3) {
            rethrow;
          }
        } catch (e) {
          rethrow;
        }
      }

      await Future.delayed(const Duration(seconds: 2));

      expect(receivedMessage, null);
    });

    testWidgets('Receiving messages from multiple channels', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final mainClient = await createClient();
      await mainClient.login(null, 'test-1');

      final mainClientChannel1 =
          await mainClient.createChannel('test-channel-1');
      await mainClientChannel1!.join();

      String? receivedMessageFromChannel1;
      mainClientChannel1.onMessageReceived =
          (AgoraRtmMessage message, AgoraRtmMember member) {
        receivedMessageFromChannel1 =
            '{uid: ${member.userId}, cid: ${member.channelId}, text: ${message.text}}';
      };

      final mainClientChannel2 =
          await mainClient.createChannel('test-channel-2');
      await mainClientChannel2!.join();

      String? receivedMessageFromChannel2;
      mainClientChannel2.onMessageReceived =
          (AgoraRtmMessage message, AgoraRtmMember member) {
        receivedMessageFromChannel2 =
            '{uid: ${member.userId}, cid: ${member.channelId}, text: ${message.text}}';
      };

      final test2Client = await createClient();
      await test2Client.login(null, 'test-2');

      final test2ClientChannel1 =
          await test2Client.createChannel('test-channel-1');
      await test2ClientChannel1!.join();
      final test2ClientChannel2 =
          await test2Client.createChannel('test-channel-2');
      await test2ClientChannel2!.join();

      await test2ClientChannel1
          .sendMessage(AgoraRtmMessage.fromText('Test channel message'));

      await test2ClientChannel2
          .sendMessage(AgoraRtmMessage.fromText('Test channel message'));

      await Future.delayed(const Duration(seconds: 2));

      expect(
        receivedMessageFromChannel1,
        '{uid: test-2, cid: test-channel-1, text: Test channel message}',
      );
      expect(
        receivedMessageFromChannel2,
        '{uid: test-2, cid: test-channel-2, text: Test channel message}',
      );
    });

    testWidgets('Stop receiving messages from channel after leaving',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final mainClient = await createClient();
      await mainClient.login(null, 'test-1');

      final mainClientChannel =
          await mainClient.createChannel('test-channel-1');
      await mainClientChannel!.join();

      String? receivedMessage;
      mainClientChannel.onMessageReceived =
          (AgoraRtmMessage message, AgoraRtmMember member) {
        receivedMessage =
            '{uid: ${member.userId}, cid: ${member.channelId}, text: ${message.text}}';
      };

      final test2Client = await createClient();
      await test2Client.login(null, 'test-2');

      final test2ClientChannel =
          await test2Client.createChannel('test-channel-1');
      await test2ClientChannel!.join();

      await test2ClientChannel
          .sendMessage(AgoraRtmMessage.fromText('Test channel message'));

      await Future.delayed(const Duration(seconds: 2));

      expect(
        receivedMessage,
        '{uid: test-2, cid: test-channel-1, text: Test channel message}',
      );

      receivedMessage = null;
      await mainClientChannel.leave();

      await test2ClientChannel
          .sendMessage(AgoraRtmMessage.fromText('Test channel message'));

      await Future.delayed(const Duration(seconds: 2));

      expect(receivedMessage, null);
    });
  });
}
