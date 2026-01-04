import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => null;

  void setLocaleTag(String tag) {
    if (tag == 'system') {
      state = null;
      return;
    }
    if (tag == 'pt_BR') {
      state = const Locale('pt', 'BR');
      return;
    }
    state = Locale(tag);
  }
}
