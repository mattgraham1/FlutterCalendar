import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_app/global_contants.dart';

class ContactCreator extends StatefulWidget {
  final String userDocumentId;

  ContactCreator({this.userDocumentId});

  @override
  State<StatefulWidget> createState() {
    return new _ContactCreateState();
  }
}

class _ContactCreateState extends State<ContactCreator> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _contactName;

  @override
  Widget build(BuildContext context) {

    final contactNameWidget = new TextFormField(
      keyboardType: TextInputType.text,
      decoration: new InputDecoration(
          hintText: 'Fred Flinstone',
          labelText: 'Contact Name',
          contentPadding: EdgeInsets.all(16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          )
      ),
      style: Theme.of(context).textTheme.headline,
      validator: (value) {
          if(value.isEmpty) {
            return 'Please enter a name.';
          }
      },
      onSaved: (String value) => this._contactName = value,
    );

    return Scaffold(
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
              onTap: () => _saveNewContact(context),
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
                contactNameWidget,
              ],
            ),
          )),
    );
  }

  _saveNewContact(BuildContext context) async {
    FirebaseUser currentUser = await _auth.currentUser();

    if (currentUser != null && this._formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.

      Firestore.instance.collection(Constants.usersCollectionId)
          .document(widget.userDocumentId)
          .collection(Constants.calendarContactsCollectionId)
          .document(null)
          .setData({'name': _contactName});

      Navigator.maybePop(context);
    } else {
      print('Error validating data and saving to firestore.');
    }
  }
}