import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'dart:math';
import '../widgets/chess_board_widget.dart';

enum GameMode { puzzle, bot, analysis }

class GameScreen extends StatefulWidget {
  final GameMode mode;

  const GameScreen({super.key, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late chess_lib.Chess _chess;
  String _status = '';
  List<String> _moveHistory = [];
  
  // Exemplo de puzzle simples (Mate em 1)
  // Brancas jogam e dão mate.
  // Posição: Rei branco em e1, Dama branca em d1. Rei preto em e8.
  // Vamos usar um FEN mais interessante.
  // FEN: Mate em 1 para as brancas: 
  // 4k3/8/4K3/8/8/8/8/R7 w - - 0 1 (Torre a1 para a8 mate)
  final String _puzzleFen = '4k3/8/4K3/8/8/8/8/R7 w - - 0 1';

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    if (widget.mode == GameMode.puzzle) {
      _chess = chess_lib.Chess.fromFEN(_puzzleFen);
      _status = 'Puzzle: Brancas jogam e dão mate em 1!';
    } else {
      _chess = chess_lib.Chess();
      _status = 'Partida iniciada. Brancas jogam.';
    }
    _moveHistory.clear();
  }

  void _onMove(String from, String to) {
    final move = _chess.move({'from': from, 'to': to, 'promotion': 'q'});
    
    if (move != null) {
      setState(() {
        _moveHistory.add(move['san'] ?? '$from$to');
        _updateStatus();
      });

      if (!_chess.game_over) {
        if (widget.mode == GameMode.bot && _chess.turn == chess_lib.Color.BLACK) {
          // Bot simples: movimento aleatório após pequeno delay
          Future.delayed(const Duration(milliseconds: 500), () {
            _makeBotMove();
          });
        } else if (widget.mode == GameMode.puzzle) {
           // Verifica se o puzzle foi resolvido (se deu mate)
           if (_chess.in_checkmate) {
             _showPuzzleSuccess();
           } else {
             // Se moveu mas não é mate, pode estar errado no contexto deste puzzle específico
             // Mas por simplicidade, vamos deixar jogar.
           }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movimento inválido!'), duration: Duration(milliseconds: 500)),
      );
    }
  }

  void _makeBotMove() {
    final moves = _chess.moves();
    if (moves.isNotEmpty) {
      final random = Random();
      final moveSan = moves[random.nextInt(moves.length)];
      _chess.move(moveSan);
      setState(() {
        _moveHistory.add(moveSan);
        _updateStatus();
      });
    }
  }

  void _updateStatus() {
    if (_chess.in_checkmate) {
      _status = 'Xeque-mate! ${_chess.turn == chess_lib.Color.WHITE ? "Pretas" : "Brancas"} venceram.';
    } else if (_chess.in_draw) {
      _status = 'Empate!';
    } else if (_chess.in_check) {
      _status = 'Xeque! Vez das ${_chess.turn == chess_lib.Color.WHITE ? "Brancas" : "Pretas"}.';
    } else {
      _status = 'Vez das ${_chess.turn == chess_lib.Color.WHITE ? "Brancas" : "Pretas"}.';
    }
  }

  void _showPuzzleSuccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Parabéns!'),
        content: const Text('Você resolveu o puzzle!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _initGame(); // Reinicia o puzzle
              });
            },
            child: const Text('Tentar Novamente'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getModeTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initGame();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _status,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: ChessBoardWidget(
                fen: _chess.fen,
                onMove: _onMove,
                orientation: chess_lib.Color.WHITE, // Usuário sempre joga de brancas por enquanto
              ),
            ),
          ),
          Container(
            height: 100,
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Histórico:', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _moveHistory.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Chip(
                          label: Text(
                            '${(index / 2).floor() + 1}. ${_moveHistory[index]}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getModeTitle() {
    switch (widget.mode) {
      case GameMode.puzzle: return 'Treino Tático';
      case GameMode.bot: return 'Vs Computador';
      case GameMode.analysis: return 'Análise';
    }
  }
}
