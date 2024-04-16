import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Config {
  const Config({
    required this.remoteTerms,
    required this.remotePrivacy,
    required this.prefsTerms,
    required this.prefsPrivacy,
    required this.needUpdate,
    required this.mentenance,
  });

  final int remoteTerms;
  final int remotePrivacy;
  final bool needUpdate;
  final bool mentenance;
  final int? prefsTerms;
  final int? prefsPrivacy;

  static FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
  static SharedPreferences? prefs;

  static Config def = const Config(
    remoteTerms: 1,
    remotePrivacy: 1,
    needUpdate: false,
    mentenance: false,
    prefsTerms: 1,
    prefsPrivacy: 1,
  );

  static Future<Config> init() async {
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await remoteConfig.setDefaults({
      'terms_version': def.remoteTerms,
      'privacy_version': def.remotePrivacy,
      'need_update': def.needUpdate,
      'mentenance': def.mentenance,
    });
    await remoteConfig.fetchAndActivate();

    prefs = await SharedPreferences.getInstance();

    return Config(
      remoteTerms: remoteConfig.getInt('terms_version'),
      remotePrivacy: remoteConfig.getInt('privacy_version'),
      needUpdate: remoteConfig.getBool('need_update'),
      mentenance: remoteConfig.getBool('mentenance'),
      prefsTerms: prefs?.getInt('terms_version'),
      prefsPrivacy: prefs?.getInt('privacy_version'),
    );
  }

  bool get isMentenace => mentenance;

  bool get isNeedUpdate => needUpdate;

  bool get isFirst => prefsTerms == null || prefsPrivacy == null;

  bool get isTermUpdated => remoteTerms != prefsTerms;
  bool get isPrivacyUpdated => remotePrivacy != prefsPrivacy;
}
