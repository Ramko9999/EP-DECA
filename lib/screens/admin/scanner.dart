import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deca_app/utility/InheritedInfo.dart';
import 'package:deca_app/utility/format.dart';
import 'package:deca_app/utility/notifiers.dart';
import 'package:deca_app/utility/transition.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'events.dart';
import 'finderscreen.dart';

class Scanner extends StatefulWidget {
  State<Scanner> createState() {
    return _ScannerState();
  }
}

class _ScannerState extends State<Scanner> {
  CameraController _mainCamera; //camera that will give us the feed
  bool _isCameraInitalized = false;
  Map eventMetadata;
  int pointVal;
  int scanCount;
  bool isInfo = false;
  bool _cameraPermission = true;
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool isManualEnter;
  StreamController _processor = StreamController();
  Queue<String> barcodeQueue = Queue();

  //handles running the actual scanner camera stream
  void runStream() {
    _mainCamera.startImageStream((image) async {
      FirebaseVisionImageMetadata metadata;

      //metadata tag for the for image format.
      //source https://github.com/flutter/flutter/issues/26348
      metadata = FirebaseVisionImageMetadata(
          rawFormat: image.format.raw,
          size: Size(image.width.toDouble(), image.height.toDouble()),
          planeData: image.planes
              .map((plane) => FirebaseVisionImagePlaneMetadata(
                  bytesPerRow: plane.bytesPerRow,
                  height: plane.height,
                  width: plane.width))
              .toList());

      FirebaseVisionImage visionImage =
          FirebaseVisionImage.fromBytes(image.planes[0].bytes, metadata);

      List<Barcode> barcodes = await FirebaseVision.instance
          .barcodeDetector()
          .detectInImage(visionImage);

      for (Barcode barcode in barcodes) {
        /*
          Using the length and last element o fthe barcodeQueue to print multiple snackbars from showing up
          */
        if (barcodeQueue.length != 0) {
          //check whether the scanned element is the same as the last element in queue so spam doesn't occur
          if (barcodeQueue.last != barcode.rawValue) {
            barcodeQueue.add(barcode.rawValue);
            _processor.add(barcode.rawValue);
          } else {
            print("Barcode has already been scanned");
          }
        } else {
          barcodeQueue.add(barcode.rawValue);
          _processor.add(barcode.rawValue);
        }
      }
    });
  }

  //get a list of permissions that are still denied
  Future<List> getPermissionsThatNeedToBeChecked(
      PermissionGroup cameraPermission,
      PermissionGroup microphonePermission) async {
    PermissionStatus cameraPermStatus =
        await PermissionHandler().checkPermissionStatus(cameraPermission);
    PermissionStatus microphonePermStatus =
        await PermissionHandler().checkPermissionStatus(microphonePermission);

    List<PermissionGroup> stillNeedToBeGranted = [];

    if (cameraPermStatus == PermissionStatus.denied) {
      stillNeedToBeGranted.add(cameraPermission);
    }

    if (microphonePermStatus == PermissionStatus.denied) {
      stillNeedToBeGranted.add(microphonePermission);
    }

    return stillNeedToBeGranted;
  }

