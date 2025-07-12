import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io' as io;

enum PlayerState {
  stopped,
  loading,
  playing,
  paused,
  completed,
  error,
}

class AudioPlayerService {
  FlutterSoundPlayer? _player;
  StreamSubscription? _playerSubscription;

  final StreamController<PlaybackDisposition> _playbackDispositionController = StreamController.broadcast();
  final StreamController<PlayerState> _playerStateController = StreamController.broadcast();

  String? _currentFilePath;
  PlayerState _currentPlayerState = PlayerState.stopped;
  bool _isPlayerInitialized = false;
  Duration _currentAudioDuration = Duration.zero;

  Stream<PlaybackDisposition> get playbackDispositionStream => _playbackDispositionController.stream;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  PlayerState get currentPlayerState => _currentPlayerState;
  Duration get currentAudioDuration => _currentAudioDuration;
  bool get isPlaying => _currentPlayerState == PlayerState.playing;
  bool get isPaused => _currentPlayerState == PlayerState.paused;
  bool get isStopped => _currentPlayerState == PlayerState.stopped || _currentPlayerState == PlayerState.completed;

  Future<void> init() async {
    if (_isPlayerInitialized) return;
    _player = FlutterSoundPlayer();
    await _player!.openPlayer();
    await _player!.setSubscriptionDuration(const Duration(milliseconds: 100));
    _isPlayerInitialized = true;
    _updatePlayerState(PlayerState.stopped);
  }

  void _updatePlayerState(PlayerState newState) {
    if (_currentPlayerState == newState) return;
    _currentPlayerState = newState;
    if (!_playerStateController.isClosed) {
      _playerStateController.add(_currentPlayerState);
    }
  }

  Future<Duration?> loadAudio(Uint8List audioBytes, String fileExtension) async {
    if (!_isPlayerInitialized) await init();
    if (_currentPlayerState == PlayerState.playing) await stop();

    _updatePlayerState(PlayerState.loading);

    try {
      final tempDir = await getTemporaryDirectory();
      if (_currentFilePath != null && await io.File(_currentFilePath!).exists()) {
        await io.File(_currentFilePath!).delete();
      }
      _currentFilePath = p.join(tempDir.path, 'playback_temp.${fileExtension.toLowerCase()}');
      await io.File(_currentFilePath!).writeAsBytes(audioBytes, flush: true);

      Completer<Duration?> durationCompleter = Completer();

      _playerSubscription?.cancel();
      _playerSubscription = _player!.onProgress!.listen((PlaybackDisposition disposition) {
        if (!_playbackDispositionController.isClosed) {
          _playbackDispositionController.add(disposition);
        }
        if (disposition.duration != Duration.zero && !durationCompleter.isCompleted) {
           _currentAudioDuration = disposition.duration;
           durationCompleter.complete(disposition.duration);
        }
      });

      await _player!.startPlayer(
        fromURI: _currentFilePath!,
        whenFinished: _handlePlaybackFinished,
      );
      await _player!.pausePlayer();

      _updatePlayerState(PlayerState.paused);

      Future.any([
          durationCompleter.future,
          Future.delayed(const Duration(seconds: 3), () async {
            if (!durationCompleter.isCompleted) {
              try {
                final trackProps = await _player!.getTrackProperties(_currentFilePath!);
                if (trackProps?.duration != null) {
                  _currentAudioDuration = trackProps!.duration!;
                  durationCompleter.complete(_currentAudioDuration);
                } else {
                  durationCompleter.complete(null);
                }
              } catch (e) {
                if(!durationCompleter.isCompleted) durationCompleter.complete(null);
              }
            }
          })
      ]);

      return durationCompleter.future;

    } catch (e) {
      _updatePlayerState(PlayerState.error);
      _currentAudioDuration = Duration.zero;
      return null;
    }
  }

  Future<void> play() async {
    if (!_isPlayerInitialized || _currentFilePath == null) return;

    if (_currentPlayerState == PlayerState.paused) {
      await _player!.resumePlayer();
      _updatePlayerState(PlayerState.playing);
    } else if (_currentPlayerState == PlayerState.stopped || _currentPlayerState == PlayerState.completed) {
      await _player!.startPlayer(
        fromURI: _currentFilePath!,
        whenFinished: _handlePlaybackFinished,
      );
      _updatePlayerState(PlayerState.playing);
    }
  }

  Future<void> pause() async {
    if (!_isPlayerInitialized || _currentPlayerState != PlayerState.playing) return;
    await _player!.pausePlayer();
    _updatePlayerState(PlayerState.paused);
  }

  Future<void> seek(Duration position) async {
    if (!_isPlayerInitialized) return;
    if (position > _currentAudioDuration) position = _currentAudioDuration;
    if (position < Duration.zero) position = Duration.zero;
    await _player!.seekToPlayer(position);
  }

  Future<void> stop() async {
    if (!_isPlayerInitialized) return;
    await _player!.stopPlayer();
    _updatePlayerState(PlayerState.stopped);
    if (!_playbackDispositionController.isClosed) {
       _playbackDispositionController.add(PlaybackDisposition(duration: _currentAudioDuration, position: Duration.zero));
    }
  }

  void _handlePlaybackFinished() {
    _updatePlayerState(PlayerState.completed);
  }

  Future<void> dispose() async {
    _playerSubscription?.cancel();
    if (_player != null && _player!.isOpen()) {
      await _player!.closePlayer();
    }
    if (_currentFilePath != null && await io.File(_currentFilePath!).exists()) {
      try {
        await io.File(_currentFilePath!).delete();
      } catch (e) {
        // ignore
      }
    }
    _playbackDispositionController.close();
    _playerStateController.close();
    _isPlayerInitialized = false;
  }
}
