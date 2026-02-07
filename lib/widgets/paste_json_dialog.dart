import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/utils.dart';
import '../models/models.dart';

class PasteJsonDialog extends StatefulWidget {
  const PasteJsonDialog({Key? key}) : super(key: key);

  @override
  State<PasteJsonDialog> createState() => _PasteJsonDialogState();
}

class _PasteJsonDialogState extends State<PasteJsonDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _formatJson() {
    final text = _controller.text;
    if (text.isEmpty) return;

    try {
      // Basic cleaning for formatting purpose: remove markdown blocks if present
      String cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        final lines = cleaned.split('\n');
        if (lines.length >= 2 && lines.first.startsWith('```') && lines.last.startsWith('```')) {
          cleaned = lines.sublist(1, lines.length - 1).join('\n').trim();
        }
      }

      dynamic decoded = jsonDecode(cleaned);
      const encoder = JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(decoded);
      
      setState(() {
        _controller.text = formatted;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Format error: ${e.toString()}';
      });
    }
  }

  void _importJson() {
    final text = _controller.text;
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter JSON content';
      });
      return;
    }

    try {
      final recipe = RecipeJsonParser.parse(text);
      Navigator.pop(context, recipe);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入菜谱 JSON'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 10,
              autofocus: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                hintText: '在此粘贴 JSON (支持 markdown 格式)...',
                border: OutlineInputBorder(),
                filled: true,
                // Using a slightly off-white background to distinguish code area
                fillColor: Color(0xFFFAFAFA),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline, 
                      size: 16, 
                      color: Theme.of(context).colorScheme.error
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error, 
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: _formatJson,
              child: const Text('格式化'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _importJson,
              child: const Text('导入'),
            ),
          ],
        ),
      ],
    );
  }
}
