import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

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

enum GameState { notStarted, playing, gameOver }

class _GameScreenState extends State<GameScreen> {
  // Game state
  GameState gameState = GameState.notStarted;
  int score = 0;
  int highScore = 0;

  // Bird physics
  double birdY = 0; // -1 at top, 1 at ground
  double velocity = 0;
  final double gravity = 0.0028;
  final double jumpStrength = -0.038;

  // Pipes (x position from 1.5 to -1.5, gapY center from -0.4 to 0.4)
  List<double> pipeX = [1.2, 2.0];
  List<double> pipeGapY = [0.0, -0.2];
  final double pipeWidth = 0.25; 
  final double pipeGapHeight = 0.42; 

  Timer? gameTimer;

  void startGame() {
    setState(() {
      gameState = GameState.playing;
      birdY = 0;
      velocity = jumpStrength;
      score = 0;
      pipeX = [1.2, 2.0];
      pipeGapY = [
        (Random().nextDouble() - 0.5) * 0.8,
        (Random().nextDouble() - 0.5) * 0.8,
      ];
    });

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
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
      // Apply gravity to bird
      velocity += gravity;
      birdY += velocity;

      // Move pipes
      for (int i = 0; i < pipeX.length; i++) {
        pipeX[i] -= 0.012; // Speed of scrolling

        // Check if passed a pipe for point
        if ((pipeX[i] + 0.012 >= 0) && (pipeX[i] < 0)) {
          score++;
          if (score > highScore) highScore = score;
        }

        // Reset pipe to right side once off-screen left
        if (pipeX[i] < -1.3) {
          pipeX[i] = 1.1;
          pipeGapY[i] = (Random().nextDouble() - 0.5) * 0.8;
        }
      }

      // Check Collisions
      _checkCollisions();
    });
  }

  void _checkCollisions() {
    // Ground collision (0.85 screen height)
    if (birdY > 0.82 || birdY < -1.1) {
      _triggerGameOver();
      return;
    }

    // Pipe collision checks
    for (int i = 0; i < pipeX.length; i++) {
      // Check if bird is within pipe's X bounds
      if (pipeX[i] - (pipeWidth / 2) < 0.1 && pipeX[i] + (pipeWidth / 2) > -0.1) {
        double topPipeBottom = pipeGapY[i] - (pipeGapHeight / 2);
        double bottomPipeTop = pipeGapY[i] + (pipeGapHeight / 2);

        // Hit top pipe or bottom pipe
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
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: jump,
      child: Scaffold(
        body: Column(
          children: [
            // Sky & Gameplay Area (80% of screen height)
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
                    // Top Pipe
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
                    // Bottom Pipe
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
                      angle: velocity * 8.0, // Rotates down when falling
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
                            // Bird Eye
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
                            // Beak
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

                  // Score Counter Overlay
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

                  // Start Screen Prompt
                  if (gameState == GameState.notStarted)
                    const Center(
                      child: Text(
                        'TAP TO JUMP & START',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ),

                  // Game Over Screen
                  if (gameState == GameState.gameOver)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
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

            // Grass / Ground Section (20% of screen height)
            Expanded(
              flex: 1,
              child: Container(
                color: const Color(0xFF8D6E63), // Dirt Color
                child: Column(
                  children: [
                    Container(
                      height: 16,
                      color: const Color(0xFF388E3C), // Top Grass
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'FLAPPY BIRD FLUTTER',
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
