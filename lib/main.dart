import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_app/global_contants.dart';

import 'splash_screen.dart';
import 'event_creator.dart';
import 'event_view.dart';
import 'contacts_view.dart';

enum _AppBarMenu {logout}

void main() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Events Calendar',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _loadHomeScreen(),
      routes: {
        '/splash': (context) => SplashPage(),
        '/calendar': (context) => MyApp(),
        '/event_creator': (context) => EventCreator(null),
        '/calendar_contacts': (context) => CalendarContacts(),
      },
    );
  }

  Widget _loadHomeScreen() {
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
                return HomePage();
            }
        }
      }
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return CalendarState();
  }
}

class CalendarState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();
  DateTime _dateTime;
  QuerySnapshot _userEventSnapshot;
  int _beginMonthPadding=0;

  CalendarState() {
    _dateTime = DateTime.now();
    setMonthPadding();
  }

  @override
  void initState() {
    super.initState();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("******** - onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("******** - onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("******** - onResume: $message");
      },
    );

    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });

    _firebaseMessaging.getToken().then((String token) async {
      assert(token != null);
      print('push token: ' + token);

      FirebaseUser user = await _auth.currentUser();
      QuerySnapshot snapshot = await Firestore.instance.collection('users')
          .where('email', isEqualTo: user.email).getDocuments();

      snapshot.documents.forEach((doc) {
        Firestore.instance.collection('users').document(doc.documentID)
          .setData({'email': user.email, 'token': token});
      });
    });
  }

  void setMonthPadding() {
    _beginMonthPadding = new DateTime(_dateTime.year, _dateTime.month, 1).weekday;
    _beginMonthPadding == 7 ? (_beginMonthPadding = 0) : _beginMonthPadding;
  }

  Future<QuerySnapshot> _getCalendarData() async {
    FirebaseUser currentUser = await _auth.currentUser();

    if (currentUser != null) {
      QuerySnapshot userEvents = await Firestore.instance
          .collection('calendar_events')
          .where(
          'time', isGreaterThanOrEqualTo: new DateTime(_dateTime.year, _dateTime.month))
          .where('email', isEqualTo: currentUser.email)
          .getDocuments();

      _userEventSnapshot = userEvents;
      return _userEventSnapshot;
    } else {
      return null;
    }
  }

  void _goToToday() {
    print("trying to go to the month of today");
    setState(() {
      _dateTime = DateTime.now();

      setMonthPadding();
    });
  }

  void _previousMonthSelected() {
    setState(() {
      if (_dateTime.month == DateTime.january)
        _dateTime = new DateTime(_dateTime.year - 1, DateTime.december);
      else
        _dateTime = new DateTime(_dateTime.year, _dateTime.month - 1);

      setMonthPadding();
    });
  }

  void _nextMonthSelected() {
    setState(() {
      if (_dateTime.month == DateTime.december)
        _dateTime = new DateTime(_dateTime.year + 1, DateTime.january);
      else
        _dateTime = new DateTime(_dateTime.year, _dateTime.month + 1);

      setMonthPadding();
    });
  }

  void _onDayTapped(int day) {
    Navigator.push(context, new MaterialPageRoute(builder: (BuildContext context)
      => new EventsView(new DateTime(_dateTime.year, _dateTime.month, day)))
    );
  }

  void _onFabClicked() {
    Navigator.pushNamed(context, Constants.eventCreatorRoute);
  }

  @override
  Widget build(BuildContext context) {
    final int numWeekDays = 7;
    var size = MediaQuery.of(context).size;

    /*24 is for notification bar on Android*/
    /*28 is for weekday labels of the row*/
    // 55 is for iPhoneX clipping issue.
    final double itemHeight = (size.height - kToolbarHeight-kBottomNavigationBarHeight-24-28-55) / 6;
    final double itemWidth = size.width / numWeekDays;

    return new Scaffold(
        backgroundColor: Colors.white,
        appBar: new AppBar(
          title: new FittedBox(
                fit: BoxFit.contain,
                child: new Text(
                    getMonthName(_dateTime.month) + " " + _dateTime.year.toString(),
                  )
              ),
          actions: <Widget>[
            IconButton(
                icon: Icon(
                  Icons.today,
                  color: Colors.white,
                ),
              onPressed: _goToToday
            ),
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
                  value: _AppBarMenu.logout,
                  child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text('Logout', textAlign: TextAlign.center,),
                  ),
                )
              ],
            ),
          ],
        ),
        floatingActionButton: new FloatingActionButton(
          onPressed: _onFabClicked,
          child: new Icon(Icons.add),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.event), title: Text('Events')),
            BottomNavigationBarItem(icon: Icon(Icons.contacts), title: Text('Contacts')),
          ],
          currentIndex: 0,
          fixedColor: Colors.deepPurple,
          onTap: _onBottomBarItemTapped,
        ),
        body:
        new FutureBuilder(
            future: _getCalendarData(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return new LinearProgressIndicator();
                case ConnectionState.done:
                  return new Column(
                    children: <Widget>[
                      new Row(
                        children: <Widget>[
                          new Expanded(
                              child: new Text('S',
                                  textAlign: TextAlign.center,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .headline)),
                          new Expanded(
                              child: new Text('M',
                                  textAlign: TextAlign.center,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .headline)),
                          new Expanded(
                              child: new Text('T',
                                  textAlign: TextAlign.center,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .headline)),
                          new Expanded(
                              child: new Text('W',
                                  textAlign: TextAlign.center,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .headline)),
                          new Expanded(
                              child: new Text('T',
                                  textAlign: TextAlign.center,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .headline)),
                          new Expanded(
                              child: new Text('F',
                                  textAlign: TextAlign.center,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .headline)),
                          new Expanded(
                              child: new Text('S',
                                  textAlign: TextAlign.center,
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .headline)),
                        ],
                        mainAxisSize: MainAxisSize.min,
                      ),
                      new GridView.count(
                        crossAxisCount: numWeekDays,
                        childAspectRatio: (itemWidth / itemHeight),
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        children: List.generate(
                            getNumberOfDaysInMonth(_dateTime.month),
                                (index) {
                              int dayNumber = index + 1;
                              return new GestureDetector(
                                // Used for handling tap on each day view
                                  onTap: () =>
                                      _onDayTapped(
                                          dayNumber - _beginMonthPadding),
                                  child: new Container(
                                      margin: const EdgeInsets.all(2.0),
                                      padding: const EdgeInsets.all(1.0),
                                      decoration: new BoxDecoration(
                                          border: new Border.all(
                                              color: Colors.grey)),
                                      child: new Column(
                                        children: <Widget>[
                                          buildDayNumberWidget(dayNumber),
                                          buildDayEventInfoWidget(dayNumber)
                                        ],
                                      )));
                            }),
                      )
                    ],
                  );
                  break;
                default:
                  if (snapshot.hasError)
                    return new Text('Error: ${snapshot.error}');
                  else
                    return new Text('Result: ${snapshot.data}');
              }
            }
        )
    );
  }

  Align buildDayNumberWidget(int dayNumber) {
    //print('buildDayNumberWidget, dayNumber: $dayNumber');
    if ((dayNumber-_beginMonthPadding) == DateTime.now().day
        && _dateTime.month == DateTime.now().month
        && _dateTime.year == DateTime.now().year) {
      // Add a circle around the current day
      return Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: 35.0, // Should probably calculate these values
          height: 35.0,
          padding: EdgeInsets.all(5.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange,
            border: Border.all(),
          ),
          child: new Text(
            (dayNumber - _beginMonthPadding).toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.title,
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
          padding: EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 0.0),
          child: new Text(
            dayNumber <= _beginMonthPadding ? ' ' : (dayNumber - _beginMonthPadding).toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headline,
          ),
        ),
      );
    }
  }

  Widget buildDayEventInfoWidget(int dayNumber) {
    int eventCount = 0;
    DateTime eventDate;

    _userEventSnapshot.documents.forEach((doc) {
      eventDate = doc.data['time'];
      if (eventDate != null
          && eventDate.day == dayNumber - _beginMonthPadding
          && eventDate.month == _dateTime.month
          && eventDate.year == _dateTime.year) {
        eventCount++;
      }
    });

    if (eventCount > 0) {
        return new Expanded(
          child:
          FittedBox(
            alignment: Alignment.topLeft,
            fit: BoxFit.contain,
            child: new Text(
              "Events:$eventCount",
              maxLines: 1,
              style: new TextStyle(fontWeight: FontWeight.normal,
                  background: Paint()..color = Colors.amberAccent),
            ),
          ),
        );
    } else {
      return new Container();
    }
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
    return numDays + _beginMonthPadding;
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
      case _AppBarMenu.logout:
        await _auth.signOut();
        Navigator.of(context).pushNamedAndRemoveUntil(Constants.splashRoute, (Route<dynamic> route) => false);
        break;
    }
  }

  Future _onBottomBarItemTapped(int index) async {
    switch(index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, Constants.calContactsRoute);
        break;
    }
  }
}
