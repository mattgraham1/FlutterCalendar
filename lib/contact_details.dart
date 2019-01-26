import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_app/global_contants.dart';

class ContactDetails extends StatelessWidget {
  final String name;
  final String userDocumentId;
  final String contactDocumentId;

  ContactDetails({this.name, this.userDocumentId, this.contactDocumentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        leading: new BackButton(),
        title: Hero(
          tag: name,
          child: new Text(name + ' ' + 'History', style: Theme.of(context).textTheme.title.copyWith(color: Colors.white)),
        ),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<QuerySnapshot>(
        future: _getContactGifts(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError)
            return new Text('${snapshot.error}');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return new Center(child: new CircularProgressIndicator());
            default:
              return ListView.separated(
                separatorBuilder: (context, index) => Divider(
                  color: Colors.black,
                ),
                itemCount: snapshot?.data?.documents?.length ?? 0,
                itemBuilder: (BuildContext context, int index) {
                  final giftDocument = snapshot?.data?.documents?.elementAt(index);
                  final String _name = giftDocument.data['name'];
                  final int _cost = giftDocument.data['cost'];
                  return ListTile(
                    onTap: () {
                      print('gift list item clicked.');
                    },
                    leading: CircleAvatar(
                        backgroundColor: Colors.orangeAccent,
                        child: new IconButton(
                            iconSize: 25.0,
                            padding: EdgeInsets.all(5.0),
                            icon: new Icon(Icons.card_giftcard, color: Colors.black,),
                        )),
                    title: Row(children: <Widget>[
                      Expanded(child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Gift: ' + _name, style: Theme.of(context).textTheme.title),
                          Text('Cost: ' + _cost.toString(), style: Theme.of(context).textTheme.title,),
                        ],
                      )),
                    ],)
                  );
                },
              );
          }
        },
      ),
    );
  }

  Future<QuerySnapshot> _getContactGifts() async {
    QuerySnapshot snapshot = await Firestore.instance.collection(Constants.usersCollectionId)
        .document(userDocumentId)
        .collection(Constants.calendarContactsCollectionId)
        .document(contactDocumentId)
        .collection(Constants.contactGiftsCollectionId)
        .getDocuments();

    return snapshot;
  }
}