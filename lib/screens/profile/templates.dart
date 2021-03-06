import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deca_app/utility/InheritedInfo.dart';
import 'package:deca_app/utility/format.dart';
import 'package:deca_app/utility/global.dart';
import 'package:deca_app/utility/transition.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class DynamicProfileUI extends StatelessWidget {
  String _uid;
  int _goldPoints;
  String _memberLevel;
  bool _isEditable = false;
  String firstName;
 

  DynamicProfileUI(String uid, {bool editable}) {
    this._uid = uid;
    if (editable != null) {
      this._isEditable = editable;
    }
  }

  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double pixelTwoWidth = 411.42857142857144;
    double pixelTwoHeight = 683.4285714285714;

    return StreamBuilder(
        //connecting to firebase and gathering user data
        stream: Firestore.instance
            .collection('Users').document(_uid)
            .snapshots(),
        builder: (context, snapshot) {
          //if data has been updated
          if (snapshot.hasData) {
            
            //grab the data and populate the fields as such
            DocumentSnapshot userInfo = snapshot.data;
            
            //there is only one case in which isEditable will be false and that will be the case when it is the actual user of the app

              firstName = userInfo.data['first_name'];
             

            _goldPoints = userInfo.data['gold_points'];
            //setting memberLevel based on gold points
            if (_goldPoints < 75) {
              _memberLevel = "N/A";
            } else if (_goldPoints < 125) {
              _memberLevel = "Member";
            } else if (_goldPoints < 200) {
              _memberLevel = "Silver";
            } else {
              _memberLevel = "Gold";
            }

            //setting the new UI
            return Center(
                child: Column(
              children: <Widget>[
                if (!_isEditable)
                  Container(
                    padding: new EdgeInsets.fromLTRB(screenWidth / 20,
                        screenHeight / 40, screenWidth / 20, screenHeight / 80),
                    width: double.infinity,
                    child: Text(
                      "Hello " + firstName + '.',
                      textAlign: TextAlign.left,
                      style: new TextStyle(
                          fontSize: 36 * screenWidth / pixelTwoWidth,
                          fontFamily: 'Lato-Regular'),
                    ),
                  ),
                Container(
                    height: screenHeight * 0.59,
                    width: screenWidth * 0.95,
                    child: ListView(
                      children: <Widget>[
                        Card(
                            child: ListTile(
                          leading: Icon(Icons.stars,
                              color: Color.fromARGB(255, 249, 166, 22)),
                          title: Text('Gold Points',
                              textAlign: TextAlign.left,
                              style: new TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20 * screenWidth / pixelTwoWidth)),
                          subtitle: Text(
                            'Click to view attended events!',
                            style: TextStyle(
                                fontSize: 16 * screenWidth / pixelTwoWidth),
                          ),
                          onTap: () => Navigator.push(
                              context,
                              NoTransition(
                                  builder: (context) => new GPInfoScreen(_uid,
                                      editable: _isEditable))),
                          trailing: Text(
                            _goldPoints.toString(),
                            textAlign: TextAlign.center,
                            style: new TextStyle(
                                fontSize: 20 * screenWidth / pixelTwoWidth,
                                color: Color.fromARGB(255, 249, 166, 22)),
                          ),
                        )),
                        Card(
                            child: ListTile(
                          
                          leading: Icon(MdiIcons.accountBadge,
                              color: (_memberLevel == 'Member')
                                  ? Colors.blueAccent
                                  : (_memberLevel == 'Silver')
                                      ? Colors.blueGrey
                                      : (_memberLevel == 'Gold')
                                          ? Color.fromARGB(255, 249, 166, 22)
                                          : Colors.black),
                          title: Text('Member Status',
                              textAlign: TextAlign.left,
                              style: new TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20 * screenWidth / pixelTwoWidth)),
                          subtitle: !_isEditable
                              ? (_memberLevel == 'N/A')
                                  ? Text(
                                      (75 - _goldPoints).toString() +
                                          ' GP until you\'re a member!',
                                      style: TextStyle(
                                          fontSize:
                                              16 * screenWidth / pixelTwoWidth),
                                    )
                                  : (_memberLevel == 'Member')
                                      ? Text(
                                          (125 - _goldPoints).toString() +
                                              ' GP until you\'re a SILVER member!',
                                          style: TextStyle(
                                              fontSize: 16 *
                                                  screenWidth /
                                                  pixelTwoWidth),
                                        )
                                      : (_memberLevel == 'Silver')
                                          ? Text(
                                              (200 - _goldPoints).toString() +
                                                  ' GP until you\'re a GOLD member!',
                                              style: TextStyle(
                                                  fontSize: 16 *
                                                      screenWidth /
                                                      pixelTwoWidth),
                                            )
                                          : null
                              : null,
                          trailing: Text(
                            _memberLevel,
                            textAlign: TextAlign.center,
                            style: new TextStyle(
                                fontSize: 20 * screenWidth / pixelTwoWidth,
                                color: (_memberLevel == 'Member')
                                    ? Colors.blueAccent
                                    : (_memberLevel == 'Silver')
                                        ? Colors.blueGrey
                                        : (_memberLevel == 'Gold')
                                            ? Color.fromARGB(255, 249, 166, 22)
                                            : Colors.black),
                          ),
                        )),
                        Card(
                          child: ListTile(
                            leading: Icon(Icons.group, color: Colors.lightBlue),
                            title: Text('List of Groups',
                                textAlign: TextAlign.left,
                                style: new TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        20 * screenWidth / pixelTwoWidth)),
                            subtitle: Text(
                              'Click to view groups!',
                              style: TextStyle(
                                  fontSize: 16 * screenWidth / pixelTwoWidth),
                            ),
                            onTap: () => Navigator.push(
                                context,
                                NoTransition(
                                    builder: (context) =>
                                        new GroupInfoScreen(
                                          _uid,
                                          editable: _isEditable,
                                        ))),
                          ),
                        )
                      ],
                    )),
              ],
            ));
          } else {
            return Container(
                alignment: Alignment.center,
                child: Column(
                  children: <Widget>[
                    Text(
                      "Connecting...",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 32 * screenWidth / pixelTwoWidth,
                      ),
                    ),
                    CircularProgressIndicator()
                  ],
                ));
          }
        });
  }
}

