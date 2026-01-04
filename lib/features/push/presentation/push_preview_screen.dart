import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class PushPreviewScreen extends StatelessWidget {
  const PushPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pushPreviewTitle)),
      body: Center(
        child: Text(
          l10n.pushPreviewDescription,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
