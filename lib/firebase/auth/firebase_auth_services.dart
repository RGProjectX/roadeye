import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmailAndPasswordWithDisplayName(
      String displayName, String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user!.updateDisplayName(displayName);

      await credential.user!.reload();
      final User? user = _auth.currentUser;

      return user;
    } catch (e) {
      print("Some Error Occurred : SignUp Function");
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      print("Some Error Occurred : SignIn Function");
      return null;
    }
  }
}
