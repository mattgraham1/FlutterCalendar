import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_app/contact_creator.dart';
import 'package:flutter_widget_app/contact_details.dart';
import 'package:flutter_widget_app/global_contants.dart';

class CalendarContacts extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _CalendarContactsState();
  }
}

class _CalendarContactsState extends State<CalendarContacts> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _usersCollectionId = 'users';
  final String _calContactsCollectionId = 'contacts';

  FirebaseUser _currentUser;
  String _userDocumentId;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      backgroundColor: Colors.white,
      appBar: new AppBar(
        leading: new BackButton(),
        title: new Text('Contacts'),
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
        currentIndex: 1,
        fixedColor: Colors.deepPurple,
        onTap: _onBottomBarItemTapped,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _getUserContacts(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError)
            return new Text('${snapshot.error}');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(child: new CircularProgressIndicator());
            default:
              return _buildListView(snapshot);
          }
        },
      ),
    );
  }

  Future<String> _getUserDocumentId() async {
    QuerySnapshot snapshot = await Firestore.instance.collection(_usersCollectionId)
        .where('email', isEqualTo: _currentUser.email).getDocuments();

    _userDocumentId = snapshot?.documents?.elementAt(0)?.documentID;

    return _userDocumentId;
  }

  Future<QuerySnapshot> _getUserContacts() async {
    _currentUser = await _auth.currentUser();
    await _getUserDocumentId();
    QuerySnapshot snapshot = await Firestore.instance.collection(_usersCollectionId)
        .document(_userDocumentId)
        .collection(_calContactsCollectionId)
        .getDocuments();

    return snapshot;
  }

  ListView _buildListView (AsyncSnapshot<QuerySnapshot> snapshot) {
    return ListView.builder(
      itemCount: snapshot?.data?.documents?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        final contactDocument = snapshot?.data?.documents?.elementAt(index);
        final String _name = contactDocument.data['name'];
        return ListTile(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) {
              return ContactDetails(name: _name, userDocumentId: _userDocumentId, contactDocumentId: contactDocument?.documentID);
            }));
          },
          leading: CircleAvatar(
              child: Text(_name.length > 1
                  ? _name?.substring(0, 2)
                  : "")),
          title: Hero(tag: _name, child: Text(_name, style: Theme.of(context).textTheme.title)),
          trailing: new IconButton(
              iconSize: 30.0,
              padding: EdgeInsets.all(5.0),
              icon: new Icon(Icons.delete),
              color: Colors.black,
              onPressed: () => _deleteContact(contactDocument)),
        );
      },
    );
  }

  Future _onBottomBarItemTapped(int index) async {
    switch(index) {
      case 0:
        Navigator.pushNamed(context, '/calendar');
        break;
      case 1:
        break;
    }
  }

  void _onFabClicked() {
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return ContactCreator(userDocumentId: _userDocumentId);
    }));
  }

  void _deleteContact(DocumentSnapshot contactDocument) {
    setState(() {
      Firestore.instance.collection(Constants.usersCollectionId)
          .document(_userDocumentId)
          .collection(Constants.calendarContactsCollectionId)
          .document(contactDocument.documentID)
          .delete();
    });
  }
}