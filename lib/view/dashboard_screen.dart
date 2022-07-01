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
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  width: 100.00,
                  height: 100.00,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                          "https://randomuser.me/api/portraits/lego/5.jpg"),
                      fit: BoxFit.fill,
                    ),
                  )),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 60,
                width: double.infinity,
                child: TextFormField(
                  controller: _channelController,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
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
              title: const Text('Broadcaster'),
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
              title: const Text('Audience'),
              value: ClientRole.Audience,
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
            SizedBox(
              height: 50,
              width: 200,
              child: ElevatedButton.icon(
                  label: const Text('Connect',
                      style: TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.call),
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
