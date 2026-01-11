import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedNoticeType extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? code) {
    state = code;
  }
}

final selectedNoticeTypeProvider =
    NotifierProvider<SelectedNoticeType, String?>(SelectedNoticeType.new);
