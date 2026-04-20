abstract class PendingInviteCodeStore {
  String? get pendingInviteCode;
  Future<void> setPendingInviteCode(String? code);
}
