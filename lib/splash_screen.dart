import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_widget_app/authentication.dart';
import 'package:flutter_widget_app/global_contants.dart';

class LoginData {
  String email = '';
  String password = '';
}

class SplashPage extends StatefulWidget {
  @override
  State createState() => new _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  LoginData _data = new LoginData();
  bool _isLoading = false;

  String validateEmail(String value) {
    if (value.isEmpty || !value.contains('@')) {
      return 'The E-mail Address must be a valid email address.';
    }
    return null;
  }

  String validatePassword(String value) {
    if (value.length < 6) {
      return 'The Password must be at least 6 characters.';
    }
    return null;
  }

  Future signInWithEmail() async {
    FirebaseUser user;

    // First validate form.
    if (this._formKey.currentState.validate()) {
       _formKey.currentState.save(); // Save our form now.

       setState(() {
         _isLoading = true;
       });

      try {
        user = await _auth.signInWithEmailAndPassword(email: _data.email,
            password: _data.password);
      } catch (error) {
        showErrorDialog(error);
      } finally {
        assert(user != null);
        assert(await user.getIdToken() != null);

        final FirebaseUser currentUser = await _auth.currentUser();
        assert(user.uid == currentUser.uid);

        print('signInEmail succeeded');
        setState(() {
          _isLoading = false;
        });

        // Navigate to main calendar view
        _navigateToCalendarView();
      }
    }
  }

  void _navigateToCalendarView() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamed(Constants.calendarRoute);
    }
  }

  Future signUpWithEmail() async {
    FirebaseUser user;

    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save();

      setState(() {
        _isLoading = true;
      });

      try {
        user = await _auth.createUserWithEmailAndPassword(
            email: _data.email, password: _data.password);
      } catch (error) {
        showErrorDialog(error);
      } finally {
        assert(user != null);
        assert(await user.getIdToken() != null);

        final FirebaseUser currentUser = await _auth.currentUser();
        assert(user.uid == currentUser.uid);

        print('signInEmail succeeded');

        // Add user to the 'users' collection
        await Firestore.instance.collection('users').document()
            .setData({'email': currentUser.email, 'token': ""});

        setState(() {
          _isLoading = false;
        });

        // Navigate to main calendar view
        _navigateToCalendarView();
      }
    }
  }

  void showErrorDialog(error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Sign Up Error'),
          content: new Text(error.message),
          actions: <Widget>[
            new FlatButton(
              onPressed: () {
                setState(() {
                  _isLoading = false;
                });
                Navigator.of(context).pop(true);
              },
              child: new Text('OK')
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    print('build().....');
    final emailWidget = new TextFormField(
      keyboardType: TextInputType.emailAddress,
      decoration: new InputDecoration(
          hintText: 'email@gmail.com',
          labelText: 'Email address',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32.0)
          )
      ),
      style: TextStyle(fontSize: 20.0, color: Colors.black),
      validator: this.validateEmail,
      onSaved: (String value) {
        this._data.email = value;
      },
    );

    final passwordWidget = new TextFormField(
      obscureText: true,
      decoration: new InputDecoration(
          hintText: 'Password',
          labelText: 'Please enter your password',
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32.0)
          )
      ),
      style: TextStyle(fontSize: 20.0, color: Colors.black),
      validator: this.validatePassword,
      onSaved: (String value) {
        this._data.password = value;
      },
    );

    final loginButton = new Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: new Material(
        borderRadius: BorderRadius.circular(30.0),
        shadowColor: Colors.lightBlueAccent.shade100,
        child: new MaterialButton(
            height: 42.0,
            color: Colors.lightBlueAccent,
            onPressed: () {
              this.signInWithEmail();
            },
            child: new Text('Login', style: new TextStyle(fontSize: 24.0, color: Colors.white))
        ),
      ),
    );

    final signUpButton = new Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: new Material(
        borderRadius: BorderRadius.circular(30.0),
        shadowColor: Colors.lightBlueAccent.shade100,
        child: new MaterialButton(
          height: 42.0,
          color: Colors.lightBlueAccent,
          onPressed: this.signUpWithEmail,
          child: new Text('Sign Up', style: new TextStyle(fontSize: 24.0, color: Colors.white))
        ),
      ),
    );

    final signInWithGoogleButton = new Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: new Material(
        borderRadius: BorderRadius.circular(30.0),
        shadowColor: Colors.lightBlueAccent.shade100,
        child: new MaterialButton(
            height: 42.0,
            color: Colors.lightBlueAccent,
            onPressed: () async {
              AuthHelper authHelper = new AuthHelper();
              FirebaseUser user = await authHelper.signInWithGoogle();
              if(user != null) {
                _navigateToCalendarView();
              } else {
                print("Error signing with Google.");
              }
            },
            child: new Text('Sign in with Google', style: new TextStyle(fontSize: 24.0, color: Colors.white))
        ),
      ),
    );

    final resetPasswordText = new GestureDetector(
      onTap: () {
        _formKey.currentState.save();
        String resetMessage;
        if (_data.email.isEmpty) {
          resetMessage = 'Please enter a email address.';
        } else {
          resetMessage = 'Reset password for ' + _data.email;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return new AlertDialog(
              title: new Text('Reset Password'),
              content: new Text(resetMessage),
              actions: <Widget>[
                new FlatButton(
                    onPressed: () {
                      if (_data.email.isNotEmpty) {
                        _auth.sendPasswordResetEmail(email: _data.email);
                      }
                      Navigator.of(context).pop(true);
                    },
                    child: new Text('OK')
                ),
                new FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: new Text("CANCEL"),
                )
              ],
            );
          }
        );
      },
      child: new Text('Reset Password',textAlign: TextAlign.center,
        style: new TextStyle(fontSize: 24.0, color: Colors.blue),
      ),
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
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(left: 24.0, right: 24.0),
          children: <Widget>[
            loginImage,
            SizedBox(height: 16.0),
            new Form(
              key: this._formKey,
              child: new Column(
                children: <Widget>[
                  emailWidget,
                  SizedBox(height: 8.0),
                  passwordWidget,
                ],
              ),
            ),
            SizedBox(height: 8.0),
            _isLoading ? loadingSpinner:
                Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      loginButton,
                      SizedBox(width: 20.0),
                      signUpButton,
                    ],
                  ),
                ),
            SizedBox(height: 4.0),
            signInWithGoogleButton,
            SizedBox(height: 4.0),
            resetPasswordText,
          ],
        ),
      )
    );
  }
}