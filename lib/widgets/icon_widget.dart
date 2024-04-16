import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/layout.dart';
import '../providers/layout_providers.dart';

class IconWidget extends ConsumerWidget {
  const IconWidget(this.url, {super.key, this.radius, this.useCache = true});
  final String url;
  final double? radius;
  final bool useCache;

  bool get _isUrl => url.startsWith('http');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return CircleAvatar(
      radius: radius,
      backgroundColor: layout.subBack,
      foregroundImage: _isUrl
          ? useCache
              ? CachedNetworkImageProvider(url)
              : Image.network(url).image
          : Image.asset('images/person.png').image,
    );
  }
}
