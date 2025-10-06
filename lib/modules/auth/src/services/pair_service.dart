// lib/core/services/pusher_service.dart
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherService {
  static final PusherChannelsFlutter _pusher =
      PusherChannelsFlutter.getInstance();
  static bool _isInitialized = false;
  static bool _isConnected = false;

  // Ganti dengan kredensial Pusher Anda
  static const String _appKey = 'a15743bef505b8594201';
  static const String _cluster = 'ap1';

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🚀 Initializing Pusher with key: $_appKey, cluster: $_cluster');

      await _pusher.init(
        apiKey: _appKey,
        cluster: _cluster,
        useTLS: true,
        onConnectionStateChange: _onConnectionStateChange,
        onError: _onError,
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onEvent: _onEvent,
        onSubscriptionError: _onSubscriptionError,
        onDecryptionFailure: _onDecryptionFailure,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
      );

      await _pusher.connect();
      _isInitialized = true;
      print('✅ Pusher initialized successfully');
    } catch (e) {
      print('❌ Pusher initialization error: $e');
      _isInitialized = false;
    }
  }

  static void _onConnectionStateChange(
    dynamic currentState,
    dynamic previousState,
  ) {
    print('🔄 Pusher Connection State: $currentState');
    _isConnected = currentState == 'connected';
  }

  static void _onError(String message, int? code, dynamic e) {
    print('❌ Pusher Error: $message, code: $code, exception: $e');
  }

  static void _onSubscriptionSucceeded(String channelName, dynamic data) {
    print('📡 Subscribed to channel: $channelName');
  }

  static void _onEvent(PusherEvent event) {
    print(
      '🎯 Pusher Event - Channel: ${event.channelName}, Event: ${event.eventName}, Data: ${event.data}',
    );
  }

  static void _onSubscriptionError(String message, dynamic e) {
    print('❌ Subscription Error: $message, exception: $e');
  }

  static void _onDecryptionFailure(String event, String reason) {
    print('❌ Decryption Failure: $event, reason: $reason');
  }

  static void _onMemberAdded(String channelName, dynamic member) {
    print('👤 Member added to $channelName: $member');
  }

  static void _onMemberRemoved(String channelName, dynamic member) {
    print('👤 Member removed from $channelName: $member');
  }

  static Future<void> subscribeToFamilyChannel(
    String familyCode,
    Function(PusherEvent) onDevicePaired,
  ) async {
    try {
      if (!_isInitialized || !_isConnected) {
        print('🔄 Pusher not connected, reinitializing...');
        await initialize();
        await Future.delayed(const Duration(seconds: 2));
      }

      final channelName = 'family.$familyCode';
      print('🎯 Attempting to subscribe to channel: $channelName');

      // Unsubscribe dulu jika sudah subscribe sebelumnya
      try {
        await _pusher.unsubscribe(channelName: channelName);
        print('✅ Unsubscribed from previous channel: $channelName');
      } catch (e) {
        print('ℹ️ No previous subscription to unsubscribe from');
      }

      // Subscribe ke channel baru
      await _pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          print(
            '🎯 Event received - Channel: ${event.channelName}, Event: ${event.eventName}',
          );

          if (event.eventName == 'device.paired') {
            print('🎯 Device paired event detected!');
            onDevicePaired(event);
          }
        },
      );

      print('✅ Successfully subscribed to channel: $channelName');
    } catch (e) {
      print('❌ Error subscribing to channel: $e');
      rethrow;
    }
  }

  static Future<void> unsubscribeFromFamilyChannel(String familyCode) async {
    try {
      await _pusher.unsubscribe(channelName: 'family.$familyCode');
      print('✅ Unsubscribed from channel: family.$familyCode');
    } catch (e) {
      print('❌ Error unsubscribing from channel: $e');
    }
  }

  static Future<void> disconnect() async {
    try {
      await _pusher.disconnect();
      _isInitialized = false;
      _isConnected = false;
      print('✅ Pusher disconnected');
    } catch (e) {
      print('❌ Error disconnecting Pusher: $e');
    }
  }

  static bool get isConnected => _isConnected;
  static bool get isInitialized => _isInitialized;
}
