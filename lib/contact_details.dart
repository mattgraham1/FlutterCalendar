import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_app/gift_creator.dart';
import 'package:flutter_widget_app/global_contants.dart';

class ContactDetails extends StatefulWidget {
  final String name;
  final String userDocumentId;
  final String contactDocumentId;
  
  ContactDetails({this.name, this.userDocumentId, this.contactDocumentId});
  
  @override
  State<StatefulWidget> createState() {
    return new _ContactDetailsState(name, userDocumentId, contactDocumentId);
  }
}

class _ContactDetailsState extends State<ContactDetails> {
  final String _name;
  final String _userDocumentId;
  final String _contactDocumentId;

  _ContactDetailsState(this._name, this._userDocumentId, this._contactDocumentId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: new AppBar(
        leading: new BackButton(),
        title: Hero(
          tag: _name,
          child: new Text(_name + ' ' + 'History', style: Theme.of(context).textTheme.title.copyWith(color: Colors.white)),
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _onFabClicked,
        child: new Icon(Icons.add),
      ),
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
                    ],),
                    trailing: new IconButton(
                        iconSize: 30.0,
                        padding: EdgeInsets.all(5.0),
                        icon: new Icon(Icons.delete),
                        color: Colors.black,
                        onPressed: () => _deleteContact(giftDocument)),
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
        .document(_userDocumentId)
        .collection(Constants.calendarContactsCollectionId)
        .document(_contactDocumentId)
        .collection(Constants.contactGiftsCollectionId)
        .getDocuments();

    return snapshot;
  }

  Future _deleteContact(DocumentSnapshot giftDocument) async {
    setState(() {
      Firestore.instance.collection(Constants.usersCollectionId)
          .document(_userDocumentId)
          .collection(Constants.calendarContactsCollectionId)
          .document(_contactDocumentId)
          .collection(Constants.contactGiftsCollectionId)
          .document(giftDocument.documentID)
          .delete();
    });
  }

  void _onFabClicked() {
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return GiftCreator(userDocumentId: _userDocumentId, userContactDocumentId: _contactDocumentId);
    }));
  }
}