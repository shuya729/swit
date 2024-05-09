import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swit/firebase_options.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'models/config.dart';
import 'models/layout.dart';
import 'models/presence.dart';
import 'pages/home_page.dart';
import 'pages/layout_page.dart';
import 'pages/logs_page.dart';
import 'pages/setting_pages/terms_page.dart';
import 'providers/layout_providers.dart';
import 'widgets/setting_page_temp.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await WakelockPlus.enable();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
    appleProvider:
        kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
  );
  await MobileAds.instance.initialize();
  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  Future<Config> _futureConfig() async {
    final Config config = await Config.init();
    FlutterNativeSplash.remove();
    return config;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = Layout.def;
    return MaterialApp(
      // debugShowCheckedModeBanner: false, // サンプル用
      home: FutureBuilder(
        future: _futureConfig(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final Config config = snapshot.data as Config;
            if (config.isMentenace) {
              return Scaffold(
                resizeToAvoidBottomInset: true,
                backgroundColor: layout.mainBack,
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'ただいまメンテナンス中です',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: layout.mainText,
                            ),
                          ),
                          const SizedBox(height: 50),
                          Text(
                            '申し訳ございません。',
                            style: TextStyle(
                              fontSize: 16,
                              color: layout.mainText,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'メンテナンス終了まで、しばらくお待ちください。',
                            style: TextStyle(
                              fontSize: 16,
                              color: layout.mainText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else if (config.isNeedUpdate) {
              return Scaffold(
                resizeToAvoidBottomInset: true,
                backgroundColor: layout.mainBack,
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'アップデートが必要です',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: layout.mainText,
                            ),
                          ),
                          const SizedBox(height: 50),
                          Text(
                            'このアプリを利用するには、アップデートが必要です。',
                            style: TextStyle(
                              fontSize: 16,
                              color: layout.mainText,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'アプリストアで最新版にアップデートしてから再度起動してください。',
                            style: TextStyle(
                              fontSize: 16,
                              color: layout.mainText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else if (config.isFirst ||
                config.isTermUpdated ||
                config.isPrivacyUpdated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => TermsDialog(config),
                );
              });
            }
            return const Main();
          } else {
            return Scaffold(
              resizeToAvoidBottomInset: true,
              backgroundColor: layout.mainBack,
            );
          }
        },
      ),
    );
  }
}

class Main extends ConsumerStatefulWidget {
  const Main({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainState();
}

class _MainState extends ConsumerState<Main> with WidgetsBindingObserver {
  final Presence _presence = Presence.instance;
  late final PageController _pageController;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    _pageController.addListener(() {
      final double width = MediaQuery.of(context).size.width;
      setState(() {
        _opacity = 1 -
            ((_pageController.offset - width) * 2 / width).abs().clamp(0, 1);
      });
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _presence.resumed();
    } else if (state == AppLifecycleState.paused) {
      _presence.paused();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Layout? layout = ref.watch(layoutProvider);

    if (layout == null) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Layout.def.mainBack,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: layout.mainBack,
      body: Container(
        decoration: BoxDecoration(
          image: layout.image == null
              ? null
              : DecorationImage(
                  image: FileImage(layout.image!),
                  opacity: _opacity,
                  fit: BoxFit.cover,
                ),
        ),
        child: PageView(
          controller: _pageController,
          children: const [
            LayoutPage(),
            HomePage(),
            LogsPage(),
          ],
        ),
      ),
    );
  }
}

class TermsDialog extends ConsumerStatefulWidget {
  const TermsDialog(this.config, {super.key});
  final Config config;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TermsDialogState();
}

class _TermsDialogState extends ConsumerState<TermsDialog> {
  late bool _termValue;
  late bool _privacyValue;

  @override
  void initState() {
    super.initState();
    if (widget.config.isFirst || widget.config.isTermUpdated) {
      _termValue = false;
    } else {
      _termValue = true;
    }
    if (widget.config.isFirst || widget.config.isPrivacyUpdated) {
      _privacyValue = false;
    } else {
      _privacyValue = true;
    }
  }

  Future<void> _confirm() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Config config = widget.config;
    if (config.isFirst) {
      await prefs.setInt('terms_version', config.remoteTerms);
      await prefs.setInt('privacy_version', config.remotePrivacy);
    } else if (config.isTermUpdated) {
      await prefs.setInt('terms_version', config.remoteTerms);
    } else {
      await prefs.setInt('privacy_version', config.remotePrivacy);
    }
  }

  Widget _termsPage(Layout layout, bool isPrivacy) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: layout.mainBack,
      body: SafeArea(child: TermsPage(isPrivacy, fromDialog: true)),
    );
  }

  Widget _dialog(String description, Layout layout) {
    return Dialog(
      backgroundColor: layout.mainBack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 330,
        constraints: const BoxConstraints(maxHeight: 320),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ご利用前に',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: layout.mainText,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                color: layout.mainText,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 5),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                (widget.config.isFirst || widget.config.isTermUpdated)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: _termValue,
                              onChanged: (value) =>
                                  setState(() => _termValue = !_termValue),
                              visualDensity: VisualDensity.compact,
                              checkColor: layout.mainText,
                              activeColor: layout.subBack,
                              side: BorderSide(color: layout.mainText),
                            ),
                          ),
                          TextButton(
                            onPressed: () => SettingPageTemp.push(
                              context,
                              _termsPage(layout, false),
                            ),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(0),
                            ),
                            child: Text(
                              '利用規約',
                              style: TextStyle(
                                color: layout.subBack,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            'に同意する',
                            style: TextStyle(
                              color: layout.mainText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                (widget.config.isFirst || widget.config.isPrivacyUpdated)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: _privacyValue,
                              onChanged: (value) => setState(
                                  () => _privacyValue = !_privacyValue),
                              visualDensity: VisualDensity.compact,
                              checkColor: layout.mainText,
                              activeColor: layout.subBack,
                              side: BorderSide(color: layout.mainText),
                            ),
                          ),
                          TextButton(
                            onPressed: () => SettingPageTemp.push(
                              context,
                              _termsPage(layout, true),
                            ),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(0),
                            ),
                            child: Text(
                              'プライバシーポリシー',
                              style: TextStyle(
                                color: layout.subBack,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            'に同意する',
                            style: TextStyle(
                              color: layout.mainText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ],
            ),
            ElevatedButton(
              onPressed: (_termValue == false || _privacyValue == false)
                  ? null
                  : () {
                      Navigator.pop(context);
                      _confirm();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: (_termValue == false || _privacyValue == false)
                    ? Colors.white38
                    : layout.subBack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'はじめる',
                style: TextStyle(fontSize: 13, color: layout.mainText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    if (widget.config.isFirst) {
      return _dialog('利用規約とプライバシーポリシーに\n同意が必要です。', layout);
    } else if (widget.config.isTermUpdated && widget.config.isPrivacyUpdated) {
      return _dialog('利用規約とプライバシーポリシーが更新\nされました。ご利用には同意が必要です。', layout);
    } else if (widget.config.isTermUpdated) {
      return _dialog('利用規約が更新されました。\nご利用には同意が必要です。', layout);
    } else {
      return _dialog('プライバシーポリシーが更新されました。\nご利用には同意が必要です。', layout);
    }
  }
}
