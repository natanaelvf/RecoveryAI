import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Modal bottom sheet for manually adding a lead.
class AddLeadSheet extends StatefulWidget {
  final void Function({
    required String phone,
    String? name,
    String? description,
    String urgency,
    double? estimatedValue,
  }) onSubmit;

  const AddLeadSheet({super.key, required this.onSubmit});

  @override
  State<AddLeadSheet> createState() => _AddLeadSheetState();
}

class _AddLeadSheetState extends State<AddLeadSheet> {
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  String _urgency = 'medium';

  bool get _isValid => _phoneCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Add Lead',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Manually add a missed call lead.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            // Phone (required)
            Text('PHONE NUMBER *',
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '+358 40 XXX XXXX',
                prefixIcon: Icon(Icons.phone_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Name (optional)
            Text('NAME', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Optional',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Issue description (optional)
            Text('ISSUE DESCRIPTION',
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What\'s the issue?',
              ),
            ),
            const SizedBox(height: 16),

            // Urgency
            Text('URGENCY', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Row(
              children: ['low', 'medium', 'high', 'emergency'].map((u) {
                final isActive = _urgency == u;
                final color = _urgencyColor(u, colors);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: u != 'emergency' ? 6 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _urgency = u),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? color.withValues(alpha: 0.15)
                              : colors.bgElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isActive ? color : colors.borderSubtle,
                            width: isActive ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            u[0].toUpperCase() + u.substring(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isActive ? color : colors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Estimated value (optional)
            Text('ESTIMATED VALUE',
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 6),
            TextField(
              controller: _valueCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '350',
                prefixText: '€ ',
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isValid ? 1.0 : 0.5,
                child: ElevatedButton.icon(
                  onPressed: _isValid
                      ? () {
                          widget.onSubmit(
                            phone: _phoneCtrl.text.trim(),
                            name: _nameCtrl.text.trim().isEmpty
                                ? null
                                : _nameCtrl.text.trim(),
                            description: _descCtrl.text.trim().isEmpty
                                ? null
                                : _descCtrl.text.trim(),
                            urgency: _urgency,
                            estimatedValue:
                                double.tryParse(_valueCtrl.text.trim()),
                          );
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Lead'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _urgencyColor(String urgency, AppColors colors) {
    switch (urgency) {
      case 'emergency': return colors.urgencyEmergency;
      case 'high': return colors.urgencyHigh;
      case 'medium': return colors.urgencyMedium;
      case 'low': return colors.urgencyLow;
      default: return colors.urgencyUnknown;
    }
  }
}
