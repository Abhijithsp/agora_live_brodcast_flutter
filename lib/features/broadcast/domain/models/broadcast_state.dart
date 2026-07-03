import 'package:agora_rtc_engine/agora_rtc_engine.dart';

sealed class BroadcastState {
  const BroadcastState();
}

/// Engine is being created / permissions being requested.
class BroadcastInitializing extends BroadcastState {
  const BroadcastInitializing();
}

/// Joined channel. Remote users tracked here.
class BroadcastConnected extends BroadcastState {
  final String channelId;
  final int localUid;
  final List<int> remoteUids;
  final bool audioMuted;
  final bool videoMuted;

  const BroadcastConnected({
    required this.channelId,
    required this.localUid,
    this.remoteUids = const [],
    this.audioMuted = false,
    this.videoMuted = false,
  });

  BroadcastConnected copyWith({
    String? channelId,
    int? localUid,
    List<int>? remoteUids,
    bool? audioMuted,
    bool? videoMuted,
  }) => BroadcastConnected(
    channelId: channelId ?? this.channelId,
    localUid: localUid ?? this.localUid,
    remoteUids: remoteUids ?? this.remoteUids,
    audioMuted: audioMuted ?? this.audioMuted,
    videoMuted: videoMuted ?? this.videoMuted,
  );
}

/// Channel left / engine released.
class BroadcastDisconnected extends BroadcastState {
  const BroadcastDisconnected();
}

/// Non-recoverable error.
class BroadcastError extends BroadcastState {
  final String message;
  const BroadcastError(this.message);
}