class GroupInfoScreen extends StatefulWidget {
  String _uid;
  bool _isEditable;
  GroupInfoScreen(String u, {bool editable}) {
    this._uid = u;
    if (editable != null) {
      this._isEditable = editable;
    }
  }
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return GroupInfoScreenState();
  }
}

class GroupInfoScreenState extends State<GroupInfoScreen> {
  List committeeList;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  ListView _buildEventList(context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double pixelTwoWidth = 411.42857142857144;
    double pixelTwoHeight = 683.4285714285714;

    return ListView.builder(
        // Must have an item count equal to the number of items!
        itemCount: committeeList.length,
        // A callback that will return a widget.
        itemBuilder: (context, i) {
          String groupName = committeeList[i];
          Card group = Card(
            child: ListTile(
              leading: Icon(Icons.group, color: Colors.blue),
              title: Text(groupName,
                  textAlign: TextAlign.left,
                  style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20 * screenWidth / pixelTwoWidth)),
            ),
          );

          //checks whether the committies are the app user's
          if (widget._isEditable) {
            return Dismissible(
                key: UniqueKey(),
                child: group,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.0),
                  color: Colors.red,
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (dismiss) {
                  List newList = [];
                  for (String comm in committeeList) {
                    if (comm != groupName) {
                      newList.add(comm);
                    }
                  }

                  String firstName = StateContainer.of(context).userData['first_name'];
                  String lastName = StateContainer.of(context).userData['last_name'];
                  String fullName = "$firstName $lastName";

                  //remove group from users
                  Firestore.instance
                      .collection('Users')
                      .document(widget._uid)
                      .updateData({'groups': newList}).whenComplete(() async {

                        //remove the users from the group
                        await Firestore.instance.collection("Groups").document(groupName).updateData({"members": FieldValue.arrayRemove([fullName])});
                    _scaffoldKey.currentState.showSnackBar(
                      SnackBar(
                        content: Text(
                          "$firstName removed from $groupName",
                          style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: Sizer.getTextSize(
                                  screenWidth, screenHeight, 18),
                              color: Colors.white),
                        ),
                        duration: Duration(milliseconds: 250),
                      ),
                    );
                  });
                });
          } else {
            return group;
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double pixelTwoWidth = 411.42857142857144;
    double pixelTwoHeight = 683.4285714285714;

    // TODO: implement build
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: !widget._isEditable
            ? Text('Groups')
            : AutoSizeText(
                'Editing ${StateContainer.of(context).userData['first_name']}\'s Groups',
                maxLines: 1),
      ),
      body: Column(
        children: <Widget>[
          StreamBuilder(
              stream: Firestore.instance
                  .collection('Users')
                  .document(widget._uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasData) {
                  
                  DocumentSnapshot userSnap = userSnapshot.data;
                  List commList = userSnap.data['groups'];
                  committeeList = commList;
                  bool isEmpty = commList.isEmpty;
                  return Center(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                      height: screenHeight * 0.7,
                      width: screenWidth * 0.9,
                      child: (isEmpty)
                          ? Text(
                              "Not In Any Groups!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "Lato",
                                color: Colors.black,
                                fontSize: 15 * screenWidth / pixelTwoWidth,
                              ),
                            )
                          : _buildEventList(context),
                    ),
                  );
                } else {
                  return Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: <Widget>[
                          Text(
                            "Connecting...",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: "Lato",
                              color: Colors.grey,
                              fontSize: 32 * screenWidth / pixelTwoWidth,
                            ),
                          ),
                          CircularProgressIndicator()
                        ],
                      ));
                }
              })
        ],
      ),
    );
  }
}

