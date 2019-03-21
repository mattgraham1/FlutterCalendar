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
  bool _isLoading = false;

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
        setState(() {
          _isLoading = true;
        });

        AuthHelper authHelper = new AuthHelper();

        FirebaseUser user = await authHelper.signInWithGoogle().catchError((onError) {
          // Clear spinner on error
          setState(() {
            _isLoading = false;
          });
        });

        // Clear spinner
        setState(() {
          _isLoading = false;
        });

        if(user != null) {
          _navigateToCalendarView();
        } else {
          print("Error signing in with Google.");
        }
      },
      darkMode: true);

    final signInWithEmailButton = new Container(
        child: MaterialButton(
          onPressed: _navigateToSignInPage,
          elevation: 4.0,
          color: Color(0xFF4285F4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.email, color: Colors.white, size: 38),
              SizedBox(width: 14.0,),
              Text("Sign in with email",
                  style: new TextStyle(fontSize: 18.0, color: Colors.white)),
            ],
          ),
        )
    );

    final loginImage = new Image.asset('assets/calendar.png',
      height: 128.0,
    );

    final loadingSpinner = new Center(
      heightFactor: null,
      widthFactor: null,
      child: new CircularProgressIndicator(),
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