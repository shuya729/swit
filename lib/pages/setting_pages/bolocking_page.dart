import '../../models/friend_state.dart';
import '../../widgets/setting_widget.dart';

class BlockingPage extends SettingWidget {
  const BlockingPage(super.myData, {super.key});

  @override
  String get title => 'ブロックリスト';
  @override
  String get noUserMsg => 'ブロック中のユーザーはいません。';
  @override
  String get tgtFriendState => FriendState.blocking;
}
