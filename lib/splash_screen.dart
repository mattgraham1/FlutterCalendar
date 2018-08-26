import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class _LoginData {
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
  _LoginData _data = new _LoginData();

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

      print('Printing the login data.');
      print('Email: ${_data.email}');
      print('Password: ${_data.password}');

      try {
        user = await _auth.signInWithEmailAndPassword(email: _data.email,
            password: _data.password);
      } catch (error) {
        print(error.toString());
      } finally {
        assert(user != null);
        assert(await user.getIdToken() != null);

        final FirebaseUser currentUser = await _auth.currentUser();
        assert(user.uid == currentUser.uid);

        print('signInEmail succeeded: $user');

        // Navigate to main calendar view
        _navigateToCalendarView();
      }
    }
  }

  void _navigateToCalendarView() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamed('/calendar');
    }
  }

  Future signUpWithEmail() async {
    FirebaseUser user;

    if (this._formKey.currentState.validate()) {
      _formKey.currentState.save();
      try {
        user = await _auth.createUserWithEmailAndPassword(
            email: _data.email, password: _data.password);
      } catch (error) {
        print(error);
      } finally {
        assert(user != null);
        assert(await user.getIdToken() != null);

        final FirebaseUser currentUser = await _auth.currentUser();
        assert(user.uid == currentUser.uid);

        print('signInEmail succeeded: $user');

        // Navigate to main calendar view
        _navigateToCalendarView();
      }
    }
  }

  void byPassLogin() {
    if (_auth.currentUser() != null) {
      Navigator.of(context).pop();
    } else {
      print('Invalid user.');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Container (
        padding: EdgeInsets.all(20.0),
        alignment: Alignment.center,
        child: new Form(
          key: this._formKey,
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: new InputDecoration(
                    hintText: 'firstname.lastname@gmail.com',
                    labelText: 'Email address',
                  ),
                  style: TextStyle(fontSize: 24.0, color: Colors.black),
                  validator: this.validateEmail,
                  onSaved: (String value) {
                    this._data.email = value;
                  },
                ),
                new TextFormField(
                  obscureText: true,
                  decoration: new InputDecoration(
                    hintText: 'Password',
                    labelText: 'Please enter your password',
                  ),
                  style: TextStyle(fontSize: 24.0, color: Colors.black),
                  validator: this.validatePassword,
                  onSaved: (String value) {
                    this._data.password = value;
                  },
                ),
                new Container(
                  width: MediaQuery.of(context).size.width,
                  margin: new EdgeInsets.only(top: 20.0),
                  child: new RaisedButton(
                    child: new Text(
                      'Login',
                      style: new TextStyle(fontSize: 24.0, color: Colors.white),
                    ),
                    color: Colors.blue,
                    onPressed: this.signInWithEmail
                  ),
                ),
                new Container(
                  width: MediaQuery.of(context).size.width,
                  margin: new EdgeInsets.only(top: 20.0),
                  child: new RaisedButton(
                    child: new Text(
                      'Sign Up',
                      style: new TextStyle(fontSize: 24.0, color: Colors.white),
                    ),
                    color: Colors.blue,
                    onPressed: this.signUpWithEmail
                  ),
                ),
              ],
            )
        ),
      ),
    );
  }
}