import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:intl/intl.dart';

class EventData {
  String title = '';
  DateTime time;
  String summary = '';
}

class EventCreator extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new EventCreatorState();
  }
}

class EventCreatorState extends State<EventCreator> {
  final dateFormat = DateFormat("MMMM d, yyyy 'at' h:mma");
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  EventData _eventData = new EventData();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: new CloseButton(),
        title: new Text('Create New Event'),
        actions: <Widget>[
          new Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(15.0),
            child: new InkWell(
              child: new Text(
                'SAVE',
                style: TextStyle(
                  fontSize: 20.0),
              ),
              onTap: () => _saveNewEvent(context),
            ),
          )
        ],
      ),
      body: new Form(
        key: this._formKey,
        child: new Column(
          children: <Widget>[
            new TextFormField(
              decoration: InputDecoration(
                  labelText: 'Event Title',
                  contentPadding: EdgeInsets.all(10.0)
              ),
              keyboardType: TextInputType.text,
              style: TextStyle(fontSize: 24.0, color: Colors.black),
              autovalidate: false,
              validator: this._validateTitle,
              onSaved: (String value) => this._eventData.title = value,
            ),
            new DateTimePickerFormField(
              format: dateFormat,
              keyboardType: TextInputType.datetime,
              style: TextStyle(fontSize: 24.0, color: Colors.black),
              decoration: InputDecoration(
                  labelText: 'Event Date',
                  contentPadding: EdgeInsets.all(10.0)
              ),
              onChanged: (date) {
                print(date.toUtc().toString());
              },
              autovalidate: false,
              validator: this._validateDate,
              onSaved: (DateTime value) => this._eventData.time = value,
            ),
            new TextFormField(
              decoration: InputDecoration(
                labelText: 'Summary / Notes',
                contentPadding: EdgeInsets.all(10.0),
              ),
              keyboardType: TextInputType.multiline,
              style: TextStyle(fontSize: 24.0, color: Colors.black),
              onSaved: (String value) => this._eventData.summary = value,
            ),
          ],
        )
      ),
    );
  }
  
  String _validateTitle(String value) {
    if (value.isEmpty) {
      return 'Please enter a valid title.';
    } else {
      return null;
    }
  }

  String _validateDate(DateTime value) {
    if ( (value != null)
        && (value.day >= 1 && value.day <= 31)
        && (value.month >= 1 && value.month <= 12)
        && (value.year >= 2015 && value.year <= 3000)) {
      return null;
    } else {
      return 'Please enter a valid event date.';
    }
  }

  Future _saveNewEvent(BuildContext context) async {
    FirebaseUser currentUser = await _auth.currentUser();
    print('current user: $currentUser');

    if (currentUser != null && this._formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.

      Firestore.instance.collection('calendar_events').document()
          .setData({'name': _eventData.title, 'summary': _eventData.summary,
        'time': _eventData.time, 'email': currentUser.email});
    } else {
      print('Error saving data to firestore.');
    }

    Navigator.maybePop(context);
  }

}