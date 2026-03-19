import 'package:flutter/material.dart';

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  String _display = '0';
  String _expression = '';
  double? _firstOperand;
  String? _operator;
  bool _newNumber = true;

  void _onDigit(String digit) {
    setState(() {
      if (_newNumber) {
        _display = digit;
        _newNumber = false;
      } else {
        _display = _display == '0' ? digit : _display + digit;
      }
    });
  }

  void _onDecimal() {
    setState(() {
      if (_newNumber) {
        _display = '0.';
        _newNumber = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      if (_firstOperand != null && !_newNumber) {
        _calculate();
      }
      _firstOperand = double.tryParse(_display);
      _operator = op;
      _expression = '$_display $op';
      _newNumber = true;
    });
  }

  void _calculate() {
    if (_firstOperand == null || _operator == null) return;
    final second = double.tryParse(_display) ?? 0;
    double result;

    switch (_operator) {
      case '+':
        result = _firstOperand! + second;
      case '-':
        result = _firstOperand! - second;
      case '×':
        result = _firstOperand! * second;
      case '÷':
        result = second == 0 ? double.nan : _firstOperand! / second;
      default:
        return;
    }

    setState(() {
      _expression = '';
      if (result.isNaN) {
        _display = 'Fehler';
      } else if (result == result.truncateToDouble()) {
        _display = result.toInt().toString();
      } else {
        _display = result.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      _firstOperand = null;
      _operator = null;
      _newNumber = true;
    });
  }

  void _onEquals() => _calculate();

  void _onClear() {
    setState(() {
      _display = '0';
      _expression = '';
      _firstOperand = null;
      _operator = null;
      _newNumber = true;
    });
  }

  void _onPercent() {
    setState(() {
      final val = double.tryParse(_display) ?? 0;
      _display = (val / 100).toString();
      _newNumber = true;
    });
  }

  void _onNegate() {
    setState(() {
      if (_display != '0') {
        _display = _display.startsWith('-') ? _display.substring(1) : '-$_display';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          // Display
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_expression.isNotEmpty)
                    Text(
                      _expression,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                    ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _display,
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w300),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Buttons
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  _buildRow(['C', '±', '%', '÷']),
                  _buildRow(['7', '8', '9', '×']),
                  _buildRow(['4', '5', '6', '-']),
                  _buildRow(['1', '2', '3', '+']),
                  _buildRow(['0', '.', '=']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((btn) {
          final isWide = btn == '0';
          return Expanded(
            flex: isWide ? 2 : 1,
            child: _CalcButton(
              label: btn,
              isOperator: ['÷', '×', '-', '+', '='].contains(btn),
              isFunction: ['C', '±', '%'].contains(btn),
              onTap: () {
                switch (btn) {
                  case 'C': _onClear();
                  case '±': _onNegate();
                  case '%': _onPercent();
                  case '÷' || '×' || '-' || '+': _onOperator(btn);
                  case '=': _onEquals();
                  case '.': _onDecimal();
                  default: _onDigit(btn);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CalcButton extends StatefulWidget {
  final String label;
  final bool isOperator;
  final bool isFunction;
  final VoidCallback onTap;

  const _CalcButton({
    required this.label,
    this.isOperator = false,
    this.isFunction = false,
    required this.onTap,
  });

  @override
  State<_CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<_CalcButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    if (widget.isOperator) {
      bg = _pressing ? Colors.blueAccent : Colors.blueAccent.withValues(alpha: 0.6);
      fg = Colors.white;
    } else if (widget.isFunction) {
      bg = _pressing ? Colors.white24 : Colors.white.withValues(alpha: 0.12);
      fg = Colors.white;
    } else {
      bg = _pressing ? Colors.white12 : Colors.white.withValues(alpha: 0.06);
      fg = Colors.white;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) {
        setState(() => _pressing = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressing = false),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