  //create camera based on permissions
  void createCamera() async {
    List<PermissionGroup> permList = await getPermissionsThatNeedToBeChecked(
        PermissionGroup.camera, PermissionGroup.microphone);

    if (permList.length == 0) {
      
      //get all the avaliable cameras
      availableCameras().then((allCameras) {
        _mainCamera = CameraController(allCameras[0], ResolutionPreset.low);

        _mainCamera.initialize().then((_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _isCameraInitalized = true;
          }); //show the actual camera

          runStream();

          _processor.stream.listen((onData) async {
            final gpContainer = StateContainer.of(
                _scaffoldKey.currentContext); //This is actually smart as hell

            DocumentSnapshot userSnapshot = await Firestore.instance
                .collection("Users")
                .document(onData)
                .get();
            
            String firstName = userSnapshot.data['first_name'];
            String lastName = userSnapshot.data['last_name'];
           
           await Firestore.instance.collection("Events").document(gpContainer.eventMetadata['event_name']).updateData(
             {'attendees': FieldValue.arrayUnion(["$firstName $lastName"])}
           );

            gpContainer.setUserData(userSnapshot.data);
            gpContainer.updateGP(onData);

            //show scaffold here
            _scaffoldKey.currentState.showSnackBar(SnackBar(
                backgroundColor: Color.fromRGBO(46, 204, 113, 1),
                content: Text("Scanned " + firstName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Lato',
                        color: Colors.white,
                        fontSize: Sizer.getTextSize(
                            MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height,
                            18))),
                duration: Duration(milliseconds: 500)));
          });
        }).catchError((onError) {
          //permission denied
          if (onError.toString().contains("permission not granted")) {
            setState(() {
              _cameraPermission = false;
            });
          }
        });
      });
    } else {
      setState(() {
        _cameraPermission = false;
      });
    }
  }

  //request permissions and check until all are requestsed
  void requestPermStatus(List<PermissionGroup> permissionGroups) {
    bool allAreAccepted = true;
    PermissionHandler()
        .requestPermissions(permissionGroups)
        .then((permissionResult) {
      permissionResult.forEach((k, v) {
        if (v == PermissionStatus.denied) {
          allAreAccepted = false;
        }
      });
      if (allAreAccepted) {
        setState(() {
          _cameraPermission = true;
        });
        createCamera();
      }
    });
  }

  void initState() {
    super.initState();
    createCamera();
  }

  void dispose() {
    if (_mainCamera != null) {
      _mainCamera.dispose();
    }

    super.dispose();
  }

  Widget build(BuildContext context) {
    final container = StateContainer.of(context);
    eventMetadata = container.eventMetadata;
    isManualEnter = container.isManualEnter;

    //check first whether camera is init
    if (_isCameraInitalized) {
      //check whether camera is already is streaming images
      if (!_mainCamera.value.isStreamingImages) {
        runStream();
      }
      //if there is an error, then stop the stream
      else if (StateContainer.of(context).isThereConnectionError) {
        _mainCamera.stopImageStream();
      }
    }

    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    pointVal = eventMetadata['gold_points'];
    return Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: AutoSizeText(
            "Add Members to \'" + eventMetadata['event_name'] + "\'",
            maxLines: 1,
          ),
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () => {Navigator.of(context).pop()}),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                setState(() {
                  isInfo = true;
                });
              },
            ),
          ],
        ),
        body: Stack(children: <Widget>[
          SingleChildScrollView(
            child: Center(
              child: Column(
                children: <Widget>[
                  Center(
                    child: Container(
                      alignment: Alignment.topCenter,
                      child: ActionChip(
                          avatar: Icon(Icons.search),
                          label: Text('Add with Search'),
                          onPressed: () {
                            changeToSearcher(context);
                          }),
                    ),
                  ),
                  Container(
                    height: screenHeight * 0.75,
                    width: screenWidth * 0.9,
                    child: _cameraPermission
                        ? _isCameraInitalized
                            ? Platform.isAndroid
                                ? RotationTransition(
                                    child: CameraPreview(_mainCamera),
                                    turns: AlwaysStoppedAnimation(270 / 360))
                                : CameraPreview(_mainCamera)
                            : Container(
                                child: Text("Loading"),
                              )
                        : GestureDetector(
                            onTap: () {
                              getPermissionsThatNeedToBeChecked(
                                      PermissionGroup.camera,
                                      PermissionGroup.microphone)
                                  .then((permGroupList) {
                                requestPermStatus(permGroupList);
                              });
                            },
                            child: Container(
                              child: Text(Platform.isAndroid
                                  ? "You have denied camera permissions, please accept them by clicking on this text"
                                  : "You have denied camera permissions, please go to settings to activate them"),
                            )),
                  ),
                ],
              ),
            ),
          ),
          if (StateContainer.of(context).isThereConnectionError)
            ConnectionError(),
          if (isInfo)
            GestureDetector(
              onTap: () {
                setState(() {
                  isInfo = false;
                });
              },
              child: Container(
                width: screenWidth,
                height: screenHeight,
                decoration: new BoxDecoration(color: Colors.black45),
                child: Align(
                    alignment: Alignment.center,
                    child: new EventInfoUI(
                      scaffoldKey: _scaffoldKey,
                    )),
              ),
            )
        ]));
  }

  void changeToSearcher(BuildContext context) {
    if (_isCameraInitalized) {
      _mainCamera.stopImageStream();
    }
    Navigator.pop(context);
    Navigator.of(context)
        .push(NoTransition(builder: (context) => FinderScreen()));
  }
}
