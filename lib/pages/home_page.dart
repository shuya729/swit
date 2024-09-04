import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/layout.dart';
import '../models/presence.dart';
import '../models/user_data.dart';
import '../providers/friends_provider.dart';
import '../providers/layout_providers.dart';
import '../providers/my_data_privder.dart';
import '../widgets/icon_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.pageController});
  final PageController? pageController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(flex: 2),
            const Align(
              alignment: Alignment.topLeft,
              child: ClockWidget(),
            ),
            const Spacer(flex: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                NativeAdWidget(),
                LabelWidget(),
              ],
            ),
            const Spacer(flex: 1),
            FriendsWidget(pageController: pageController),
          ],
        ),
      ),
    );
  }
}

class ClockWidget extends ConsumerStatefulWidget {
  const ClockWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends ConsumerState<ClockWidget> {
  DateTime _now = DateTime.now();
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_now.year}/${_now.month.toString().padLeft(2, '0')}/${_now.day.toString().padLeft(2, '0')}',
            // '2024/04/01', // サンプル用のコード
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 24,
              letterSpacing: 2,
              color: layout.mainText,
            ),
          ),
          Text(
            '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
            // '12:34', // サンプル用のコード
            style: TextStyle(
              fontWeight: FontWeight.w100,
              fontSize: 70,
              letterSpacing: 2,
              height: 1.0,
              color: layout.mainText,
            ),
          ),
        ],
      ),
    );
  }
}

class NativeAdWidget extends ConsumerStatefulWidget {
  const NativeAdWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;
  bool _showAd = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nativeAd?.dispose();
    super.dispose();
  }

  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-9057495563597980/5634855423'
      : 'ca-app-pub-9057495563597980/1328778904';

  NativeTemplateStyle _nativeTemplateStyle(Layout layout) {
    return NativeTemplateStyle(
      templateType: TemplateType.small,
      mainBackgroundColor: Colors.transparent,
      cornerRadius: 15,
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: layout.mainText,
        size: 15,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: layout.subText,
        size: 12,
      ),
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: layout.mainText,
        backgroundColor: layout.subBack,
        size: 13,
      ),
    );
  }

  Future<void> _load() async {
    final Layout? layout = ref.watch(layoutProvider);
    if (layout == null) return;

    setState(() => _nativeAdIsLoaded = false);
    await _nativeAd?.dispose();

    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(),
      nativeTemplateStyle: _nativeTemplateStyle(layout),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _nativeAdIsLoaded = true;
            _showAd = true;
          });
        },
        onAdFailedToLoad: (ad, error) async {
          await ad.dispose();
          _timer = Timer(const Duration(minutes: 1), () => _load());
        },
      ),
    );
    await _nativeAd?.load();
  }

  Future<void> _onEnd() async {
    if (_showAd) {
      _timer = Timer(
        const Duration(minutes: 1),
        () => setState(() => _showAd = false),
      );
    } else {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;

    // // サンプル用のコード
    // return Container(
    //   height: 105,
    //   width: 320,
    //   margin: const EdgeInsets.symmetric(horizontal: 10),
    // );

    return Container(
      height: 105,
      width: 320,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.only(left: 15, top: 0, right: 7, bottom: 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 0, color: layout.mainText),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedOpacity(
          opacity: _showAd ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          onEnd: _onEnd,
          child: _nativeAdIsLoaded ? AdWidget(ad: _nativeAd!) : null,
        ),
      ),
    );
  }
}

class LabelWidget extends ConsumerWidget {
  const LabelWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 10),
      child: Image(
        image: layout.label.bodyImage,
        fit: BoxFit.contain,
      ),
    );
  }
}

class FriendsWidget extends ConsumerWidget {
  const FriendsWidget({super.key, required this.pageController});
  final PageController? pageController;

  Widget _friendsBack({required Layout layout, required Widget child}) {
    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 25),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: layout.image != null
            ? null
            : Border.all(width: 0, color: layout.mainText),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: child,
      ),
    );
  }

  Future<void> _animateToPage(int page) async {
    if (pageController == null) return;
    await pageController?.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Presence presence = Presence.instance;
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    final UserData? myData = ref.watch(myDataProvider);
    final List<UserData> friends = ref.watch(friendsProvider);
    final List<UserData> activeFriends =
        friends.where((friend) => friend.bgndt != null).toList();

    if (myData == null) {
      return FutureBuilder(
        future: Future.delayed(const Duration(microseconds: 600)),
        builder: (context, snapshot) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity:
                snapshot.connectionState == ConnectionState.done ? 1.0 : 0.0,
            child: SizedBox(
              height: 46,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _animateToPage(0),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_left,
                            size: 23,
                            color: layout.subText,
                          ),
                          Text(
                            'レイアウト',
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              color: layout.mainText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _animateToPage(2),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: [
                          Text(
                            'ログ',
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              color: layout.mainText,
                              fontSize: 14,
                            ),
                          ),
                          Icon(
                            Icons.arrow_right,
                            size: 23,
                            color: layout.subText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return StreamBuilder(
      initialData: presence.state,
      stream: presence.stateStream,
      builder: (context, snapshot) {
        final bool connected = snapshot.data ?? false;
        final bool completed = myData.bgndt != null;

        if (connected == false || completed == false) {
          return FutureBuilder(
            future: Future.delayed(const Duration(seconds: 60)),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _friendsBack(
                  layout: layout,
                  child: SizedBox(
                    width: 54,
                    child: Center(
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: layout.subText,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return _friendsBack(
                  layout: layout,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          connected == false
                              ? "インターネット接続がありません"
                              : "接続状況が正しく処理されませんでした",
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 13,
                            color: layout.mainText,
                          ),
                        ),
                        Text(
                          connected == false
                              ? "ログの記録やフレンドへの表示が行われません"
                              : "アプリを再起動してください",
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 13,
                            color: layout.mainText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        }

        if (activeFriends.isEmpty) {
          return const SizedBox(height: 46);
        }

        return _friendsBack(
          layout: layout,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: activeFriends.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, index) {
              final UserData friend = activeFriends[index];
              return Padding(
                padding: const EdgeInsets.all(2),
                child: Center(
                  child: IconWidget(friend.image, radius: 18),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
