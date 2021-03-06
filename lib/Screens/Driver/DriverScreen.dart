import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dynamicrouteplanner/Screens/Driver/RemovePassenger.dart';
import 'package:dynamicrouteplanner/StaticConstants/constants.dart';
import 'package:dynamicrouteplanner/components/drawer_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:location/location.dart' as loc;

import '../../main.dart';
import 'AddPassenger.dart';
import 'Calculating.dart';

class Driver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample>
{
  final loc.Location location = loc.Location();
  StreamSubscription<loc.LocationData> locationSubscription;

  Widget _AddPassengerDrawer()
  {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => AddPassenger()), ModalRoute.withName("/Home"));
        },
        child: Padding(
          padding: EdgeInsets.only(top: 10),
          child:Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(right: 20),
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/icons/Main.png'),
                  ),
                ),
              ),
              Text("Add Passengers", style: TextStyle(color: Colors.black, fontSize: 20),),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ExitDrawer()
  {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () async {
              await FirebaseAuth.instance.signOut();
              student = null;
              driver = null;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MyApp()), ModalRoute.withName("/Home"));
            },
        child: Padding(
          padding: EdgeInsets.only(top: 10),
          child:Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(right: 20),
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/icons/Main.png'),
                  ),
                ),
              ),
              Text("Exit", style: TextStyle(color: Colors.black, fontSize: 20),),
            ],
          ),
        ),
      ),
    );
  }

  Widget _RempvePassengerDrawer() {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => RemovePassenger()), ModalRoute.withName("/Home"));
        },
        child: Padding(
          padding: EdgeInsets.only(top: 10),
          child:Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(right: 20),
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/icons/Main.png'),
                  ),
                ),
              ),
              Text("Remove Passengers", style: TextStyle(color: Colors.black, fontSize: 20),),
            ],
          ),
        ),
      ),
    );
  }

  Widget Driver_DrawerList()
  {
    return Container(
      padding: EdgeInsets.only(top: 15,),
      child: Column(
        children: [
          _AddPassengerDrawer(),
          _RempvePassengerDrawer(),
          _ExitDrawer()
        ],
      ),
    );
  }

  static CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(40.8809433, 29.2577417),
    zoom: 7.4746,
  );

  Set<Marker> _markers = {};

  BitmapDescriptor driverPin;
  BitmapDescriptor schoolPin;
  BitmapDescriptor studentPin;

  int idx = -1;
  int uBound = 0;
  String next = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _requestPermission();
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _kGooglePlex = CameraPosition(
        target: LatLng(driver["lat"], driver["lng"]),
        zoom: 11.4746,
      );
    });
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/images/bus.png')
        .then((value) {
      driverPin = value;
    });
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/images/school.png')
        .then((value) {
      schoolPin = value;
    });
    BitmapDescriptor.fromAssetImage(
        ImageConfiguration(), 'assets/images/student.png')
        .then((value) {
      studentPin = value;
    });

    if (path != null) {
      idx = 1;
      uBound = path.length;
      next = path[1];
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      if (driver != null) {
        if (driver["sLat"] != 0 && driver["sLng"] != 0) {
          _markers.add(
              Marker(
                markerId: MarkerId('id-1'),
                position: LatLng(driver["sLat"], driver["sLng"]),
                icon: schoolPin,
                infoWindow: InfoWindow(
                  title: "School",
                  snippet: "School Location",
                ),
              )
          );
        }
        _markers.add(
            Marker(
              markerId: MarkerId('id-2'),
              position: LatLng(driver["lat"], driver["lng"]),
              icon: driverPin,
              infoWindow: InfoWindow(
                  title: "Bus Driver",
                  snippet: "Your Location"
              ),
            )
        );
      }
    });
  }

  void updateDriverMarker() async {
    int idx = -1;
    for (int i = 0; i < _markers.length; ++i) {
      if (_markers.elementAt(i).markerId == MarkerId('id-2'))
          idx = i;
    }

    if (_markers.length > 1) {
      _markers.remove(_markers.elementAt(idx));
      _markers.add(Marker(
        markerId: MarkerId('id-2'),
        position: LatLng(driver["lat"], driver["lng"]),
        icon: driverPin,
        infoWindow: InfoWindow(
            title: "Bus Driver",
            snippet: "Your Bus Driver Location"
        ),
      ));
    }

    if (path != null) {
        for (int i = 1; i < path.length - 1; ++i) {
          for (int j = 0; j < students.length; ++j) {
            if (path[i] == students[j]["email"]) {
              _markers.add(Marker(
                markerId: MarkerId(students[j]["email"]),
                position: LatLng(students[j]["lat"], students[j]["lng"]),
                icon: studentPin,
                infoWindow: InfoWindow(
                    title: "Student: ",
                    snippet: students[j]["email"]
                ),
              ));
            }
          }
        }
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent[200],
        title: Text("Dynamic Route Planner - Driver"),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blueAccent[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _getLocation();},
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.white)),
                  child: Text("Add my location"),
                ),
                TextButton(
                    onPressed: () {
                      _listenLocation();},
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.white)),
                    child: Text("Enable live location")),
                TextButton(
                    onPressed: () {
                      _stopListening();},
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.white)),
                    child: Text("Stop live location")),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: () {
                    setState(() {
                      print(path);
                      if (idx != -1) {
                        if (idx < path.length - 1) {
                          next = path[idx];
                        } else if (idx == path.length - 1) {
                          next = "Completed";
                        }
                        idx += 1;
                      }
                      print(next);
                    });
                    },
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.white)),
                  child: Text(next)),
            ],
          ),
          Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('Drivers').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  bool isUpdate = false;
                  try {
                    for (int i = 0; i < snapshot.data.docs.length; ++i) {
                      if (driver != null) {
                        if (snapshot.data.docs[i]['email'] == driver['email']) {
                          isUpdate = true;
                          driver['lat'] = snapshot.data.docs[i]['lat'];
                          driver['lng'] = snapshot.data.docs[i]['lng'];
                        }
                      }
                    }
                  } catch (e) {}
                  if (isUpdate)
                    updateDriverMarker();
                  return Container(
                    child: GoogleMap(
                        mapType: MapType.normal,
                        onMapCreated: _onMapCreated,
                        markers: _markers,
                        initialCameraPosition: _kGooglePlex,
                    ),
                  );
                }
              ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          child: Container(
            child: Column(
              children: [
                MyHeaderDrawer(),
                Driver_DrawerList()
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => LoadToCalculate()));
        },
        label: Text('Find Shortest Path'),
        icon: Icon(Icons.directions_bus),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  _getLocation() async {
    try {
      final loc.LocationData _locationResult = await location.getLocation();
      await FirebaseFirestore.instance.collection('Drivers').doc(FirebaseAuth.instance.currentUser.email).set({
        'lat': _locationResult.latitude,
        'lng': _locationResult.longitude,
      }, SetOptions(merge: true));
    } catch (e) {
      print(e);
    }
  }

  Future<void> _listenLocation() async {
    locationSubscription = location.onLocationChanged.handleError((onError) {
      print(onError);
      locationSubscription.cancel();
      setState(() {
        locationSubscription = null;
      });
    }).listen((loc.LocationData currentlocation) async {
      await FirebaseFirestore.instance.collection('Drivers').doc(FirebaseAuth.instance.currentUser.email).set({
        'lat': currentlocation.latitude,
        'lng': currentlocation.longitude,
      }, SetOptions(merge: true));
    });
  }

  _stopListening() {
    if (locationSubscription != null) {
      locationSubscription.cancel();
      setState(() {
        locationSubscription = null;
      });
    }
  }

  _requestPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print('done');
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}
