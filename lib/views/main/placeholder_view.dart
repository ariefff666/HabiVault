import 'package:flutter/material.dart';

class PlaceholderView extends StatelessWidget {
  final String pageName;
  const PlaceholderView({super.key, required this.pageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pageName)),
      body: Center(
        child: Text(
          'This is the $pageName page.\nComing soon!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
