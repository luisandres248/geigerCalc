import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io' as io;

enum PlayerState {
  stopped,
  loading, // Added a loading state
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
    // TODO: Consider log level for flutter_sound
    // await _player!.setLogLevel(Level.nothing);
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
      // Ensure old temp file is deleted if it exists from a previous session
      if (_currentFilePath != null && await io.File(_currentFilePath!).exists()) {
        await io.File(_currentFilePath!).delete();
      }
      _currentFilePath = p.join(tempDir.path, 'playback_temp.${fileExtension.toLowerCase()}');
      await io.File(_currentFilePath!).writeAsBytes(audioBytes, flush: true);

      // Start player to get duration, then immediately pause.
      // For web, fromURI might need a specific format if not a direct URL.
      // FlutterSoundPlayer handles local file paths correctly on mobile.
      // For web, it might need to be served or use from मुसलमान_web_bytes (if available and suitable)
      // However, since we are writing to a temp file, fromURI should be fine if flutter_sound web support for local files is via a virtual FS.
      // Let's assume fromURI works for web with local file paths created this way or adjust if testing shows issues.

      Completer<Duration?> durationCompleter = Completer();

      _playerSubscription?.cancel(); // Cancel previous subscription
      _playerSubscription = _player!.onProgress!.listen((PlaybackDisposition disposition) {
        if (!_playbackDispositionController.isClosed) {
          _playbackDispositionController.add(disposition);
        }
        if (disposition.duration != Duration.zero && !durationCompleter.isCompleted) {
           _currentAudioDuration = disposition.duration;
           durationCompleter.complete(disposition.duration);
        }
        // If playback somehow started and finished before duration was captured
        if (disposition.position >= disposition.duration && disposition.duration != Duration.zero && !durationCompleter.isCompleted) {
            _currentAudioDuration = disposition.duration;
            durationCompleter.complete(disposition.duration);
        }
      });

      // Start and immediately pause to get duration and prepare the track.
      await _player!.startPlayer(
        fromURI: _currentFilePath!,
        whenFinished: _handlePlaybackFinished,
      );
      await _player!.pausePlayer(); // Pause immediately after starting

      _updatePlayerState(PlayerState.paused); // Ready to play, but paused

      // Timeout for duration completer
      Future.any([
          durationCompleter.future,
          Future.delayed(const Duration(seconds: 3), () {
            if (!durationCompleter.isCompleted) {
              // Try to get duration via media properties as a fallback if onProgress didn't provide it quickly
              // This is more of a safeguard.
              _player!.getMediaProperties(_currentFilePath!).then((props) {
                if (props?.duration != null) {
                  _currentAudioDuration = Duration(milliseconds: props!.duration!.toInt());
                  durationCompleter.complete(_currentAudioDuration);
                } else {
                  durationCompleter.complete(null); // Still no duration
                }
              }).catchError((_) {
                if(!durationCompleter.isCompleted) durationCompleter.complete(null);
              });
            }
          })
        ]);


      return durationCompleter.future;

    } catch (e) {
      _updatePlayerState(PlayerState.error);
      print("Error loading audio: $e");
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
    // Update disposition stream manually if needed, though onProgress should catch it.
    // For immediate feedback on UI, you might want to push a new PlaybackDisposition
    // _playbackDispositionController.add(PlaybackDisposition(duration: _currentAudioDuration, position: position));
  }

  Future<void> stop() async {
    if (!_isPlayerInitialized) return;
    await _player!.stopPlayer();
    _updatePlayerState(PlayerState.stopped);
     // Reset position to start for next play
    if (!_playbackDispositionController.isClosed) {
       _playbackDispositionController.add(PlaybackDisposition(duration: _currentAudioDuration, position: Duration.zero));
    }
  }

  void _handlePlaybackFinished() {
    _updatePlayerState(PlayerState.completed);
    // Optionally, seek to start and pause to be ready for another play
    // seek(Duration.zero);
    // _updatePlayerState(PlayerState.paused); // if you want it to be ready at start
  }

  Future<void> dispose() async {
    if (_playerSubscription != null) {
      await _playerSubscription!.cancel();
      _playerSubscription = null;
    }
    if (_player != null && _player!.isOpen()) {
      await _player!.closePlayer();
      _player = null;
    }
    if (_currentFilePath != null && await io.File(_currentFilePath!).exists()) {
      try {
        await io.File(_currentFilePath!).delete();
      } catch (e) {
        print("Error deleting temp playback file: $e");
      }
      _currentFilePath = null;
    }
    await _playbackDispositionController.close();
    await _playerStateController.close();
    _isPlayerInitialized = false;
  }
}
