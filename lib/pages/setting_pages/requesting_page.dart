import '../../models/friend_state.dart';
import '../../widgets/setting_widget.dart';

class RequestingPage extends SettingWidget {
  const RequestingPage(super.myData, {super.key});

  @override
  String get title => '送信リクエスト';
  @override
  String get noUserMsg => '送信済みのリクエストはありません。';
  @override
  String get tgtFriendState => FriendState.requesting;
}
