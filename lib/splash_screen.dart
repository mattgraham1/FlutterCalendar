import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_widget_app/authentication.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:flutter_widget_app/global_contants.dart';

class SplashPage extends StatefulWidget {
  @override
  State createState() => new _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  void _navigateToCalendarView() {
    Navigator.of(context).pushNamedAndRemoveUntil(Constants.calendarRoute,
            (Route<dynamic> route) => false);
  }

  void _navigateToSignInPage() {
    Navigator.of(context).pushNamed(Constants.signInRoute);
  }

  @override
  Widget build(BuildContext context) {
    final signInWithGoogleButton = GoogleSignInButton(
      onPressed: () async {
        AuthHelper authHelper = new AuthHelper();

        FirebaseUser user = await authHelper.signInWithGoogle().catchError((onError) {
          // Handle errors if needed
        });

        if(user != null) {
          _navigateToCalendarView();
        } else {
          print("Error signing in with Google.");
        }
      },
      darkMode: true);

    final signInWithEmailButton = ButtonTheme(
      height: 40.0,
      padding: const EdgeInsets.all(0.0),
      shape: RoundedRectangleBorder(
        // Google doesn't specify a border radius, but this looks about right.
        borderRadius: BorderRadius.circular(3.0),
      ),
      child: RaisedButton(
        onPressed: _navigateToSignInPage,
        color: Color(0xFF4285F4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(padding: const EdgeInsets.all(1.0),
              child: Container(
                height: 38.0, // 40dp - 2*1dp border
                width: 38.0, // matches above
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3.0),
                ),
                child: Center(
                  child: Icon(Icons.email, color: Colors.white, size: 38),
                ),
              ),
            ),
            SizedBox(width: 14.0 /* 24.0 - 10dp padding */),
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 8.0, 8.0, 8.0),
              child: Text('Sign in with email',
                style: TextStyle(fontSize: 18.0, fontFamily: "Roboto", fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    final loginImage = new Image.asset('assets/calendar.png',
      height: 128.0,
    );

    return new Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(child: Text("Events Calendar",
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
              ),
              loginImage,
              SizedBox(height: 8.0),
              signInWithGoogleButton,
              Center(child: Text("or")),
              SizedBox(height: 4.0),
              signInWithEmailButton,
            ],
          ),
        ),
      )
    );
  }
}