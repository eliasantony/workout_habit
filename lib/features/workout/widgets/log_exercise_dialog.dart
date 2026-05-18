import 'package:flutter/material.dart';

class LogExerciseDialog extends StatefulWidget {
  final int quickAddSmall;
  final int quickAddLarge;
  final Function(int) onAdd;

  const LogExerciseDialog({
    super.key,
    required this.quickAddSmall,
    required this.quickAddLarge,
    required this.onAdd,
  });

  @override
  State<LogExerciseDialog> createState() => _LogExerciseDialogState();
}

class _LogExerciseDialogState extends State<LogExerciseDialog> {
  final TextEditingController _textController = TextEditingController();
  bool _isCustomMode = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        _isCustomMode ? 'Custom Amount' : 'Add Water',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isCustomMode
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('How much did you drink?'),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _textController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '250',
                        suffixText: 'ml',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _AddOption(
                            icon: Icons.local_drink_rounded,
                            label: '100 ml',
                            onTap: () => widget.onAdd(100),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AddOption(
                            icon: Icons.water_drop_rounded,
                            label: '${widget.quickAddSmall} ml',
                            onTap: () => widget.onAdd(widget.quickAddSmall),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AddOption(
                            icon: Icons.water_drop_outlined,
                            label: '${widget.quickAddLarge} ml',
                            onTap: () => widget.onAdd(widget.quickAddLarge),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AddOption(
                            icon: Icons.liquor_rounded,
                            label: '1 Liter',
                            onTap: () => widget.onAdd(1000),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AddOption(
                      icon: Icons.edit_rounded,
                      label: 'Custom Amount',
                      color: theme.colorScheme.primary,
                      isWide: true,
                      onTap: () => setState(() => _isCustomMode = true),
                    ),
                  ],
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_isCustomMode) {
              setState(() => _isCustomMode = false);
            } else {
              Navigator.pop(context);
            }
          },
          child: Text(_isCustomMode ? 'Back' : 'Cancel'),
        ),
        if (_isCustomMode)
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(_textController.text);
              if (amount != null && amount > 0) {
                widget.onAdd(amount);
              }
            },
            child: const Text('Add'),
          ),
      ],
    );
  }
}

class _AddOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isWide;

  const _AddOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = color ?? theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: isWide ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: isWide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: activeColor),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: activeColor,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 28, color: activeColor),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: activeColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
