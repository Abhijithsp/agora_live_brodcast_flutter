import 'dart:developer';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'call_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _channelController = TextEditingController();
  bool validateError = false;
  ClientRole _currentRole = ClientRole.Broadcaster;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 50,
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.broadcast_on_personal,color: Colors.green,size: 100,),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Live Broadcast",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    color: Colors.black),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                height: 65,
                width: double.infinity,
                child: TextFormField(
                  controller: _channelController,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    isDense: true,
                      prefixIcon: const Icon(Icons.videocam,color:Colors.green,size: 30,),
                      errorText:
                          validateError ? 'Channel name is required' : null,
                      labelText: 'Channel Name',
                      hintText: "Channel Name"),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            RadioListTile(
              title: const Text('Broadcaster',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
              value: ClientRole.Broadcaster,
              groupValue: _currentRole,
              onChanged: (ClientRole? value) {
                setState(() {
                  _currentRole = value!;
                });
              },
            ),
            const SizedBox(
              height: 20,
            ),
            RadioListTile(
              title: const Text('Audience',style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
              value: ClientRole.Audience,
              groupValue: _currentRole,
              onChanged: (ClientRole? value) {
                setState(() {
                  _currentRole = value!;
                });
              },
            ),
            const SizedBox(
              height: 40,
            ),
            SizedBox(
              height: 50,
              width: 200,
              child: ElevatedButton.icon(
                  label: const Text('Connect',
                      style: TextStyle(color: Colors.white,fontSize: 18,fontWeight: FontWeight.bold)),
                  icon: const Icon(Icons.video_camera_front_outlined,size: 30,),
                  onPressed: () async {
                    joinChannel();
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> joinChannel() async {
    setState(() {
      _channelController.text.isEmpty
          ? validateError = true
          : validateError = false;
    });
    if (_channelController.text.isNotEmpty) {
      await _handleCameraAndMicPermission();
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) =>  CallScreen(
          channelName: _channelController.text,
          userRole: _currentRole,
        )),
      );

    }
  }
  Future<void> _handleCameraAndMicPermission() async {

    Map<Permission, PermissionStatus> permissionStatus = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    log(permissionStatus[Permission.camera].toString());
    log(permissionStatus[Permission.microphone].toString());

  }

}
