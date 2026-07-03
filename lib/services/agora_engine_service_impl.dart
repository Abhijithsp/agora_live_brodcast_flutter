import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'agora_engine_service.dart';

/// Production implementation — delegates to the real [RtcEngine].
class AgoraEngineServiceImpl implements AgoraEngineService {
  late RtcEngine _engine;

  @override
  RtcEngine? get rawEngine => _engine;

  @override
  Future<void> initialize(
      String appId, ChannelProfileType channelProfile) async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: channelProfile,
    ));
  }

  @override
  void registerEventHandlers(AgoraEventHandlers handlers) {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onError: handlers.onError,
        onJoinChannelSuccess: handlers.onJoinChannelSuccess,
        onLeaveChannel: handlers.onLeaveChannel,
        onUserJoined: handlers.onUserJoined,
        onUserOffline: handlers.onUserOffline,
      ),
    );
  }

  @override
  Future<void> setClientRole(ClientRoleType role) =>
      _engine.setClientRole(role: role);

  @override
  Future<void> enableVideo() => _engine.enableVideo();

  @override
  Future<void> enableAudio() => _engine.enableAudio();

  @override
  Future<void> startPreview() => _engine.startPreview();

  @override
  Future<void> joinChannel({
    required String token,
    required String channelId,
    required int uid,
    required ChannelMediaOptions options,
  }) =>
      _engine.joinChannel(
        token: token,
        channelId: channelId,
        uid: uid,
        options: options,
      );

  @override
  Future<void> leaveChannel() => _engine.leaveChannel();

  @override
  Future<void> muteLocalAudioStream(bool mute) =>
      _engine.muteLocalAudioStream(mute);

  @override
  Future<void> muteLocalVideoStream(bool mute) =>
      _engine.muteLocalVideoStream(mute);

  @override
  Future<void> switchCamera() => _engine.switchCamera();

  @override
  Future<void> release() => _engine.release();
}
