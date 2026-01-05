import 'package:flutter/material.dart';

class FullScreenLoadingOverlay extends StatelessWidget {
  const FullScreenLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }

    return Stack(
      children: [
        child,
        const ModalBarrier(dismissible: false, color: Colors.black54),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
