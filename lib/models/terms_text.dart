class TermsText {
  const TermsText({
    required this.type,
    required this.text,
    this.indent = 0,
  });

  final String type;
  final String text;
  final int indent;

  static const String title = "title";
  static const String headline = "headline";
  static const String content = "content";
  static const String signature = "signature";

  factory TermsText.fromJson(Map<String, dynamic> json) {
    return TermsText(
      type: json['type'] ?? content,
      text: json['text'] ?? "",
      indent: json['indent'] ?? 0,
    );
  }
}
