import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventsView extends StatefulWidget {
  final DateTime eventDate;

  EventsView(DateTime date) : eventDate = date;

  @override
  State<StatefulWidget> createState() {
    return _EventsViewState(eventDate);
  }
}

class _EventsViewState extends State<EventsView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DateTime _eventDate;

  _EventsViewState(DateTime date) : _eventDate = date;

  Future<QuerySnapshot> _getEvents() async {
    FirebaseUser currentUser = await _auth.currentUser();

    if (currentUser != null) {
      QuerySnapshot events = await Firestore.instance
          .collection('calendar_events')
          .where('time', isGreaterThan: new DateTime(2018, _eventDate.month, _eventDate.day-1, 23, 59, 59))
          .where('time', isLessThan: new DateTime(2018, _eventDate.month, _eventDate.day+1))
          .where('email', isEqualTo: currentUser.email)
          .getDocuments();

      return events;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: new CloseButton(),
        title: new Text(_eventDate.month.toString() + '/' + _eventDate.day.toString()
                        + '/' + _eventDate.year.toString() + ' Events'),
      ),
      body: FutureBuilder(
        future: _getEvents(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return new CircularProgressIndicator();
            case ConnectionState.done:
            default:
              if (snapshot.hasError)
                return new Text('Error: ${snapshot.error}');
              else {
                return ListView(
                  children: snapshot.data.documents.map((document) {
                    return new Card(
                      color: Colors.orangeAccent,
                      elevation: 5.0,
                      shape: Border.all(color: Colors.black),
                      child: new Column(
//                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          new Container(
                            padding: EdgeInsets.all(10.0),
                            child:  new Text('Event: ' + document.data['name'],
                              style: TextStyle(color: Colors.black, fontSize: 18.0,),),
                          ),
                          new Container(
                            padding: EdgeInsets.all(10.0),
                            child:  new Text('Summary: ' + document.data['summary'],
                              style: TextStyle(color: Colors.black, fontSize: 18.0)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }
          }
        }
      ),
    );
  }

}