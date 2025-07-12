import 'package:flutter/material.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me (To be built)'),
      ),
      body: const Center(
        child: Text('Me Screen Placeholder'),
      ),
    );
  }
}