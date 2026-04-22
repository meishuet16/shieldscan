import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/scan_provider.dart';

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

  final _tabs = [
    {'type': 'url', 'label': '🔗 URL', 'hint': 'Paste suspicious URL here...'},
    {'type': 'text', 'label': '💬 Text', 'hint': 'Paste suspicious message here...'},
    {'type': 'image', 'label': '🖼️ Image', 'hint': ''},
  ];

  final _testCases = [
    {'type': 'url', 'label': '🔴 Phishing URL', 'content': 'https://maybank2u-secure-login.xyz/verify'},
    {'type': 'text', 'label': '🔴 Prize Scam (BM)', 'content': 'Tahniah! Anda memenangi RM5,000. Klik pautan untuk tuntut hadiah anda sekarang!'},
    {'type': 'url', 'label': '🟢 Legit URL', 'content': 'https://www.maybank2u.com.my'},
    {'type': 'text', 'label': '🔴 Macau Scam', 'content': 'Ini Polis DiRaja Malaysia. Akaun bank anda telah disekat. Sila hubungi kami segera atau anda akan ditangkap.'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Web-compatible file pick using HTML input
    // Since we're Flutter Web, use a simple base64 approach
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image upload: paste base64 image data or use URL for demo'),
        backgroundColor: Color(0xFF1E2D45),
      ),
    );
  }

  void _useTestCase(Map<String, String> tc) {
    setState(() {
      _selectedType = tc['type']!;
      _controller.text = tc['content']!;
      _imageBase64 = null;
    });
  }

  void _submit() {
    final provider = context.read<ScanProvider>();
    final content = _selectedType == 'image'
        ? (_imageBase64 ?? _controller.text)
        : _controller.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter content to scan'),
          backgroundColor: Color(0xFFFF3B5C),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel header
            Row(
              children: [
                const Icon(Icons.radar, color: Color(0xFF00D4FF), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Scan for Fraud',
                  style: GoogleFonts.spaceMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Type selector
            Row(
              children: _tabs.map((tab) {
                final selected = _selectedType == tab['type'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = tab['type']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF00D4FF).withOpacity(0.15)
                            : const Color(0xFF1A2232),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF00D4FF)
                              : const Color(0xFF2D3748),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        tab['label']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          color: selected
                              ? const Color(0xFF00D4FF)
                              : const Color(0xFF8B9AB5),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Input field
            if (_selectedType != 'image')
              TextField(
                controller: _controller,
                maxLines: _selectedType == 'text' ? 5 : 2,
                style: GoogleFonts.spaceMono(
                  fontSize: 13,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: _tabs.firstWhere(
                      (t) => t['type'] == _selectedType)['hint'],
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF4A5568),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D1321),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1321),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF1E2D45),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _imageBase64 != null
                            ? Icons.check_circle_outline
                            : Icons.cloud_upload_outlined,
                        color: _imageBase64 != null
                            ? const Color(0xFF00FF94)
                            : const Color(0xFF4A5568),
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _imageBase64 != null
                            ? 'Image loaded: $_imageFileName'
                            : 'Click to upload screenshot\n(WhatsApp, SMS, phishing page)',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: _imageBase64 != null
                              ? const Color(0xFF00FF94)
                              : const Color(0xFF4A5568),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Image URL fallback
            if (_selectedType == 'image') ...[
              const SizedBox(height: 8),
              Text(
                'Or paste image URL / base64 data:',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: const Color(0xFF4A5568),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _controller,
                style: GoogleFonts.spaceMono(fontSize: 12, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://... or data:image/jpeg;base64,...',
                  hintStyle: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF4A5568),
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D1321),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1E2D45)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Scan button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isScanning ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: const Color(0xFF0A0E1A),
                  disabledBackgroundColor: const Color(0xFF1E2D45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isScanning
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF8B9AB5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Scanning...',
                            style: GoogleFonts.spaceMono(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8B9AB5),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '🔍  Run Fraud Analysis',
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),

            if (provider.status != ScanStatus.idle) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.read<ScanProvider>().reset(),
                child: Text(
                  'Clear & scan again',
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF4A5568),
                    fontSize: 13,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(color: Color(0xFF1E2D45)),
            const SizedBox(height: 12),

            // Test cases
            Text(
              'Quick Test Cases:',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: const Color(0xFF8B9AB5),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _testCases.map((tc) {
                return GestureDetector(
                  onTap: () => _useTestCase(tc.cast<String, String>()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1321),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2D3748)),
                    ),
                    child: Text(
                      tc['label']!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: const Color(0xFF8B9AB5),
                      ),
                    ),
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
