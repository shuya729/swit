import '../../models/friend_state.dart';
import '../../widgets/setting_widget.dart';

class RequestedPage extends SettingWidget {
  const RequestedPage(super.myData, {super.key});

  @override
  String get title => '受信リクエスト';
  @override
  String get noUserMsg => '受信したリクエストはありません。';
  @override
  String get tgtFriendState => FriendState.requested;
}
