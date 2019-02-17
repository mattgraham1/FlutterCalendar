import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_app/global_contants.dart';

class GiftCreator extends StatefulWidget {
  final String userDocumentId;
  final String userContactDocumentId;

  GiftCreator({this.userDocumentId, this.userContactDocumentId});

  @override
  State<StatefulWidget> createState() {
    return new _GiftCreatorState();
  }
}

class _GiftCreatorState extends State<GiftCreator> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _giftName;
  int _giftCost;

  @override
  Widget build(BuildContext context) {
    final giftNameWidget = new TextFormField(
      keyboardType: TextInputType.text,
      decoration: new InputDecoration(
          hintText: 'Gift Card',
          labelText: 'Gift Name',
          contentPadding: EdgeInsets.all(16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          )
      ),
      style: Theme.of(context).textTheme.headline,
      validator: (value) {
        if(value.isEmpty) {
          return 'Please enter a gift name.';
        }
      },
      onSaved: (String value) => this._giftName = value,
    );

    final giftCostWidget = new TextFormField(
      keyboardType: TextInputType.number,
      decoration: new InputDecoration(
          hintText: '25',
          labelText: 'Gift Amount',
          contentPadding: EdgeInsets.all(16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          )
      ),
      style: Theme.of(context).textTheme.headline,
      validator: (value) {
        if(value.isEmpty) {
          return 'Please enter a gift amount.';
        }
      },
      onSaved: (String value) => this._giftCost = int.parse(value),
    );

    return Scaffold(
      appBar: new AppBar(
        leading: new BackButton(),
        title: new Text('Create New Gift'),
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
                giftNameWidget,
                SizedBox(height: 8.0),
                giftCostWidget,
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
          .document(widget.userContactDocumentId)
          .collection(Constants.contactGiftsCollectionId)
          .document(null)
          .setData({'name': _giftName, 'cost': _giftCost});

      Navigator.maybePop(context);
    } else {
      print('Error validating data and saving to firestore.');
    }
  }

}