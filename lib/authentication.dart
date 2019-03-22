import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthHelper {
  static final AuthHelper _singleton = new AuthHelper._internal();

  factory AuthHelper() {
    return _singleton;
  }

  FirebaseAuth _auth;
  GoogleSignIn _googleSignIn;

  AuthHelper._internal() {
    _auth = FirebaseAuth.instance;
    _googleSignIn = new GoogleSignIn();
  }

  Future<FirebaseUser> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser?.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final FirebaseUser user = await _auth.signInWithCredential(credential);
    final FirebaseUser currentUser = await _auth?.currentUser();
    assert(user?.uid == currentUser?.uid);

    print('signInWithGoogle succeeded: $user');
    return user;
  }

  Future<Null> signOutWithGoogle() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<Null> signOut() async {
    await _auth.signOut();
  }
}