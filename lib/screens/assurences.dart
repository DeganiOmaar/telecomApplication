import 'package:flutter/material.dart';

class Assurences extends StatefulWidget {
  const Assurences({super.key});

  @override
  State<Assurences> createState() => _AssurencesState();
}

class _AssurencesState extends State<Assurences> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: Text("Assurences", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),)
          ],
      )
    );
  }
}