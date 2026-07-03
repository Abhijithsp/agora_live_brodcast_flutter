import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agroa_videocall/constants/api_setting.dart';
import 'package:agroa_videocall/features/broadcast/domain/models/broadcast_state.dart';
import 'package:agroa_videocall/services/agora_engine_service.dart';
import 'package:agroa_videocall/services/agora_engine_service_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final agoraEngineServiceProvider = Provider<AgoraEngineService>((ref) {
  return AgoraEngineServiceImpl();
});

final broadcastNotifierProvider =
    NotifierProvider.autoDispose<BroadcastNotifier, BroadcastState>(() {
  return BroadcastNotifier();
});

class BroadcastNotifier extends AutoDisposeNotifier<BroadcastState> {
  late AgoraEngineService _service;

  @override
  BroadcastState build() {
    _service = ref.watch(agoraEngineServiceProvider);
    
    // Automatically leave/release when provider is disposed.
    ref.onDispose(() {
      _leaveAndReleaseSync();
    });

    return const BroadcastDisconnected();
  }

  void _leaveAndReleaseSync() {
    // If we're connected, trigger leave & release
    _service.leaveChannel();
    _service.release();
  }

  Future<void> join({
    required String channelId,
    required ClientRoleType role,
  }) async {
    if (APISettings.appID.isEmpty) {
      state = const BroadcastError('APP_ID missing – please add it to APISettings');
      return;
    }

    state = const BroadcastInitializing();

    try {
      await _service.initialize(
        APISettings.appID,
        ChannelProfileType.channelProfileLiveBroadcasting,
      );

      _service.registerEventHandlers(AgoraEventHandlers(
        onError: (ErrorCodeType err, String msg) {
          state = BroadcastError('Error: $msg');
        },
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          final current = state;
          if (current is BroadcastConnected) {
            state = current.copyWith(
              channelId: connection.channelId ?? current.channelId,
              localUid: connection.localUid ?? current.localUid,
            );
          } else {
            state = BroadcastConnected(
              channelId: connection.channelId ?? channelId,
              localUid: connection.localUid ?? 0,
              audioMuted: false,
              videoMuted: false,
              remoteUids: const [],
            );
          }
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          state = const BroadcastDisconnected();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          final current = state;
          if (current is BroadcastConnected) {
            state = current.copyWith(
              remoteUids: [...current.remoteUids, remoteUid],
            );
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          final current = state;
          if (current is BroadcastConnected) {
            state = current.copyWith(
              remoteUids: current.remoteUids.where((uid) => uid != remoteUid).toList(),
            );
          }
        },
      ));

      await _service.setClientRole(role);
      await _service.enableVideo();
      await _service.enableAudio();
      await _service.startPreview();

      await _service.joinChannel(
        token: APISettings.agoraToken,
        channelId: channelId,
        uid: 0,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: role,
          publishCameraTrack: role == ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: role == ClientRoleType.clientRoleBroadcaster,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      state = BroadcastConnected(
        channelId: channelId,
        localUid: 0,
        audioMuted: false,
        videoMuted: false,
        remoteUids: const [],
      );
    } catch (e) {
      state = BroadcastError('Failed to join channel: $e');
    }
  }

  Future<void> toggleAudio() async {
    final current = state;
    if (current is BroadcastConnected) {
      final newMute = !current.audioMuted;
      await _service.muteLocalAudioStream(newMute);
      state = current.copyWith(audioMuted: newMute);
    }
  }

  Future<void> toggleVideo() async {
    final current = state;
    if (current is BroadcastConnected) {
      final newMute = !current.videoMuted;
      await _service.muteLocalVideoStream(newMute);
      state = current.copyWith(videoMuted: newMute);
    }
  }

  Future<void> switchCamera() async {
    await _service.switchCamera();
  }

  Future<void> leave() async {
    await _service.leaveChannel();
    await _service.release();
    state = const BroadcastDisconnected();
  }
}
