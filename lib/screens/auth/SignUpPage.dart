import 'package:flutter/material.dart';
import 'package:roadeye/firebase/auth/firebase_auth_services.dart';
import 'package:roadeye/helper/CustomDialog.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _isSecure = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          title: title,
          message: message,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.5),
              Colors.green.withOpacity(0.5),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to RoadEye!',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Together, let\'s create a smoother and safer journey for everyone',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                  labelStyle: const TextStyle(color: Colors.white),
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.5), width: 1),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  labelStyle: const TextStyle(color: Colors.white),
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.5), width: 1),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                cursorColor: Colors.white,
                controller: _passwordController,
                obscureText: _isSecure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  labelStyle: const TextStyle(color: Colors.white),
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.5), width: 1),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 1),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isSecure ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    onPressed: () {
                      setState(() {
                        _isSecure = !_isSecure;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // showDialog(
                  //     context: context,
                  //     builder: (context) =>
                  //         const Center(child: CircularProgressIndicator()));

                  final email = _emailController.text;
                  final password = _passwordController.text;
                  final displayName = _nameController.text;
                  if (email.isNotEmpty && password.isNotEmpty) {
                    final user = await _authService
                        .signUpWithEmailAndPasswordWithDisplayName(
                            displayName, email, password);

                    if (user != null) {
                      print('Registration successful! User ID: ${user.uid}');
                      _showDialog('Success',
                          'Registration successful! You can now log in.');
                      ;
                    } else {
                      _showDialog('Error', 'An Unknown Error Occured.');
                      print('Registration failed.');
                    }
                  } else {
                    _showDialog('Error', 'Email Or Password Cannot Be Empty.');
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(color: Colors.black),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
