import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FlappyBirdApp());
}

class FlappyBirdApp extends StatelessWidget {
  const FlappyBirdApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum GameState { notStarted, playing, paused, gameOver }

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  // Game state
  GameState gameState = GameState.notStarted;
  int score = 0;
  int highScore = 0;

  // Balanced Physics (The mode you hit 16 on)
  double birdY = 0; // -1 at top, 1 at ground
  double velocity = 0;
  final double gravity = 0.0008; 
  final double jumpStrength = -0.018; 

  // Pipes setup
  List<double> pipeX = [1.3, 2.2];
  List<double> pipeGapY = [0.0, -0.1];
  final double pipeWidth = 0.24; 
  final double pipeGapHeight = 0.52; 

  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHighScore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    gameTimer?.cancel();
    super.dispose();
  }

  // Auto-pause when phone calls, home button, or app switching happens
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) &&
        gameState == GameState.playing) {
      pauseGame();
    }
  }

  // Load High Score from phone storage
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('flappy_high_score') ?? 0;
    });
  }

  // Save High Score to phone storage
  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('flappy_high_score', highScore);
  }

  void startGame() {
    setState(() {
      gameState = GameState.playing;
      birdY = 0;
      velocity = jumpStrength;
      score = 0;
      pipeX = [1.3, 2.2];
      pipeGapY = [
        (Random().nextDouble() - 0.5) * 0.5,
        (Random().nextDouble() - 0.5) * 0.5,
      ];
    });

    _runGameLoop();
  }

  void _runGameLoop() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
  }

  void pauseGame() {
    if (gameState == GameState.playing) {
      gameTimer?.cancel();
      setState(() {
        gameState = GameState.paused;
      });
    }
  }

  void resumeGame() {
    if (gameState == GameState.paused) {
      setState(() {
        gameState = GameState.playing;
      });
      _runGameLoop();
    }
  }

  void jump() {
    if (gameState == GameState.notStarted) {
      startGame();
    } else if (gameState == GameState.playing) {
      setState(() {
        velocity = jumpStrength;
      });
    } else if (gameState == GameState.gameOver) {
      startGame();
    }
  }

  void _updateGame() {
    setState(() {
      velocity += gravity;
      birdY += velocity;

      for (int i = 0; i < pipeX.length; i++) {
        pipeX[i] -= 0.008;

        if ((pipeX[i] + 0.008 >= 0) && (pipeX[i] < 0)) {
          score++;
          if (score > highScore) {
            highScore = score;
            _saveHighScore();
          }
        }

        if (pipeX[i] < -1.4) {
          pipeX[i] = 1.2;
          pipeGapY[i] = (Random().nextDouble() - 0.5) * 0.5;
        }
      }

      _checkCollisions();
    });
  }

  void _checkCollisions() {
    if (birdY > 0.82 || birdY < -1.1) {
      _triggerGameOver();
      return;
    }

    for (int i = 0; i < pipeX.length; i++) {
      if (pipeX[i] - (pipeWidth / 2) < 0.08 && pipeX[i] + (pipeWidth / 2) > -0.08) {
        double topPipeBottom = pipeGapY[i] - (pipeGapHeight / 2);
        double bottomPipeTop = pipeGapY[i] + (pipeGapHeight / 2);

        if (birdY < topPipeBottom || birdY > bottomPipeTop) {
          _triggerGameOver();
          return;
        }
      }
    }
  }

  void _triggerGameOver() {
    gameTimer?.cancel();
    setState(() {
      gameState = GameState.gameOver;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: jump,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  // Sky Background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF4DD0E1), Color(0xFF80DEEA)],
                      ),
                    ),
                  ),

                  // Pipes
                  for (int i = 0; i < pipeX.length; i++) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 0),
                      alignment: Alignment(pipeX[i], -1.1),
                      child: Container(
                        width: MediaQuery.of(context).size.width * (pipeWidth / 2),
                        height: (MediaQuery.of(context).size.height * 0.4) * (1 + pipeGapY[i] - pipeGapHeight / 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          border: Border.all(color: Colors.black, width: 2.5),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 0),
                      alignment: Alignment(pipeX[i], 1.1),
                      child: Container(
                        width: MediaQuery.of(context).size.width * (pipeWidth / 2),
                        height: (MediaQuery.of(context).size.height * 0.4) * (1 - pipeGapY[i] - pipeGapHeight / 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          border: Border.all(color: Colors.black, width: 2.5),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Bird
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 0),
                    alignment: Alignment(0, birdY),
                    child: Transform.rotate(
                      angle: velocity * 14.0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 10,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.all(Radius.circular(2)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Score Display
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(offset: Offset(3, 3), color: Colors.black45, blurRadius: 2),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Pause Button (visible during active gameplay)
                  if (gameState == GameState.playing)
                    Positioned(
                      top: 45,
                      right: 20,
                      child: GestureDetector(
                        onTap: pauseGame,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.pause, color: Colors.white, size: 28),
                        ),
                      ),
                    ),

                  // Start Screen Overlay
                  if (gameState == GameState.notStarted)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'TAP TO JUMP & START',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'HIGH SCORE: $highScore',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.yellowAccent,
                              shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Pause Screen Overlay
                  if (gameState == GameState.paused)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'GAME PAUSED',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0288D1),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              onPressed: resumeGame,
                              icon: const Icon(Icons.play_arrow, color: Colors.white),
                              label: const Text('RESUME', style: TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Game Over Screen Overlay
                  if (gameState == GameState.gameOver)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'GAME OVER',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                            const SizedBox(height: 10),
                            Text('Score: $score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                            Text('High Score: $highScore', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              onPressed: startGame,
                              child: const Text('PLAY AGAIN', style: TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Grass / Ground Section
            Expanded(
              flex: 1,
              child: Container(
                color: const Color(0xFF8D6E63),
                child: Column(
                  children: [
                    Container(
                      height: 16,
                      color: const Color(0xFF388E3C),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'FLAPPY BIRD MASKY',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