class GPInfoScreen extends StatefulWidget {
  String _uid;
  bool _isEditable;

  GPInfoScreen(String uid, {bool editable}) {
    this._uid = uid;
    if (editable != null) {
      this._isEditable = editable;
    }
  }

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return GPInfoScreenState();
  }
}

//a screen that shows the events and gold point values a person has
class GPInfoScreenState extends State<GPInfoScreen> {
  List<EventObject> eventList;
  String filterType;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  ListView _buildEventList(context, eventSnapshot, userSnapshot) {
    double sW = MediaQuery.of(context).size.width;
    double sH = MediaQuery.of(context).size.height;
    final infoContainer = StateContainer.of(context);

    eventList = filter(eventSnapshot, userSnapshot);

    return ListView.builder(
      // Must have an item count equal to the number of items!
      itemCount: eventList.length,
      // A callback that will return a widget.
      itemBuilder: (context, i) {
        
        DocumentSnapshot event = eventList[i].info;

        //event data
        Card eventDataCard = Card(
          color: eventList[i].eventColor,
          child: ListTile(
            title: Text(event['event_name'],
                textAlign: TextAlign.left,
                style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Sizer.getTextSize(sW, sH, 20))),
            subtitle: Text(event['event_type']),
            trailing: Text(eventList[i].gp.toString(),
                textAlign: TextAlign.center,
                style: new TextStyle(
                    fontSize: Sizer.getTextSize(sW, sH, 20),
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
          ),
        );

        //used to in order to prevent user for deleting their own events
        if (widget._isEditable) {
          
          return Dismissible(
            key: UniqueKey(),
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20.0),
              color: Colors.red,
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            child: eventDataCard,
            onDismissed: (dissmiss) async {
              Map newMap = {};
              for (EventObject eventItem in eventList) {
           
                if (eventItem.info['event_name'] != event['event_name']) {
                  newMap.addAll({eventItem.info['event_name']: eventItem.gp});
                }
              }

            String fullName = "${StateContainer.of(context).userData['first_name']} ${StateContainer.of(context).userData['last_name']}";
              //remove the attendees from the
             await event.reference.updateData({'attendees': FieldValue.arrayRemove([fullName])});
              
              Firestore.instance.collection('Users')
                  .document(widget._uid)
                  .updateData({'events': newMap}).whenComplete(() {
                infoContainer.syncGPWithEvents(widget._uid);
                infoContainer.decrementAttendees(event['event_name']);

                _scaffoldKey.currentState.showSnackBar(
                  SnackBar(
                    content: Text(
                      "${event['event_name']} removed from ${infoContainer.userData['first_name']} ",
                      style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: Sizer.getTextSize(sW, sH, 18),
                          color: Colors.white),
                    ),
                    duration: Duration(milliseconds: 250),
                  ),
                );
              });
            },
          );
        } else {
          return eventDataCard;
        }
      },
    );
  }

  List<EventObject> filter(eventSnapshot, DocumentSnapshot userSnapshot) {
    List<EventObject> eventList = [];
    Map userMetadata = userSnapshot.data as Map;

    if (userMetadata.isNotEmpty) {
      for (DocumentSnapshot event in eventSnapshot) {
        for (String userEvent in userMetadata['events'].keys) {
          if (event['event_name'] == userEvent) {
            if (event['enter_type'] == "ME") {
              eventList.add(
                  new EventObject(event, userMetadata['events'][userEvent]));
            } else {
              eventList.add(new EventObject(event));
            }
          }
        }
      }

      eventList.sort();
      if (filterType == 'eventType') {
        Map<String, List<EventObject>> eventSortedList = {
          'Meeting': [],
          'Social': [],
          'Event': [],
          'Competition': [],
          'Committee': [],
          'Cookie Store': [],
          'Miscellaneous': [],
        };
        for (EventObject element in eventList) {
          eventSortedList[element.eventType].add(element);
        }
        List<EventObject> finalEventSortedList = [];
        for (List<EventObject> value in eventSortedList.values) {
          if (value != []) {
            finalEventSortedList.addAll(value);
          }
        }
        return finalEventSortedList;
      }
    }
    return eventList;
  }

  @override
  Widget build(BuildContext context) {
    final container = StateContainer.of(context);
    String _uid = widget._uid;
    filterType = container.filterType;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double pixelTwoWidth = 411.42857142857144;
    double pixelTwoHeight = 683.4285714285714;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(!widget._isEditable
            ? 'Events Attended'
            : 'Editing ${container.userData['first_name']}\'s Events'),
      ),
      body: Column(
        children: <Widget>[
          Center(
            child: Container(
              alignment: Alignment.topCenter,
              child: ActionChip(
                  avatar: (filterType == null)
                      ? Icon(Icons.event)
                      : (filterType == 'date')
                          ? Icon(Icons.event)
                          : Icon(Icons.access_time),
                  label: (filterType == null)
                      ? Text('Filter by Event Type')
                      : (filterType == 'date')
                          ? Text('Filter by Event Type')
                          : Text('Filter Chronologically'),
                  onPressed: () {
                    if (filterType == null || filterType == 'date') {
                      container.setFilterType('eventType');
                    } else {
                      container.setFilterType('date');
                    }
                  }),
            ),
          ),
          StreamBuilder(
              stream: Firestore.instance.collection('Events').snapshots(),
              builder: (context, eventSnapshot) {
                
                if (eventSnapshot.hasData) {
                  List<DocumentSnapshot> eventSnap =
                      eventSnapshot.data.documents;
                  return StreamBuilder(
                      stream: Firestore.instance
                          .collection('Users').document(_uid)
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.hasData) {
                          DocumentSnapshot userSnap =
                              userSnapshot.data;
                          Map eventList = userSnap.data['events'] as Map;
                          bool isEmpty = eventList.isEmpty;
                          return Center(
                            child: Container(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                              height: screenHeight * 0.7,
                              width: screenWidth * 0.9,
                              child: (isEmpty)
                                  ? Text(
                                      "No Events Attended!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: "Lato",
                                        color: Colors.black,
                                        fontSize:
                                            15 * screenWidth / pixelTwoWidth,
                                      ),
                                    )
                                  : _buildEventList(
                                      context, eventSnap, userSnap),
                            ),
                          );
                        } else {
                          return Container(
                              alignment: Alignment.center,
                              child: Column(
                                children: <Widget>[
                                  Text(
                                    "Connecting...",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: "Lato",
                                      color: Colors.grey,
                                      fontSize:
                                          32 * screenWidth / pixelTwoWidth,
                                    ),
                                  ),
                                  CircularProgressIndicator()
                                ],
                              ));
                        }
                      });
                } else {
                  return Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: <Widget>[
                          Text(
                            "Connecting...",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: "Lato",
                              color: Colors.grey,
                              fontSize: 32 * screenWidth / pixelTwoWidth,
                            ),
                          ),
                          CircularProgressIndicator()
                        ],
                      ));
                }
              }),
        ],
      ),
    );
  }
}

class EventObject implements Comparable<EventObject> {
  final DocumentSnapshot info;
  DateTime eventDate;
  Color eventColor;
  int gp;
  String eventType;

  final Map<String, Color> eventColors = {
    'Meeting': Colors.blueAccent,
    'Social': Colors.orange,
    'Event': Colors.tealAccent,
    'Competition': Colors.lightGreenAccent,
    'Committee': Colors.redAccent,
    'Cookie Store': Colors.yellowAccent,
    'Miscellaneous': Colors.grey
  };

  EventObject(this.info, [this.gp]) {
    eventType = info['event_type'];
    eventDate = DateTime.parse(info['event_date']);
    eventColor = eventColors[info['event_type']];
    if (this.gp == null) {
      this.gp = info['gold_points'];
    }
  }

  int compareTo(EventObject other) {
    int order = eventDate.compareTo(other.eventDate);
    return order;
  }
}
