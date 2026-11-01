import 'package:flutter/services.dart';

const _channel = MethodChannel('zpay/app');

Future<void> finishTask() => _channel.invokeMethod('finishTask');

Future<void> setLauncherAlias(String alias) => _channel.invokeMethod('setLauncherAlias', alias);
