import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter_widget_app/models/event_model.dart';
import 'package:intl/intl.dart';

class EventData {
  String title = '';
  DateTime time;
  String summary = '';
}

class EventCreator extends StatefulWidget {
  final Event _event;

  @override
  State<StatefulWidget> createState() {
    return new EventCreatorState();
  }

  EventCreator(this._event) {
    createState();
  }
}

class EventCreatorState extends State<EventCreator> {
  final dateFormat = DateFormat("MMMM d, yyyy 'at' h:mma");
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  EventData _eventData = new EventData();

  @override
  Widget build(BuildContext context) {

    final titleWidget = new TextFormField(
      keyboardType: TextInputType.text,
      decoration: new InputDecoration(
          hintText: 'Event Name',
          labelText: 'Event Title',
          contentPadding: EdgeInsets.all(16.0),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
          )
      ),
      initialValue: widget._event != null ? widget._event.title : '',
      style: Theme.of(context).textTheme.headline,
      validator: this._validateTitle,
      onSaved: (String value) => this._eventData.title = value,
    );

    final notesWidget = new TextFormField(
      keyboardType: TextInputType.multiline,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Notes',
        labelText: 'Enter your notes here',
        contentPadding: EdgeInsets.all(16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0)
        )
      ),
      initialValue: widget._event != null ? widget._event.summary : '',
      style: Theme.of(context).textTheme.headline,
      onSaved: (String value) => this._eventData.summary = value,
    );
    
    return new Scaffold(
      appBar: new AppBar(
        leading: new BackButton(),
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
        child: new Container(
          padding: EdgeInsets.all(10.0),
          child: new Column(
            children: <Widget>[
              titleWidget,
              SizedBox(height: 16.0),
              new DateTimePickerFormField(
                initialDate: widget._event != null ? widget._event.time : DateTime.now(),
                initialValue: widget._event != null ? widget._event.time : DateTime.now(),
                format: dateFormat,
                keyboardType: TextInputType.datetime,
                style: TextStyle(fontSize: 20.0, color: Colors.black),
                decoration: InputDecoration(
                    labelText: 'Event Date',
                    hintText: 'November 1, 2018 at 5:00PM',
                    contentPadding: EdgeInsets.all(20.0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0)
                    )
                ),
                autovalidate: false,
                validator: this._validateDate,
                onSaved: (DateTime value) => this._eventData.time = value,
              ),
              SizedBox(height: 16.0),
              notesWidget,
            ],
          ),
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

      Firestore.instance.collection('calendar_events').document(widget._event != null ? widget._event.documentId : null)
          .setData({'name': _eventData.title, 'summary': _eventData.summary,
        'time': _eventData.time, 'email': currentUser.email});

      Navigator.maybePop(context);
    } else {
      print('Error validating data and saving to firestore.');
    }
  }

}