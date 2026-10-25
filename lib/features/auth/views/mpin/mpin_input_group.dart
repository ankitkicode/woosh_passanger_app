import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MpinInputGroup extends StatefulWidget {
  final Function(String) onChanged;

  const MpinInputGroup({super.key, required this.onChanged});

  @override
  State<MpinInputGroup> createState() => _MpinInputGroupState();
}

class _MpinInputGroupState extends State<MpinInputGroup> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
      widget.onChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden TextField
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
          // Visible OTP Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              final isFocused = _focusNode.hasFocus && _controller.text.length == index ||
                  (_controller.text.length == 4 && index == 3 && _focusNode.hasFocus);
              final text = index < _controller.text.length ? '●' : ''; // Obscured

              return Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused ? AppColors.primaryPink : Colors.transparent,
                    width: isFocused ? 2 : 1,
                  ),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
