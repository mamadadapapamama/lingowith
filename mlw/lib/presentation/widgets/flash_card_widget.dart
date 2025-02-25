import 'package:flutter/material.dart';

class FlashCardWidget extends StatefulWidget {
  final String front;
  final String back;
  final String pinyin;
  final bool known;
  
  const FlashCardWidget({
    Key? key,
    required this.front,
    required this.back,
    required this.pinyin,
    required this.known,
  }) : super(key: key);

  @override
  State<FlashCardWidget> createState() => _FlashCardWidgetState();
}

class _FlashCardWidgetState extends State<FlashCardWidget> {
  bool _showFront = true;
  
  void _toggleSide() {
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleSide,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: widget.known ? Colors.green : Colors.grey,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _showFront ? Colors.white : Colors.blue.shade50,
                _showFront ? Colors.grey.shade100 : Colors.blue.shade100,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showFront ? '앞면' : '뒷면',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showFront ? widget.front : widget.back,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_showFront && widget.pinyin.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.pinyin,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  Text(
                    '탭하여 ${_showFront ? '뒷면' : '앞면'} 보기',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 