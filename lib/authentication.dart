import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = new GoogleSignIn();

Future<FirebaseUser> signInWithGoogle() async {
  final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  final FirebaseUser user = await _auth.signInWithGoogle(
      idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

  assert(user.email != null);
  assert(!user.isAnonymous);
  assert(await user.getIdToken() != null);

  final FirebaseUser currentUser = await _auth.currentUser();
  assert(user.uid == currentUser.uid);

  print('signInWithGoogle succeeded: $user');
  return user;
}

Future<FirebaseUser> signInWithEmailPassword(String email, String password) async {
  final FirebaseUser user = await _auth.signInWithEmailAndPassword(email: email, password: password);

  assert(user.email != null);
  assert(!user.isAnonymous);
  assert(await user.getIdToken() != null);

  final FirebaseUser currentUser = await _auth.currentUser();
  assert(user.uid == currentUser.uid);

  print('signInEmail succeeded: $user');
  return user;
}

Future<Null> signOutWithGoogle() async {
  await _auth.signOut();
  await _googleSignIn.signOut();
}

Future<Null> signOut() async {
  await _auth.signOut();
}