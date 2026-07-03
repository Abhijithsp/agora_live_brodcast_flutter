import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agroa_videocall/services/agora_engine_service.dart';

/// A fully-controllable in-memory fake for [AgoraEngineService].
///
/// * Records every call so tests can assert on them.
/// * Exposes trigger helpers so tests can fire SDK events on demand
///   (e.g. [simulateUserJoined]) without any native code or network.
/// * Never touches a real [RtcEngine] – safe to run on the Dart VM.
class FakeAgoraEngineService implements AgoraEngineService {
  // --------------------------------------------------------------------------
  // State visible to tests
  // --------------------------------------------------------------------------

  bool initializeCalled = false;
  String? lastInitializedAppId;
  ChannelProfileType? lastInitializedProfile;

  bool eventHandlersRegistered = false;

  ClientRoleType? lastSetRole;

  bool enableVideoCalled = false;
  bool enableAudioCalled = false;
  bool startPreviewCalled = false;

  bool joinChannelCalled = false;
  String? lastJoinedToken;
  String? lastJoinedChannelId;
  int? lastJoinedUid;
  ChannelMediaOptions? lastJoinedOptions;

  bool leaveChannelCalled = false;
  int leaveChannelCallCount = 0;

  bool releaseCalled = false;

  bool? lastMuteAudio; // true = muted, false = un-muted
  bool? lastMuteVideo;

  bool switchCameraCalled = false;

  /// Set to true before calling [initialize] to make it throw.
  bool throwOnInitialize = false;

  /// Set to true before calling [joinChannel] to make it throw.
  bool throwOnJoin = false;

  // --------------------------------------------------------------------------
  // Private – stored handlers so we can fire events from tests
  // --------------------------------------------------------------------------

  AgoraEventHandlers? _handlers;

  // --------------------------------------------------------------------------
  // AgoraEngineService interface
  // --------------------------------------------------------------------------

  @override
  RtcEngine? get rawEngine => null; // no native engine in tests

  @override
  Future<void> initialize(
      String appId, ChannelProfileType channelProfile) async {
    if (throwOnInitialize) throw Exception('init failed (fake)');
    initializeCalled = true;
    lastInitializedAppId = appId;
    lastInitializedProfile = channelProfile;
  }

  @override
  void registerEventHandlers(AgoraEventHandlers handlers) {
    eventHandlersRegistered = true;
    _handlers = handlers;
  }

  @override
  Future<void> setClientRole(ClientRoleType role) async {
    lastSetRole = role;
  }

  @override
  Future<void> enableVideo() async => enableVideoCalled = true;

  @override
  Future<void> enableAudio() async => enableAudioCalled = true;

  @override
  Future<void> startPreview() async => startPreviewCalled = true;

  @override
  Future<void> joinChannel({
    required String token,
    required String channelId,
    required int uid,
    required ChannelMediaOptions options,
  }) async {
    if (throwOnJoin) throw Exception('join failed (fake)');
    joinChannelCalled = true;
    lastJoinedToken = token;
    lastJoinedChannelId = channelId;
    lastJoinedUid = uid;
    lastJoinedOptions = options;
  }

  @override
  Future<void> leaveChannel() async {
    leaveChannelCalled = true;
    leaveChannelCallCount++;
  }

  @override
  Future<void> muteLocalAudioStream(bool mute) async => lastMuteAudio = mute;

  @override
  Future<void> muteLocalVideoStream(bool mute) async => lastMuteVideo = mute;

  @override
  Future<void> switchCamera() async => switchCameraCalled = true;

  @override
  Future<void> release() async => releaseCalled = true;

  // --------------------------------------------------------------------------
  // Test-trigger helpers — simulate SDK events from test code
  // --------------------------------------------------------------------------

  void simulateError(ErrorCodeType code, String msg) =>
      _handlers?.onError?.call(code, msg);

  void simulateJoinChannelSuccess(String channelId, {int uid = 0}) {
    _handlers?.onJoinChannelSuccess?.call(
      RtcConnection(channelId: channelId, localUid: uid),
      0,
    );
  }

  void simulateLeaveChannel(String channelId) {
    _handlers?.onLeaveChannel?.call(
      RtcConnection(channelId: channelId, localUid: 0),
      const RtcStats(),
    );
  }

  void simulateUserJoined(String channelId, int remoteUid) {
    _handlers?.onUserJoined?.call(
      RtcConnection(channelId: channelId, localUid: 0),
      remoteUid,
      0,
    );
  }

  void simulateUserOffline(String channelId, int remoteUid,
      {UserOfflineReasonType reason =
          UserOfflineReasonType.userOfflineDropped}) {
    _handlers?.onUserOffline?.call(
      RtcConnection(channelId: channelId, localUid: 0),
      remoteUid,
      reason,
    );
  }
}
