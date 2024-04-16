import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/layout.dart';
import '../models/user_data.dart';
import '../providers/friends_provider.dart';
import '../providers/layout_providers.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Spacer(flex: 2),
            Align(
              alignment: Alignment.topLeft,
              child: ClockWidget(),
            ),
            Spacer(flex: 8),
            Align(
              alignment: Alignment.bottomLeft,
              child: NativeAdWidget(),
            ),
            Spacer(flex: 1),
            FriendsWidget(),
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: 2,
              color: layout.mainText,
            ),
          ),
          Text(
            '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 85,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _load();
    });
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  // 本番環境用の広告ユニットID
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-9057495563597980/5634855423'
      : 'ca-app-pub-9057495563597980/1328778904';

  // テスト用の広告ユニットID
  // final String _adUnitId = Platform.isAndroid
  //     ? 'ca-app-pub-3940256099942544/2247696110'
  //     : 'ca-app-pub-3940256099942544/3986624511';

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
    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(),
      nativeTemplateStyle: _nativeTemplateStyle(layout),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() => _nativeAdIsLoaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    await _nativeAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return Container(
      height: 105,
      width: 320,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.only(left: 15, top: 0, right: 7, bottom: 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: layout.image != null
            ? null
            : Border.all(width: 0, color: layout.mainText),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: _nativeAdIsLoaded ? AdWidget(ad: _nativeAd!) : null,
      ),
    );
  }
}

class FriendsWidget extends ConsumerWidget {
  const FriendsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    final List<UserData> friends = ref.watch(friendsProvider);
    final List<UserData> activeFriends =
        friends.where((friend) => friend.bgndt != null).toList();

    if (activeFriends.isEmpty) {
      return const SizedBox(height: 56);
    }

    return Container(
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: layout.image != null
            ? null
            : Border.all(width: 0, color: layout.mainText),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: activeFriends.length,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemBuilder: (context, index) {
            final UserData friend = activeFriends[index];
            return Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: CachedNetworkImageProvider(friend.image),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
