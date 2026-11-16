import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAudioPlatform {
  FakeAudioPlatform._(this._messenger, this._cache);

  static const MethodCodec _codec = StandardMethodCodec();
  static const String _audio = 'xyz.luan/audioplayers';
  static const String _paths = 'plugins.flutter.io/path_provider';

  final TestDefaultBinaryMessenger _messenger;
  final Directory _cache;
  final List<String> calls = [];

  static FakeAudioPlatform install() {
    final platform = FakeAudioPlatform._(
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger,
      Directory.systemTemp.createTempSync('vamoose_audio'),
    );
    platform._messenger.allMessagesHandler = platform._handle;
    addTearDown(platform._uninstall);
    return platform;
  }

  int count(String method) => calls.where((call) => call == method).length;

  void _uninstall() {
    _messenger.allMessagesHandler = null;
    _cache.deleteSync(recursive: true);
  }

  Future<ByteData?>? _handle(
    String channel,
    MessageHandler? handler,
    ByteData? message,
  ) {
    if (channel == _paths) {
      return Future.value(_codec.encodeSuccessEnvelope(_cache.path));
    }
    if (!channel.startsWith(_audio)) {
      return handler == null
          ? _messenger.delegate.send(channel, message)
          : handler(message);
    }
    final call = _codec.decodeMethodCall(message);
    calls.add(call.method);
    if (call.method.startsWith('setSource')) {
      _prepare(
        (call.arguments as Map<Object?, Object?>)['playerId']! as String,
      );
    }
    return Future.value(_codec.encodeSuccessEnvelope(null));
  }

  void _prepare(String playerId) {
    _messenger.handlePlatformMessage(
      '$_audio/events/$playerId',
      _codec.encodeSuccessEnvelope({
        'event': 'audio.onPrepared',
        'value': true,
      }),
      (_) {},
    );
  }
}
