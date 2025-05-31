import 'dart:async';
import 'package:flutter/material.dart';
import 'ball.dart';

class BucketGameScreen extends StatefulWidget {
  const BucketGameScreen({Key? key}) : super(key: key);

  @override
  _BucketGameScreenState createState() => _BucketGameScreenState();
}

class _BucketGameScreenState extends State<BucketGameScreen> {
  final List<Ball> _balls = [];
  final double _bucketWidth = 120;
  final double _bucketHeight = 90;
  double _bucketX = 150;

  int _score = 0;
  int _level = 1;
  int _lives = 3;
  double _fallSpeed = 3;
  Duration _spawnRate = Duration(seconds: 2);

  bool _isGameStarted = false;
  bool _isPaused = false;
  bool _isGameOver = false;

  String? _missMessage;

  Timer? _fallTimer;
  late double _screenWidth;
  late double _screenHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenWidth = MediaQuery.of(context).size.width;
      _screenHeight = MediaQuery.of(context).size.height;
    });
  }

  void _startGame() {
    setState(() {
      _isGameStarted = true;
      _isPaused = false;
      _isGameOver = false;
      _score = 0;
      _level = 1;
      _lives = 3;
      _balls.clear();
      _missMessage = null;
    });

    _startFallTimer();
    _startSpawnLoop();
  }

  void _startFallTimer() {
    _fallTimer?.cancel();
    _fallTimer = Timer.periodic(Duration(milliseconds: 50), (_) {
      if (_isPaused || _isGameOver || !_isGameStarted) return;

      setState(() {
        _fallSpeed = (2.0 + _level * 0.8).clamp(2.0, 15.0);

        for (var ball in _balls) {
          ball.y += _fallSpeed;
        }

        _balls.removeWhere((ball) {
          final caught = (ball.y >= _screenHeight - _bucketHeight - 30) &&
              (ball.x >= _bucketX && ball.x <= _bucketX + _bucketWidth);

          if (caught) {
            _score += ball.isGift ? 5 : 1;
            int newLevel = (_score ~/ 10) + 1;
            if (newLevel > _level) {
              _level = newLevel;
              _isPaused = true;
            }
          }

          if (ball.y > _screenHeight) {
            _lives--;
            _missMessage = "Missed a ball!";
            Future.delayed(Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _missMessage = null;
                });
              }
            });

            if (_lives <= 0) {
              _isGameOver = true;
              _isPaused = true;
            }
            return true;
          }

          return caught;
        });
      });
    });
  }

  void _startSpawnLoop() {
    void spawnBall() {
      if (!mounted) return;

      if (_isPaused || _isGameOver || !_isGameStarted) {
        Future.delayed(Duration(milliseconds: 200), spawnBall);
        return;
      }

      setState(() {
        int ms = (3000 - _level * 200).clamp(800, 3000);
        _spawnRate = Duration(milliseconds: ms);

        int maxBalls = (3 + _level).clamp(3, 10);
        if (_balls.length < maxBalls) {
          _balls.add(Ball.random(_screenWidth));
        }
      });

      Future.delayed(_spawnRate, spawnBall);
    }

    spawnBall();
  }

  void _moveBucket(double dx) {
    setState(() {
      _bucketX += dx;
      if (_bucketX < 0) _bucketX = 0;
      if (_bucketX > _screenWidth - _bucketWidth) {
        _bucketX = _screenWidth - _bucketWidth;
      }
    });
  }

  void _handleTap() {
    if (!_isGameStarted) return;

    if (_isPaused) {
      setState(() {
        if (_isGameOver) {
          _startGame();
        } else {
          _isPaused = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _fallTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Score
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Score: $_score", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            // Level
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Level: $_level", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            // Lives
            Positioned(
              top: 80,
              left: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Lives: $_lives", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            // Falling balls and gifts
            ..._balls.map((ball) => Positioned(
              top: ball.y,
              left: ball.x,
              child: ball.isGift
                  ? Image.asset('lib/assets/gift.png', width: 30, height: 30)
                  : Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: ball.color,
                  shape: BoxShape.circle,
                ),
              ),
            )),

            // Bucket
            if (_isGameStarted)
              Positioned(
                bottom: 20,
                left: _bucketX,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _moveBucket(details.delta.dx),
                  child: Image.asset(
                    'lib/assets/bucket.png',
                    width: _bucketWidth,
                    height: _bucketHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

            // Game Start Screen
            if (!_isGameStarted)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Bucket Catch Game',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _startGame,
                      child: Text('Start Game', style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ),
              ),

            // Pause or Game Over
            if (_isPaused && _isGameStarted)
              Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _isGameOver ? 'Game Over\nTap to Restart' : 'Level $_level\nTap to Continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // Missed ball message
            if (_missMessage != null)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _missMessage!,
                    style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
