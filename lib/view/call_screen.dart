import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agroa_videocall/constants/api_setting.dart';
import 'package:flutter/material.dart';

import 'dart:async';

import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

class CallScreen extends StatefulWidget {
  final String? channelName;
  final ClientRole? userRole;
  const CallScreen({Key? key, this.channelName, this.userRole})
      : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _usersList = <int>[];
  final _infoStrings = <String>[];
  bool mutedStatus = false;
  bool viewPanel = false;
  late RtcEngine rtc_engine;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    initializeAppData();
    // initRtcEngine();
  }

  @override
  void dispose() {
    _usersList.clear();
    // _infoStrings.clear();
    rtc_engine.leaveChannel();
    rtc_engine.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        key: _scaffoldKey,
        title: const Text('Call',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Stack(
          children: <Widget>[
            viewVideoScreen(),
            buttonsPanelView(),
          ],
        ),
      ),
    );
  }

  ///View for Video of Each joined users And Broadcaster

  Widget viewVideoScreen() {
    final List<StatefulWidget> list = [];
    final videoViews = list;
    if (widget.userRole == ClientRole.Broadcaster) {
      list.add(const RtcLocalView.SurfaceView());
    }
    for (int userId in _usersList) {
      list.add(RtcRemoteView.SurfaceView(
        uid: userId,
        channelId: widget.channelName!,
      ));
    }

    return Column(
        children: List.generate(
            videoViews.length, (index) => Expanded(child: videoViews[index])));
  }

  ///Button for switch camera,End call and Mute button

  Widget buttonsPanelView() {
    if (widget.userRole == ClientRole.Audience) return const SizedBox();

    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 45),
      child: Row(
        children: [
          RawMaterialButton(
            onPressed: () {
              setState(() {
                mutedStatus = !mutedStatus;
              });
              rtc_engine.muteLocalAudioStream(mutedStatus);
            },
            shape: const CircleBorder(),
            fillColor: mutedStatus ? Colors.green : Colors.white,
            elevation: 2.0,
            padding: const EdgeInsets.all(5.0),
            child: Icon(
              mutedStatus ? Icons.mic_off : Icons.mic,
              color: mutedStatus ? Colors.white : Colors.green,
              size: 40,
            ),
          ),
          RawMaterialButton(
            onPressed: () {
              Navigator.pop(context);
              rtc_engine.leaveChannel();
            },
            shape: const CircleBorder(),
            fillColor: Colors.white,
            elevation: 5.0,
            padding: const EdgeInsets.all(5.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.red,
              size: 45,
            ),
          ),
          RawMaterialButton(
            onPressed: () {
              rtc_engine.switchCamera();
            },
            shape: const CircleBorder(),
            fillColor: Colors.white,
            padding: const EdgeInsets.all(5.0),
            child: const Icon(
              Icons.switch_camera,
              color: Colors.green,
              size: 35,
            ),
          )
        ],
      ),
    );
  }

  ///Functions For Agora Engine and check if app_id is present
  Future<void> initializeAppData() async {
    if (APISettings.app_ID.isEmpty) {
      setState(() {
        _infoStrings
            .add("APP_ID missing,Please provide one in APISetting class");
        _infoStrings.add("Agora Engine Failed to Start,please Try again later");
      });
      return;
    }
    initAgoraEngine();
  }

  Future<void> initAgoraEngine() async {
    rtc_engine = await RtcEngine.create(APISettings.app_ID);
    await rtc_engine.enableAudio();
    await rtc_engine.enableVideo();
    await rtc_engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await rtc_engine.setClientRole(widget.userRole!);

    ///Call Event Handler  Status for RtcEngine
    _RtceventHandler();

    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(width: 1920, height: 1080);
    await rtc_engine.setVideoEncoderConfiguration(configuration);
    await rtc_engine.joinChannel(
        APISettings.agoraToken, widget.channelName!, null, 0);
  }

  ///Event Handler Function with status of RtcEngine

  Future<void> _RtceventHandler() async {
    rtc_engine.setEventHandler(RtcEngineEventHandler(error: (code) {
      final snackBar = SnackBar(content: Text("Error:$code"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }, joinChannelSuccess: (channel, userid, elapsed) {
      final snackBar =
          SnackBar(content: Text("Join Channel:$channel,uid:$userid"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }, leaveChannel: (status) {
      final snackBar = SnackBar(content: Text("Leave Channel:$status"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      setState(() {
        _usersList.clear();
      });
    }, userJoined: (int userid, int elapsed) {
      final snackBar = SnackBar(
          content: Text("User Joined:userid:$userid,elapsed:$elapsed"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      setState(() {
        _usersList.add(userid);
      });
    }, userOffline: (int userid, UserOfflineReason reason) {
      final snackBar =
          SnackBar(content: Text("User Offline:userid:$userid,reason:$reason"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      setState(() {
        _usersList.remove(userid);
      });
    }));
  }
}
