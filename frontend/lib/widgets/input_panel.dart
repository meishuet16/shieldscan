import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/scan_provider.dart';
import '../theme/app_theme.dart';

class InputPanel extends StatefulWidget {
  const InputPanel({super.key});

  @override
  State<InputPanel> createState() => _InputPanelState();
}

class _InputPanelState extends State<InputPanel> {
  String _selectedType = 'url';
  final _controller = TextEditingController();
  String? _imageBase64;
  String? _imageFileName;

  static const _tabs = [
    _InputTypeTab(
      type: 'url',
      label: 'URL',
      icon: Icons.link_rounded,
      hint: 'https://maybank2u-secure-login.xyz/verify',
    ),
    _InputTypeTab(
      type: 'text',
      label: 'Text',
      icon: Icons.sms_outlined,
      hint: 'Paste a suspicious SMS, WhatsApp message, or email here...',
    ),
    _InputTypeTab(
      type: 'image',
      label: 'Image',
      icon: Icons.image_search_rounded,
      hint: 'https://... or data:image/jpeg;base64,...',
    ),
  ];

  static const _testCases = [
    _DemoCase(
      type: 'url',
      label: 'Phishing URL',
      content: 'https://maybank2u-secure-login.xyz/verify',
    ),
    _DemoCase(
      type: 'text',
      label: 'Prize Scam BM',
      content:
          'Tahniah! Anda memenangi RM5,000. Klik pautan untuk tuntut hadiah anda sekarang!',
    ),
    _DemoCase(
      type: 'url',
      label: 'Legit URL',
      content: 'https://www.maybank2u.com.my',
    ),
    _DemoCase(
      type: 'text',
      label: 'Macau Scam',
      content:
          'Ini Polis DiRaja Malaysia. Akaun bank anda telah disekat. Sila hubungi kami segera atau anda akan ditangkap.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pickImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('For the web demo, paste an image URL or base64 data.'),
        backgroundColor: AppColors.panelAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
        ),
      ),
    );
  }

  void _useTestCase(_DemoCase demo) {
    setState(() {
      _selectedType = demo.type;
      _controller.text = demo.content;
      _imageBase64 = null;
      _imageFileName = null;
    });
  }

  void _submit() {
    final provider = context.read<ScanProvider>();
    final content = _selectedType == 'image'
        ? (_imageBase64 ?? _controller.text.trim())
        : _controller.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter content to scan first.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.panel),
          ),
        ),
      );
      return;
    }

    provider.scan(type: _selectedType, content: content);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanProvider>();
    final isScanning = provider.status == ScanStatus.scanning;
    final currentTab = _tabs.firstWhere((tab) => tab.type == _selectedType);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radar_rounded, color: AppColors.cyan, size: 20),
                const SizedBox(width: 8),
                Text('Scan Console', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (isScanning)
                  Text(
                    'Running',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: AppColors.cyan),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tabs.map((tab) {
                    final width = constraints.maxWidth < 420
                        ? (constraints.maxWidth - 8) / 2
                        : (constraints.maxWidth - 16) / 3;
                    return SizedBox(
                      width: width,
                      child: _TypeButton(
                        tab: tab,
                        selected: _selectedType == tab.type,
                        disabled: isScanning,
                        onTap: () => setState(() => _selectedType = tab.type),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 14),
            if (_selectedType == 'image') ...[
              InkWell(
                onTap: isScanning ? null : _pickImage,
                borderRadius: BorderRadius.circular(AppRadii.panel),
                child: Container(
                  height: 116,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(AppRadii.panel),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _imageBase64 != null
                            ? Icons.check_circle_outline_rounded
                            : Icons.cloud_upload_outlined,
                        color: _imageBase64 != null
                            ? AppColors.green
                            : AppColors.faint,
                        size: 34,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _imageBase64 != null
                            ? 'Image loaded: $_imageFileName'
                            : 'Paste image data below for this web demo',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _imageBase64 != null
                                  ? AppColors.green
                                  : AppColors.muted,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _controller,
              enabled: !isScanning,
              maxLines: _selectedType == 'text' ? 6 : 3,
              minLines: _selectedType == 'url' ? 2 : null,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
              decoration: InputDecoration(
                hintText: currentTab.hint,
                prefixIcon: Icon(currentTab.icon, color: AppColors.faint),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isScanning ? null : _submit,
                icon: isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.muted,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(isScanning ? 'Analyzing content' : 'Run fraud analysis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: AppColors.ink,
                  disabledBackgroundColor: AppColors.stroke,
                  disabledForegroundColor: AppColors.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.panel),
                  ),
                ),
              ),
            ),
            if (provider.status != ScanStatus.idle) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: isScanning ? null : provider.reset,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Clear scan'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Demo samples', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _testCases.map((demo) {
                return ActionChip(
                  avatar: Icon(
                    demo.type == 'url' ? Icons.link_rounded : Icons.sms_outlined,
                    color: AppColors.muted,
                    size: 16,
                  ),
                  label: Text(demo.label),
                  onPressed: isScanning ? null : () => _useTestCase(demo),
                  backgroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.stroke),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.small),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final _InputTypeTab tab;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _TypeButton({
    required this.tab,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.cyan : AppColors.muted;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadii.panel),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyan.withOpacity(0.12) : AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadii.panel),
          border: Border.all(
            color: selected ? AppColors.cyan : AppColors.stroke,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                tab.label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputTypeTab {
  final String type;
  final String label;
  final IconData icon;
  final String hint;

  const _InputTypeTab({
    required this.type,
    required this.label,
    required this.icon,
    required this.hint,
  });
}

class _DemoCase {
  final String type;
  final String label;
  final String content;

  const _DemoCase({
    required this.type,
    required this.label,
    required this.content,
  });
}
