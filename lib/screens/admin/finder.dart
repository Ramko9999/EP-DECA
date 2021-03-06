import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deca_app/screens/admin/searcher.dart';
import 'package:deca_app/screens/db/databasemanager.dart';
import 'package:deca_app/utility/InheritedInfo.dart';
import 'package:deca_app/utility/format.dart';
import 'package:flutter/material.dart';

//Finder is a widget that will show search results of users based on names
class Finder extends StatefulWidget {
  Widget alert; //an alert widget to pop up when a card is tapped
  Function tapCallback; // a callback when a card is tapped
  Widget title;
  Widget subtitle;
  Widget trailing;

  Finder(Function t, {Widget a}) {
    this.alert = a;
    this.tapCallback = t;
  }

  State<Finder> createState() {
    return FinderState();
  }
}

class FinderState extends State<Finder> {
  final _fullName = TextEditingController();
  bool hasSearched = false;
  Map recentCardInfo;
  Map userDocs;
  ScrollController _listScroller = ScrollController();

  FinderState();

  //get the user documents
  void initalizeDocuments() async {
    DocumentSnapshot userData = await DataBaseManagement.userAggregator.get();
    Map userNames = userData.data['users'] as Map;
    setState(() => userDocs = userNames);
  }

  @override
  void initState() {
    super.initState();

    if (mounted) {
      initalizeDocuments();

      _fullName.addListener(() {
        setState(() => _listScroller.jumpTo(0.0));
      });
    }
  }

  void dispose() {
    _listScroller.dispose();
    _fullName.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final container = StateContainer.of(context);

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: <Widget>[
        Center(
          child: Container(
            width: screenWidth * .9,
            child: Column(children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                child: Row(children: <Widget>[
                  Expanded(
                    child: Container(
                      child: TextField(
                        controller: _fullName,
                        onTap: () {
                          _listScroller.jumpTo(0.0);
                        },
                        decoration: InputDecoration(labelText: "Full Name"),
                      ),
                    ),
                  ),
                ]),
              ),
              Flexible(
                  child: userDocs == null
                      ? CircularProgressIndicator()
                      : getList(context)),
            ]),
          ),
        ),

        if (container.isCardTapped)
          //this will most likely execute for gold points and never will execute for adding groups
          if (widget.alert != null)
            widget.alert //build alert widget
      ],
    );
  }

  //fetches the users in an order relevant way
  MaxList getData() {
    List<Map<dynamic, dynamic>> usersList = [];

    userDocs.forEach((k, v) {
      List nameList = k.toString().split(" ").toList();

      Map<String, dynamic> userData = {
        "first_name": nameList[0],
        "last_name": nameList[1],
        "uid": v.toString()
      };

      usersList.add(userData);
    });

    List nameList = _fullName.text.trim().split(" ");
    String firstName = nameList[0];
    String lastName = "";
    if (nameList.length == 2) {
      lastName = nameList[1];
    }

    Searcher searcher = new Searcher(usersList, firstName, lastName);
    MaxList relevanceList = searcher.search();
    return relevanceList;
  }

  //builds list
  Widget getList(BuildContext context) {
    double sW = MediaQuery.of(context).size.width;
    double sH = MediaQuery.of(context).size.height;
    MaxList list = getData();
    final infoContainer = StateContainer.of(context);

    Node current = list.head;

    return ListView.builder(
        controller: _listScroller,
        shrinkWrap: true,
        itemCount: list.getSize(),
        itemBuilder: (context, i) {
          if (list.getSize() == 0) {
            return CircularProgressIndicator();
          }
          if (current == null) {
            return CircularProgressIndicator();
          }

          Map userInfo = current.element['info'];
          ListTile c = ListTile(
            onTap: () {
              FocusScope.of(context)
                  .requestFocus(FocusNode()); //remove the keyboard

              //checking what the purpose of the finder is
              widget.tapCallback(context, infoContainer, userInfo);
            },
            leading: Icon(Icons.person, color: Colors.black),
            title: Text(
              userInfo['first_name'].toString() +
                  " " +
                  userInfo['last_name'].toString(),
              style: TextStyle(
                  fontFamily: 'Lato', fontSize: Sizer.getTextSize(sW, sH, 20)),
            ),
          );

          current = current.next;
          return c;
        });
  }
}

class ManualEnterPopup extends StatefulWidget {
  ManualEnterPopup();
  State<ManualEnterPopup> createState() {
    return ManualEnterPopupState();
  }
}

class ManualEnterPopupState extends State<ManualEnterPopup> {
  TextEditingController pointController = new TextEditingController();
  Map userData;

  ManualEnterPopupState() {
    pointController.text = 0.toString();
  }

  Widget build(BuildContext context) {
    final container = StateContainer.of(context);
    userData = container.userData;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Container(
        width: screenWidth * 0.7,
        height: screenHeight * 0.5,
        child: AlertDialog(
          title: AutoSizeText(
            "Add GP to " + userData['first_name'],
            maxLines: 1,
          ),
          content: Container(
            child: TextField(
              style: TextStyle(fontFamily: 'Lato'),
              textAlign: TextAlign.center,
              decoration: new InputDecoration(
                labelText: "GP",
                border: new OutlineInputBorder(
                  borderRadius: new BorderRadius.circular(10.0),
                  borderSide: new BorderSide(color: Colors.blue),
                ),
              ),
              keyboardType: TextInputType.number,
              controller: pointController,
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("Submit", style: TextStyle(color: Colors.blue)),
              onPressed: () async {
                String userUID = userData['uid'];
                int points = int.parse(pointController.text);
                if (points > 0) {
                  container.updateGP(userUID, points);

                  await Firestore.instance
                      .collection("Events")
                      .document(container.eventMetadata['event_name'])
                      .updateData({
                    "attendees": FieldValue.arrayUnion(
                        ["${userData['first_name']} ${userData['last_name']}"])
                  });
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text(
                      "Succesfully added ${points.toString()} to ${userData['first_name']}",
                      style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize:
                              Sizer.getTextSize(screenWidth, screenHeight, 20),
                          color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                  ));
                  container.setIsCardTapped(false);
                  container.setIsManualEnter(false);
                } else {
                  pointController.text = 0.toString();
                  //alert the user to enter a non negative value
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text(
                      "Enter a non negative value",
                      style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize:
                              Sizer.getTextSize(screenWidth, screenHeight, 20),
                          color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ));
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
