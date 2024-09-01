import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/layout.dart';
import '../providers/layout_providers.dart';

class SettingItem extends ConsumerWidget {
  const SettingItem({
    super.key,
    required this.menu,
    required this.onTap,
    this.counting,
    this.putBadge = false,
  });

  final String menu;
  final Function()? onTap;
  final Future<int>? counting;
  final bool putBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Layout layout = ref.watch(layoutProvider) ?? Layout.def;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                menu,
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 15,
                  color: onTap == null ? layout.subText : layout.mainText,
                ),
              ),
              Row(
                children: [
                  FutureBuilder(
                    future: counting,
                    builder: ((context, snapshot) {
                      if (snapshot.hasData) {
                        return SizedBox(
                          width: 40,
                          child: Center(
                            child: Text(
                              snapshot.data.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 15,
                                color: layout.subText,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }),
                  ),
                  Badge(
                    smallSize: 7,
                    isLabelVisible: putBadge,
                    backgroundColor: layout.subBack,
                    child: SizedBox(
                      width: 21,
                      height: 21,
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 15,
                        color: layout.subText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
