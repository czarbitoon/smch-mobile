// Flutter web plugin registrant file.

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter_secure_storage_web/flutter_secure_storage_web.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  // Ensure that web plugins are initialized first
  usePathUrlStrategy();
  // Then register the plugins
  FlutterSecureStorageWeb.registerWith(registrar);
  SharedPreferencesPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}