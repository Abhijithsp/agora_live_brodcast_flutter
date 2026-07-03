import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/// Callback types that mirror [RtcEngineEventHandler] fields we care about.
typedef OnErrorCallback = void Function(ErrorCodeType err, String msg);
typedef OnJoinChannelSuccessCallback = void Function(
    RtcConnection connection, int elapsed);
typedef OnLeaveChannelCallback = void Function(
    RtcConnection connection, RtcStats stats);
typedef OnUserJoinedCallback = void Function(
    RtcConnection connection, int remoteUid, int elapsed);
typedef OnUserOfflineCallback = void Function(
    RtcConnection connection, int remoteUid, UserOfflineReasonType reason);

/// Groups every engine event handler in one value-object.
/// This makes it easy to pass to both real and fake implementations.
class AgoraEventHandlers {
  final OnErrorCallback? onError;
  final OnJoinChannelSuccessCallback? onJoinChannelSuccess;
  final OnLeaveChannelCallback? onLeaveChannel;
  final OnUserJoinedCallback? onUserJoined;
  final OnUserOfflineCallback? onUserOffline;

  const AgoraEventHandlers({
    this.onError,
    this.onJoinChannelSuccess,
    this.onLeaveChannel,
    this.onUserJoined,
    this.onUserOffline,
  });
}

/// Abstract service layer around [RtcEngine].
/// Testable seam — production uses [AgoraEngineServiceImpl],
/// tests use [FakeAgoraEngineService].
abstract class AgoraEngineService {
  /// Initialise the engine with the given [appId].
  Future<void> initialize(String appId, ChannelProfileType channelProfile);

  /// Register all relevant RTC event callbacks.
  void registerEventHandlers(AgoraEventHandlers handlers);

  /// Set client role (Broadcaster / Audience).
  Future<void> setClientRole(ClientRoleType role);

  /// Enable the video module.
  Future<void> enableVideo();

  /// Enable the audio module.
  Future<void> enableAudio();

  /// Start the local camera preview.
  Future<void> startPreview();

  /// Join the given [channelId] with [options].
  Future<void> joinChannel({
    required String token,
    required String channelId,
    required int uid,
    required ChannelMediaOptions options,
  });

  /// Leave the current channel.
  Future<void> leaveChannel();

  /// Mute / un-mute the local audio stream.
  Future<void> muteLocalAudioStream(bool mute);

  /// Mute / un-mute the local video stream.
  Future<void> muteLocalVideoStream(bool mute);

  /// Switch between front and rear cameras.
  Future<void> switchCamera();

  /// Destroy the engine and free resources.
  Future<void> release();

  /// The underlying [RtcEngine] instance, needed for [AgoraVideoView].
  /// Implementations that do not expose a real engine (e.g. fakes) may
  /// return null and callers must guard accordingly.
  RtcEngine? get rawEngine;
}
