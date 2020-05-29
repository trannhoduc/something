// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
//import 'dart:js';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:flutter/semantics.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_blue_example/widgets.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

void main() => runApp(FlutterBlueApp());

class FlutterBlueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return FindDevicesScreen();
            }
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key key, this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle1
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatelessWidget {

  // Future<Color>getState(BluetoothDevice device, Color xx) async { 
  //   List<BluetoothService> services = await device.discoverServices();
  //   //Color xx;
  //   services.forEach((service) async {
  //   // do something with service
  //   var characteristics = service.characteristics;
  //   for(BluetoothCharacteristic c in characteristics) {
  //     if (service.uuid.toString() == "bae55b96-7d19-458d-970c-50613d801bc9"){
  //       if (c.uuid.toString() == "76e137ac-b15f-49d7-9c4c-e278e6492ad9") {
  //         List<int> value = await c.read();
  //         if (value.toString() == "[1]"){
  //           xx = Colors.red[200];
  //         }
  //         else if (value.toString() == "[0]"){
  //           xx = Colors.grey[200];
  //         }      
  //       }
  //     }
  //   }      
  //   }); 
  //   return xx;                   
  // }

  nextPage(ScanResult r, BuildContext context) async {
    
      await r.device.connect();
      //Color xx = Colors.yellow;
      
      //Future<Color> xxx;
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DeviceScreen(device: r.device)),
        );

      // Navigator.of(context)
      //     .push(MaterialPageRoute(builder: (context) {r.device.connect();
      //   return DeviceScreen(device: r.device);
      // }));
      //print("fffffffffffffffffff\ndd\nddddddddddddddddddddd\n");
      //print(getState(r.device).runtimeType);
      //print(getState(r.device));
      //return DeviceScreen(device: r.device, lightColor: xxx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[ 
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map((d) => ListTile(
                            title: Text(d.name),
                            subtitle: Text(d.id.toString()),
                            trailing: StreamBuilder<BluetoothDeviceState>(
                              stream: d.state,
                              initialData: BluetoothDeviceState.disconnected,
                              builder: (c, snapshot) {
                                if (snapshot.data ==
                                    BluetoothDeviceState.connected) {
                                  return RaisedButton(
                                    child: Text('OPEN'),
                                    onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                DeviceScreen(device: d))),
                                  );
                                }
                                return Text(snapshot.data.toString());
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map(
                        (r) => ScanResultTile(
                          result: r,
                          onTap: () {
                            nextPage(r, context);
                          }
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}


class DeviceScreen extends StatefulWidget{
  //DeviceScreen({this.device, this.lightColor});
  DeviceScreen({this.device});
  final BluetoothDevice device; 
  //Color> lightColor; 
  //Future<Color> lightColor;
  @override 
  DeviceScreenState createState() => DeviceScreenState();
}

class DeviceScreenState extends State<DeviceScreen>{

  Color lightColor = Colors.black;
  BluetoothCharacteristic cMain;

  //Color lightColor = convert(lightColor);

  List<int> _getRandomBytes() {
    final math = Random();
    return [
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255),
      math.nextInt(255)
    ];
  }

  List<Widget> _buildServiceTiles(List<BluetoothService> services) {
    return services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map(
                  (c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () => c.read(),
                    onWritePressed: () async {                      
                      List<int> value = await c.read();
                      if (value.toString() == "[1]"){
                        await c.write([0]);
                      }
                      else{
                        await c.write([1]);
                      }
                      await c.read();
                    },
                    onNotificationPressed: () async {
                      await c.setNotifyValue(!c.isNotifying);
                      await c.read();
                    },
                    descriptorTiles: c.descriptors
                        .map(
                          (d) => DescriptorTile(
                            descriptor: d,
                            onReadPressed: () => d.read(),
                            onWritePressed: () => d.write(_getRandomBytes()),
                            //onWritePressed: () => d.write([1]),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

/*
remoteId: 00:0B:57:64:8D:6D 
characteristicUuid: 76e137ac-b15f-49d7-9c4c-e278e6492ad9 
serviceUuid: bae55b96-7d19-458d-970c-50613d801bc9 
*/

  void _turnOn() async { 
    List<BluetoothService> services = await widget.device.discoverServices();
    services.forEach((service) async {
    // do something with service
    var characteristics = service.characteristics;
    for(BluetoothCharacteristic c in characteristics) {
      if (service.uuid.toString() == "bae55b96-7d19-458d-970c-50613d801bc9"){
        if (c.uuid.toString() == "76e137ac-b15f-49d7-9c4c-e278e6492ad9") {
          List<int> value = await c.read();
          if (value.toString() == "[1]"){
            await c.write([0]);
            _changeColor(0);
          }
          else if (value.toString() == "[0]"){
            await c.write([1]);
            _changeColor(1);
          }          
        }
      }
    }      
    });                     
  }

  void readDescriptors() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    services.forEach((service) async {
      // do something with service
      var characteristics = service.characteristics;
      for(BluetoothCharacteristic c in characteristics) {
        var descriptors = c.descriptors;
        for(BluetoothDescriptor d in descriptors) {
          if (service.uuid.toString() == "bae55b96-7d19-458d-970c-50613d801bc9"){
            if (c.uuid.toString() == "76e137ac-b15f-49d7-9c4c-e278e6492ad9") {
              List<int> value = await d.read();
              //print("ffffffffffffffffff \n fdddddddddddddddddddddddđ\n ffffffffffffffffffffff\n");
              print(value);    
            }
          }
        }
      }      
    });
  }

  void _changeColor(int i){
    setState(() {
      lightColor = (i==0)?Colors.grey[200]:Colors.redAccent[100];
    });
  }

  void getState(BluetoothDevice device) async { 
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) async {
    // do something with service
    var characteristics = service.characteristics;
    for(BluetoothCharacteristic c in characteristics) {
      if (service.uuid.toString() == "bae55b96-7d19-458d-970c-50613d801bc9"){
        if (c.uuid.toString() == "76e137ac-b15f-49d7-9c4c-e278e6492ad9") {
          List<int> value = await c.read();
          if (value.toString() == "[1]"){
            _changeColor(1);
          }
          else if (value.toString() == "[0]"){
            _changeColor(0);
          }      
        }
      }
    }      
  });                 
  }

  Future writeBle(List<int> data, BluetoothCharacteristic c) async {
    try {
      await c.write(data);
    } on PlatformException catch (e) {
      print("BLE write error $e!");
    }
               
  }

  Future readBle(List<int> data, BluetoothCharacteristic c) async {
    try {
      return await c.read(); 
    } on PlatformException catch (e) {
      print("BLE read error $e!");
    }       
  }

  @override
  void initState(){
    super.initState();
    getState(widget.device);    
  }

  @override
  Widget build(BuildContext context) {
    //getState(widget.device);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: widget.device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => widget.device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => widget.device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return FlatButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: widget.device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: (snapshot.data == BluetoothDeviceState.connected)
                    ? Icon(Icons.bluetooth_connected)
                    : Icon(Icons.bluetooth_disabled),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.')[1]}.'),
                subtitle: Text('${widget.device.id}'),
                trailing: StreamBuilder<bool>(
                  stream: widget.device.isDiscoveringServices,
                  initialData: false,
                  builder: (c, snapshot) => IndexedStack(
                    index: snapshot.data ? 1 : 0,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () {
                          widget.device.discoverServices();                          
                        } 
                      ),
                      IconButton(
                        icon: SizedBox(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                          width: 18.0,
                          height: 18.0,
                        ),
                        onPressed: null,
                      )
                    ],
                  ),
                ),
              ),
            ),
            // RaisedButton(
            //   child: Text("READ DESCRIPTORS"),
            //   onPressed: _readDescriptors,
            // ),
            StreamBuilder<List<BluetoothService>>(
              stream: widget.device.services,
              initialData: [],
              builder: (c, snapshot) {
                return null;
              },
            ),
            IconButton(
              iconSize: 200,
              padding: new EdgeInsets.all(5),
              icon: Icon(
                MdiIcons.lightbulbOnOutline,
              ),
              color: lightColor,
              //highlightColor: Colors.red,
              //hoverColor: Colors.green,
              //focusColor: Colors.purple,
              splashColor: Colors.red[100],
              //disabledColor: Colors.amber,
              tooltip: 'Turn off the light!',
              onPressed: () => _turnOn(),
            ),
            StreamBuilder<int>(
              stream: widget.device.mtu,
              initialData: 0,
              builder: (c, snapshot) => ListTile(
                title: Text('MTU Size'),
                subtitle: Text('${snapshot.data} bytes'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => widget.device.requestMtu(223),
                ),
              ),
            ),
            StreamBuilder<List<BluetoothService>>(
              stream: widget.device.services,
              initialData: [],
              builder: (c, snapshot) {
                return Column(
                  children: _buildServiceTiles(snapshot.data),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
