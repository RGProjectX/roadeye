import 'package:flutter/material.dart';
import 'package:roadeye/screens/home/HomeScreen.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String message;

  const CustomDialog({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            if (title == 'Error') {
              Navigator.of(context).pop();
            } else {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                  (route) => false);
            }
          },
          child: const Text(
            'OK',
            style: TextStyle(
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}
