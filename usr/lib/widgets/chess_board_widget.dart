import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;

class ChessBoardWidget extends StatefulWidget {
  final String fen;
  final Function(String from, String to) onMove;
  final chess_lib.Color orientation;

  const ChessBoardWidget({
    super.key,
    required this.fen,
    required this.onMove,
    this.orientation = chess_lib.Color.WHITE,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget> {
  String? _selectedSquare;
  List<String> _validMoves = [];

  @override
  Widget build(BuildContext context) {
    // Parse FEN to get piece positions
    final chess = chess_lib.Chess.fromFEN(widget.fen);
    
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown.shade800, width: 4),
        ),
        child: Column(
          children: List.generate(8, (rankIndex) {
            // Se orientação for preta, inverte as linhas
            final rank = widget.orientation == chess_lib.Color.WHITE 
                ? 7 - rankIndex 
                : rankIndex;
                
            return Expanded(
              child: Row(
                children: List.generate(8, (fileIndex) {
                  // Se orientação for preta, inverte as colunas
                  final file = widget.orientation == chess_lib.Color.WHITE 
                      ? fileIndex 
                      : 7 - fileIndex;
                      
                  final squareName = '${String.fromCharCode(97 + file)}${rank + 1}';
                  final piece = chess.get(squareName);
                  final isLightSquare = (rank + file) % 2 != 0;
                  final isSelected = _selectedSquare == squareName;
                  final isValidMove = _validMoves.contains(squareName);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _handleTap(squareName, chess),
                      child: Container(
                        color: _getSquareColor(isLightSquare, isSelected, isValidMove),
                        child: Center(
                          child: piece != null
                              ? Text(
                                  _getPieceUnicode(piece),
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: _getPieceColor(piece),
                                    // Sombra para destacar peças brancas em fundo claro
                                    shadows: piece.color == chess_lib.Color.WHITE
                                        ? [
                                            const Shadow(
                                              offset: Offset(0, 0),
                                              blurRadius: 2,
                                              color: Colors.black45,
                                            )
                                          ]
                                        : null,
                                  ),
                                )
                              : (isValidMove 
                                  ? Container(
                                      width: 12, 
                                      height: 12, 
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.5),
                                        shape: BoxShape.circle
                                      )
                                    ) 
                                  : null),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _handleTap(String square, chess_lib.Chess chess) {
    if (_selectedSquare == null) {
      // Selecionar peça
      final piece = chess.get(square);
      if (piece != null && piece.color == chess.turn) {
        setState(() {
          _selectedSquare = square;
          // Calcular movimentos válidos para esta peça
          final moves = chess.moves({'square': square, 'verbose': true});
          _validMoves = moves.map((m) => m['to'] as String).toList();
        });
      }
    } else {
      // Tentar mover
      if (_selectedSquare == square) {
        // Deselecionar
        setState(() {
          _selectedSquare = null;
          _validMoves = [];
        });
      } else if (_validMoves.contains(square)) {
        // Mover
        widget.onMove(_selectedSquare!, square);
        setState(() {
          _selectedSquare = null;
          _validMoves = [];
        });
      } else {
        // Clicou em outra casa inválida ou outra peça
        final piece = chess.get(square);
        if (piece != null && piece.color == chess.turn) {
          // Trocar seleção
          setState(() {
            _selectedSquare = square;
            final moves = chess.moves({'square': square, 'verbose': true});
            _validMoves = moves.map((m) => m['to'] as String).toList();
          });
        } else {
          // Cancelar seleção
          setState(() {
            _selectedSquare = null;
            _validMoves = [];
          });
        }
      }
    }
  }

  Color _getSquareColor(bool isLight, bool isSelected, bool isValidMove) {
    if (isSelected) return Colors.yellow.withOpacity(0.7);
    // if (isValidMove) return Colors.green.withOpacity(0.3); // Opcional: pintar a casa toda
    return isLight ? const Color(0xFFF0D9B5) : const Color(0xFFB58863);
  }

  Color _getPieceColor(chess_lib.Piece piece) {
    return piece.color == chess_lib.Color.WHITE ? Colors.white : Colors.black;
  }

  String _getPieceUnicode(chess_lib.Piece piece) {
    switch (piece.type) {
      case chess_lib.PieceType.PAWN:
        return '♟'; // Usando o mesmo glifo para simplificar ou variar se a fonte suportar
      case chess_lib.PieceType.KNIGHT:
        return '♞';
      case chess_lib.PieceType.BISHOP:
        return '♝';
      case chess_lib.PieceType.ROOK:
        return '♜';
      case chess_lib.PieceType.QUEEN:
        return '♛';
      case chess_lib.PieceType.KING:
        return '♚';
      default:
        return '';
    }
  }
}
