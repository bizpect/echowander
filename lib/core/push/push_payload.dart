class PushPayload {
  const PushPayload({required this.title, required this.body, this.route});

  final String title;
  final String body;
  final String? route;
}
