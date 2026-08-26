import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart' hide Level;
import 'package:provider/provider.dart';

import '../ads/ads_controller.dart';
import '../audio/audio_controller.dart';
import '../flame_game/overlays/game_hud.dart';
import '../flame_game/overlays/game_over_overlay.dart';
import '../flame_game/overlays/pause_overlay.dart';
import '../flame_game/overlays/start_play_overlay.dart';
import '../flame_game/overlays/victory_overlay.dart';
import '../flame_game/resistencia_game.dart';
import '../games_services/games_services.dart';
import '../games_services/score.dart';
import '../in_app_purchase/in_app_purchase.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';

class PlaySessionScreen extends StatefulWidget {
  final GameLevel level;

  const PlaySessionScreen(this.level, {super.key});

  @override
  State<PlaySessionScreen> createState() => _PlaySessionScreenState();
}

class _PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreen');

  late DateTime _startOfPlay;
  late final ResistenciaGame _game;

  @override
  void initState() {
    super.initState();
    _startOfPlay = DateTime.now();
    _game = ResistenciaGame(
      level: widget.level,
      audio: context.read<AudioController>(),
      onWon: _playerWon,
    );

    final adsRemoved =
        context.read<InAppPurchaseController?>()?.adRemoval.active ?? false;
    if (!adsRemoved) {
      context.read<AdsController?>()?.preloadAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: GameWidget<ResistenciaGame>(
          game: _game,
          overlayBuilderMap: {
            ResistenciaGame.hudOverlay: (context, game) =>
                GameHud(game: game, onPause: game.pauseGame),
            ResistenciaGame.gameOverOverlay: (context, game) {
              return GameOverOverlay(
                game: game,
                onRetry: game.restartLevel,
                onExit: () => GoRouter.of(context).go('/play'),
              );
            },
            ResistenciaGame.pauseOverlay: (context, game) {
              return PauseOverlay(
                game: game,
                onExit: () => GoRouter.of(context).go('/play'),
              );
            },
            ResistenciaGame.playOverlay: (context, game) {
              return StartPlayOverlay(game: game);
            },
            ResistenciaGame.winOverlay: (context, game) {
              return VictoryOverlay(
                game: game,
                onRetry: game.restartLevel,
                onExit: () => GoRouter.of(context).go('/play'),
                onNext: () {
                  final next = game.level.number + 1;
                  final exists = gameLevels.any(
                    (level) => level.number == next,
                  );
                  if (exists) {
                    GoRouter.of(context).go('/play/session/$next');
                  } else {
                    GoRouter.of(context).go('/play');
                  }
                },
              );
            },
          },
        ),
      ),
    );
  }

  Future<void> _playerWon(int coins) async {
    _log.info('Level ${widget.level.number} won with $coins coins');

    final score = Score(
      widget.level.number,
      widget.level.difficulty + coins * 10,
      DateTime.now().difference(_startOfPlay),
    );

    context.read<PlayerProgress>().setLevelReached(widget.level.number);

    final gamesServicesController = context.read<GamesServicesController?>();
    if (gamesServicesController != null) {
      if (widget.level.awardsAchievement) {
        await gamesServicesController.awardAchievement(
          android: widget.level.achievementIdAndroid!,
          iOS: widget.level.achievementIdIOS!,
        );
      }
      await gamesServicesController.submitLeaderboardScore(score);
    }

    if (!mounted) return;
  }
}
