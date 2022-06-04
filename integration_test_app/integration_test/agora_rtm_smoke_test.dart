import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:integration_test_app/main.dart' as app;

import 'utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Client smoke tests', () {
    testWidgets('Create client', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final client = await createClient();

      expect(client.runtimeType, AgoraRtmClient);
    });

    testWidgets('User login', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final client = await createClient();

      final loginResult = await client.login(null, 'test-1');

      expect(loginResult, null);
    });

    testWidgets('User logout', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final client = await createClient();
      await client.login(null, 'test-1');

      final logoutResult = await client.logout();

      expect(logoutResult, null);
    });

    testWidgets('Client destroy', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final client = await createClient();
      await client.login(null, 'test-1');

      await client.destroy();
    });

    testWidgets('Query peers online', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final mainClient = await createClient();
      await mainClient.login(null, 'test-1');

      final test2Client = await createClient();
      await test2Client.login(null, 'test-2');

      final queryPeersResult =
          await mainClient.queryPeersOnlineStatus(['test-2', 'test-3']);

      expect(queryPeersResult, {'test-2': true, 'test-3': false});
    });

    testWidgets('Send query message', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final mainClient = await createClient();
      await mainClient.login(null, 'test-1');

      final test2Client = await createClient();
      await test2Client.login(null, 'test-2');

      await mainClient.sendMessageToPeer(
          'test-2', AgoraRtmMessage.fromText('Test message'));
    });

    testWidgets('Create channel', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final client = await createClient();
      await client.login(null, 'test-1');

      final channel = await client.createChannel('test-channel-1');

      expect(channel.runtimeType, AgoraRtmChannel);
    });

    testWidgets('Release channel', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final client = await createClient();
      await client.login(null, 'test-1');
      await client.createChannel('test-channel-1');

      await client.releaseChannel('test-channel-1');
    });

    testWidgets('Receive message', (tester) async {
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
    });
  });

  group('Channel smoke tests', () {
    testWidgets('Channel join', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final client = await createClient();
      await client.login(null, 'test-1');

      final channel = await client.createChannel('test-channel-1');

      await channel!.join();
    });

    testWidgets('Left channel', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final client = await createClient();
      await client.login(null, 'test-1');

      final channel = await client.createChannel('test-channel-1');
      await channel!.join();

      await channel.leave();
    });

    testWidgets('Send channel message', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final client = await createClient();
      await client.login(null, 'test-1');

      final channel = await client.createChannel('test-channel-1');
      await channel!.join();

      await channel
          .sendMessage(AgoraRtmMessage.fromText('Test channel message'));
    });

    testWidgets('Get channel members', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final mainClient = await createClient();
      await mainClient.login(null, 'test-1');
      final mainChannel = await mainClient.createChannel('test-channel-1');
      await mainChannel!.join();

      final test2Client = await createClient();
      await test2Client.login(null, 'test-2');
      final test2Channel = await test2Client.createChannel('test-channel-1');
      await test2Channel!.join();

      final channelMembers = await mainChannel.getMembers();

      expect(
        [for (final member in channelMembers) member.userId]..sort(),
        ['test-1', 'test-2']..sort(),
      );
    });

    testWidgets('Receive channel message', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final mainClient = await createClient();
      await mainClient.login(null, 'test-1');
      final mainChannel = await mainClient.createChannel('test-channel-1');
      await mainChannel!.join();

      String? receivedMessage;

      mainChannel.onMessageReceived =
          (AgoraRtmMessage message, AgoraRtmMember member) {
        receivedMessage =
            '{uid: ${member.userId}, cid: ${member.channelId}, text: ${message.text}}';
      };

      final test2Client = await createClient();
      await test2Client.login(null, 'test-2');
      final test2Channel = await test2Client.createChannel('test-channel-1');
      await test2Channel!.join();

      await test2Channel
          .sendMessage(AgoraRtmMessage.fromText('Test channel message'));

      await Future.delayed(const Duration(seconds: 2));

      expect(
        receivedMessage,
        '{uid: test-2, cid: test-channel-1, text: Test channel message}',
      );
    });

    testWidgets('Receive channel members changing', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final mainClient = await createClient();
      await mainClient.login(null, 'test-1');
      final mainChannel = await mainClient.createChannel('test-channel-1');
      await mainChannel!.join();

      int? memberCount;

      mainChannel.onMemberCountUpdated = (int count) {
        memberCount = count;
      };

      String? joinedMemberInfo;

      mainChannel.onMemberJoined = (AgoraRtmMember member) {
        joinedMemberInfo = '{uid: ${member.userId}, cid: ${member.channelId}}';
      };

      String? leftMemberInfo;

      mainChannel.onMemberLeft = (AgoraRtmMember member) {
        leftMemberInfo = '{uid: ${member.userId}, cid: ${member.channelId}}';
      };

      final test2Client = await createClient();
      await test2Client.login(null, 'test-2');
      final test2Channel = await test2Client.createChannel('test-channel-1');
      await test2Channel!.join();

      final test3Client = await createClient();
      await test3Client.login(null, 'test-3');
      final test3Channel = await test3Client.createChannel('test-channel-1');
      await test3Channel!.join();

      await test2Channel.leave();

      await Future.delayed(const Duration(seconds: 3));

      expect(memberCount, 2);

      expect(joinedMemberInfo, '{uid: test-3, cid: test-channel-1}');

      expect(leftMemberInfo, '{uid: test-2, cid: test-channel-1}');
    });
  });
}
