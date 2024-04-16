class FriendState {
  static const String friend = 'friend';
  static const String requesting = 'requesting';
  static const String requested = 'requested';
  static const String blocked = 'blocked';
  static const String blocking = 'blocking';

  static const list = [
    friend,
    requesting,
    requested,
    blocked,
    blocking,
  ];

  static bool isFriendState(String state) {
    return list.contains(state);
  }

  static bool isFriend(String state) {
    return state == friend;
  }
}
