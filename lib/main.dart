import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'splash_screen.dart';
import 'event_creator.dart';

enum _AppBarMenu {refresh, logout}

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Calendar',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _loadHomeScreen(),
      routes: {
        '/splash': (context) => SplashPage(),
        '/calendar': (context) => MyApp(),
        '/event_creator': (context) => EventCreator(),
      },
    );
  }

  _loadHomeScreen() {
    return FutureBuilder<FirebaseUser>(
      future: _auth.currentUser(),
      builder: (BuildContext context, AsyncSnapshot<FirebaseUser> snapshot) {
        switch(snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return CircularProgressIndicator();
          default:
            if(snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              if(snapshot.data == null)
                return SplashPage();
              else
                return MonthView();
            }
        }
      }
    );
  }
}

class MonthView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return CalendarState();
  }
}

class CalendarState extends State<MonthView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime _dateTime;
  QuerySnapshot _userEventSnapshot;

  CalendarState() {
    _dateTime = DateTime.now();
  }

  Future<QuerySnapshot> getCalendarData() async {
    FirebaseUser currentUser = await _auth.currentUser();

    if (currentUser != null) {
      QuerySnapshot userEvents = await Firestore.instance
          .collection('calendar_events')
          .where(
          'time', isGreaterThanOrEqualTo: new DateTime(2018, _dateTime.month))
          .where('email', isEqualTo: currentUser.email)
          .getDocuments();

      _userEventSnapshot = userEvents;
      return _userEventSnapshot;
    } else {
      return null;
    }
  }

  void _previousMonthSelected() {
    setState(() {
      if (_dateTime.month == DateTime.january)
        _dateTime = new DateTime(_dateTime.year - 1, DateTime.december);
      else
        _dateTime = new DateTime(_dateTime.year, _dateTime.month - 1);
    });
  }

  void _nextMonthSelected() {
    setState(() {
      if (_dateTime.month == DateTime.december)
        _dateTime = new DateTime(_dateTime.year + 1, DateTime.january);
      else
        _dateTime = new DateTime(_dateTime.year, _dateTime.month + 1);
    });
  }

  void _onDayTapped() {
    print("onDayTapped()...");
  }

  void _onFabClicked() {
    print("on FAB clicked()...");
    Navigator.pushNamed(context, '/event_creator');
  }

  @override
  Widget build(BuildContext context) {
    final int numWeekDays = 7;
    var size = MediaQuery.of(context).size;

    /*24 is for notification bar on Android*/
    /*28 is for weekday labels of the row*/
    final double itemHeight = (size.height - kToolbarHeight - 24 - 28) / 5;
    final double itemWidth = size.width / numWeekDays;

    return new Scaffold(
        backgroundColor: Colors.white,
        appBar: new AppBar(
          title: new Text(
              getMonthName(_dateTime.month) + " " + _dateTime.year.toString()),
          actions: <Widget>[
            IconButton(
                icon: Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                ),
                onPressed: _previousMonthSelected
            ),
            IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
                onPressed: _nextMonthSelected
            ),
            PopupMenuButton<_AppBarMenu>(
              onSelected: (_AppBarMenu value) {
                _handleAppbarMenu(context, value);
              },
              itemBuilder: (BuildContext context) => <PopupMenuItem<_AppBarMenu>>[
                const PopupMenuItem(
                  value: _AppBarMenu.refresh,
                  child: Text('Refresh'),
                ),
                const PopupMenuItem(
                  value: _AppBarMenu.logout,
                  child: Text('Logout'),
                )
              ],
            ),
          ],
        ),
        floatingActionButton: new FloatingActionButton(
          onPressed: _onFabClicked,
          child: new Icon(Icons.add),
        ),
        body: new Column(
          children: <Widget>[
            new Row(
              children: <Widget>[
                new Expanded(
                    child: new Text('S',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline)),
                new Expanded(
                    child: new Text('M',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline)),
                new Expanded(
                    child: new Text('T',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline)),
                new Expanded(
                    child: new Text('W',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline)),
                new Expanded(
                    child: new Text('T',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline)),
                new Expanded(
                    child: new Text('F',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline)),
                new Expanded(
                    child: new Text('S',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline)),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
            new GridView.count(
              crossAxisCount: numWeekDays,
              childAspectRatio: (itemWidth / itemHeight),
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: List.generate(getNumberOfDaysInMonth(_dateTime.month),
                  (index) {
                int dayNumber = index + 1;
                return new GestureDetector(
                    // Used for handling tap on each day view
                    onTap: _onDayTapped,
                    child: new Container(
                        margin: const EdgeInsets.all(2.0),
                        padding: const EdgeInsets.all(1.0),
                        decoration: new BoxDecoration(
//                        color: Colors.red, // Color for debugging layout
                            border: new Border.all(color: Colors.grey)),
                        child: new Column(
                          children: <Widget>[
                            buildDayNumberWidget(dayNumber),
                            buildDayEventInfoWidget(dayNumber),
                          ],
                        )));
              }),
            )
          ],
        ));
  }

  Align buildDayNumberWidget(int dayNumber) {
    if (dayNumber == DateTime.now().day
        && _dateTime.month == DateTime.now().month) {
      // Add a circle around the current day
      return Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: 35.0, // Should probably calculate these values
          height: 35.0,
          padding: EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange, // Color for debugging layout
            border: Border.all(),
          ),
          child: new Text(
            '$dayNumber',
            textAlign: TextAlign.center,
            //style: Theme.of(context).textTheme.headline,
            style: TextStyle(color: Colors.black, fontSize: 20.0),
          ),
        ),
      );
    } else {
      // No circle around the current day
      return Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: 35.0, // Should probably calculate these values
          height: 35.0,
          padding: EdgeInsets.all(5.0),
          child: new Text(
            '$dayNumber',
            textAlign: TextAlign.center,
            //style: Theme.of(context).textTheme.headline,
            style: TextStyle(color: Colors.black, fontSize: 20.0),
          ),
        ),
      );
    }
  }

  Widget buildDayEventInfoWidget(int dayNumber) {
    return new FutureBuilder(
        future: getCalendarData(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return new CircularProgressIndicator();
            case ConnectionState.done:
              int eventCount = 0;
              DateTime eventDate;

              _userEventSnapshot.documents.forEach((doc) {
                eventDate = doc.data['time'];
                if (eventDate != null
                    && eventDate.day == dayNumber
                    && eventDate.month == _dateTime.month
                    && eventDate.year == _dateTime.year) {
                  eventCount++;
                }
              });

              if (eventCount > 0) {
                return Container(
                    decoration: new BoxDecoration(
                      color: Colors.green,
                    ),
                    child: new Text(
                      "Events: $eventCount",
                      maxLines: 1,
                      style: new TextStyle(fontSize: 12.0),
                    )
                );
              } else {
                return new Container();
              }

              break;
            default:
              if (snapshot.hasError)
                return new Text('Error: ${snapshot.error}');
              else
                return new Text('Result: ${snapshot.data}');
          }
        });
  }

  int getNumberOfDaysInMonth(final int month) {
    int numDays = 28;

    // Months are 1, ..., 12
    switch (month) {
      case 1:
        numDays = 31;
        break;
      case 2:
        numDays = 28;
        break;
      case 3:
        numDays = 31;
        break;
      case 4:
        numDays = 30;
        break;
      case 5:
        numDays = 31;
        break;
      case 6:
        numDays = 30;
        break;
      case 7:
        numDays = 31;
        break;
      case 8:
        numDays = 31;
        break;
      case 9:
        numDays = 30;
        break;
      case 10:
        numDays = 31;
        break;
      case 11:
        numDays = 30;
        break;
      case 12:
        numDays = 31;
        break;
      default:
        numDays = 28;
    }
    return numDays;
  }

  String getMonthName(final int month) {
    // Months are 1, ..., 12
    switch (month) {
      case 1:
        return "January";
      case 2:
        return "February";
      case 3:
        return "March";
      case 4:
        return "April";
      case 5:
        return "May";
      case 6:
        return "June";
      case 7:
        return "July";
      case 8:
        return "August";
      case 9:
        return "September";
      case 10:
        return "October";
      case 11:
        return "November";
      case 12:
        return "December";
      default:
        return "Unknown";
    }
  }

  Future _handleAppbarMenu(BuildContext context, _AppBarMenu value) async {
    switch(value) {
      case _AppBarMenu.refresh:
        // TODO: refresh calendar data.
        break;
      case _AppBarMenu.logout:
        await _auth.signOut();
        Navigator.pushNamed(context, '/splash');
        break;
    }
  }
}
