import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roadeye/firebase/auth/firebase_auth_services.dart';
import 'package:roadeye/helper/CustomDialog.dart';
import 'package:roadeye/screens/auth/SignUpPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isSecure = true;

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
                'Welcome Back!', 
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sign in to continue your journey with RoadEye.', 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
              const SizedBox(height: 20),
              
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
              const SizedBox(
                  height: 10), 

              TextFormField(
                cursorColor: Colors.white,
                controller: _passwordController,
                obscureText:
                    _isSecure, 
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

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () async {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return Center(child: CircularProgressIndicator());
                      });
                  final email = _emailController.text;
                  final password = _passwordController.text;

                  if (email.isNotEmpty && password.isNotEmpty) {
                    final user = await _authService.signInWithEmailAndPassword(
                        email, password);

                    if (user != null) {
                      print('Login successful! User ID: ${user.uid}');
                      Navigator.pop(context);
                      _showDialog('Success',
                          'Login successful. You can continue using our services.');
                      
                    } else {
                      Navigator.pop(context);
                      _showDialog(
                          'Error', 'Login failed. Invalid credentials.');
                      print('Login failed.');
                    }
                  } else {
                    _showDialog('Error', 'Email or password cannot be empty.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                child: const Text(
                  'Log In', 
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.white,
                      thickness: 1,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Or',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Divider(
                      color: Colors.white,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Icon(
                CupertinoIcons.mail_solid,
                size: 40,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Not a member yet? ',
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Register Now',
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
