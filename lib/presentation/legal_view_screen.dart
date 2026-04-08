import 'package:flutter/material.dart';

class LegalViewScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalViewScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black87)),
        backgroundColor: const Color(0xFFFAF6F0),
        iconTheme: const IconThemeData(color: Colors.black54),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
