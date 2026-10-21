import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/services/voice_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  bool _obscureApiKey = true;
  bool _isTestingVoice = false;

  final List<Map<String, String>> _availableModels = [
    {
      'id': 'gemini-3.8-flash',
      'name': '⚡ Gemini 3.8 Flash (Newest)',
      'desc': 'Next-gen preview: Ultra-fast reasoning & in-chat OpenUI generative widgets',
    },
    {
      'id': 'gemini-2.5-flash',
      'name': 'Gemini 2.5 Flash',
      'desc': 'Stable production: Fast multimodal & native tool calling',
    },
    {
      'id': 'gemini-2.5-pro',
      'name': 'Gemini 2.5 Pro',
      'desc': 'Deep reasoning for complex multi-envelope and financial portfolio planning',
    },
    {
      'id': 'gemini-2.0-flash',
      'name': 'Gemini 2.0 Flash',
      'desc': 'Next-gen low-latency multimodal Gemini 2.0 release',
    },
    {
      'id': 'gemini-1.5-flash',
      'name': 'Gemini 1.5 Flash',
      'desc': 'Lightweight and ultra-low latency model',
    },
    {
      'id': 'gemini-1.5-pro',
      'name': 'Gemini 1.5 Pro',
      'desc': 'Long context window and complex ledger data analysis',
    },
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _apiKeyController = TextEditingController(text: provider.geminiApiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    await context.read<AppProvider>().setGeminiApiKey(key.isEmpty ? null : key);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(key.isEmpty ? 'Gemini API Key removed.' : 'Gemini API Key saved successfully!'),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _testVoice() async {
    setState(() => _isTestingVoice = true);
    final voice = VoiceService();
    await voice.init();
    await voice.speak(
      'Namaste! Gemini AI Voice is active. Your liquid net balance is in Indian Rupees, and OpenUI dashboard tools are ready.',
    );
    if (mounted) {
      setState(() => _isTestingVoice = false);
    }
  }

  Future<void> _exportBackup() async {
    try {
      final jsonStr = await context.read<AppProvider>().exportBackup();
      final docsDir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName = 'ActualTrack_Backup_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}.json';
      final file = File(p.join(docsDir.path, fileName));
      await file.writeAsString(jsonStr);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 24),
                SizedBox(width: 10),
                Text('Backup Exported'),
              ],
            ),
            content: Text(
              'Your entire database has been safely saved to:\n\n${file.path}\n\nYou can keep this offline backup file safely.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: AppColors.coral),
        );
      }
    }
  }

  void _showImportBackupDialog() {
    final jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Import Backup JSON'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste the contents of your exported JSON backup file below to restore your ledger.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: jsonController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: '{"version": 1, "accounts": [...], "categories": [...]}',
                  hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final raw = jsonController.text.trim();
              if (raw.isEmpty) return;
              try {
                // Validate json
                jsonDecode(raw);
                await context.read<AppProvider>().importBackup(raw);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Backup restored successfully!'),
                      backgroundColor: AppColors.emerald,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Invalid JSON format: $e'), backgroundColor: AppColors.coral),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will remove all accounts, categories, and transactions so you can start completely fresh with zero data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<AppProvider>().clearAllData();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared. Starting fresh!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final hasKey = provider.hasGeminiKey;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings & Preferences', style: AppTypography.heading1),
                    const SizedBox(height: 4),
                    Text(
                      'Configure Gemini AI, voice controls, and local database settings',
                      style: AppTypography.subtitle,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 16, color: AppColors.emerald),
                      const SizedBox(width: 6),
                      Text(
                        '100% Local-First',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 1: Gemini AI Settings
            _buildSectionCard(
              title: 'Gemini AI Advisor & OpenUI',
              subtitle: 'Connect your personal Google Gemini API key to enable conversational ledger operations, voice interaction, and live OpenUI interactive dashboards.',
              icon: Icons.auto_awesome,
              iconColor: AppColors.cobalt,
              children: [
                // API Key Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Google Gemini API Key', style: AppTypography.bodyBold),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: hasKey ? AppColors.emeraldLight : AppColors.coralLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  hasKey ? 'Configured' : 'Missing Key',
                                  style: AppTypography.caption.copyWith(
                                    color: hasKey ? AppColors.emerald : AppColors.coral,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get your free Gemini API key from Google AI Studio (aistudio.google.com). Kept 100% private in your local device SQLite.',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _apiKeyController,
                        obscureText: _obscureApiKey,
                        decoration: InputDecoration(
                          hintText: 'Enter AIzaSy... API key',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.surfaceSecondary,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureApiKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _saveApiKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save Key', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 20),

                // Model Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Model Selection', style: AppTypography.bodyBold),
                    const SizedBox(height: 4),
                    Text(
                      'Choose which Gemini intelligence model powers your conversational finance assistant.',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _availableModels.any((m) => m['id'] == provider.geminiModel)
                              ? provider.geminiModel
                              : _availableModels.first['id'],
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.emerald),
                          items: _availableModels.map((m) {
                            return DropdownMenuItem<String>(
                              value: m['id'],
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(m['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(m['desc']!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              provider.setGeminiModel(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 20),

                // Voice STT / TTS Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Voice & Speech Engine', style: AppTypography.bodyBold),
                          const SizedBox(height: 4),
                          Text(
                            'Enable Speech-to-Text voice dictation and natural Text-to-Speech financial responses.',
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isTestingVoice ? null : _testVoice,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cobalt,
                            side: const BorderSide(color: AppColors.cobalt),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: _isTestingVoice
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.volume_up_rounded, size: 16),
                          label: const Text('Test Voice', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: provider.aiVoiceEnabled,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.emerald,
                          onChanged: (val) => provider.setAiVoiceEnabled(val),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 2: Budgeting & Investment Logic
            _buildSectionCard(
              title: 'Budgeting & Ledger Logic',
              subtitle: 'Zero-based budgeting separates liquid spending cash from fluctuating off-budget investments.',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.emerald,
              children: [
                _buildInfoRow(
                  icon: Icons.currency_rupee,
                  title: 'Default Currency',
                  value: 'Indian Rupee (₹ INR)',
                  description: 'All ledger entries, envelope balances, and analytics are computed in Indian Rupees.',
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),
                _buildInfoRow(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'Investment Separation (Off-Budget)',
                  value: 'Excluded from Net Liquidity',
                  description: 'Accounts marked as "Investment / Vault" (e.g. Zerodha, Groww, Stocks, Mutual Funds, Crypto) fluctuate with market prices and are tracked separately so they never artificially inflate your spendable budget.',
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),
                _buildInfoRow(
                  icon: Icons.all_inbox_rounded,
                  title: 'Zero-Based Envelope Methodology',
                  value: 'Every Rupee Has a Job',
                  description: 'Your monthly income is distributed into custom envelopes (Living, Rent, Food, Travel). Available to Budget drops to ₹0 when all income is allocated.',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 3: Data & Offline Backup Management
            _buildSectionCard(
              title: 'Data Safety & Local Storage',
              subtitle: 'Actual Track operates 100% offline with zero cloud dependency. Your data stays strictly on your machine.',
              icon: Icons.storage_rounded,
              iconColor: AppColors.purple,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_special_outlined, size: 24, color: AppColors.purple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Windows SQLite Database Location', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              Platform.isWindows
                                  ? '%APPDATA%\\com.example\\expense_tracker\\actual_expense_tracker.db'
                                  : 'Application Support / Local App Storage',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Safe upon updates: Installing new versions of Actual Track will NEVER overwrite or delete your database.',
                              style: AppTypography.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.w600, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _exportBackup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cobalt,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.cloud_download_outlined, size: 18),
                      label: const Text('Export Backup (JSON)'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _showImportBackupDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: const Text('Import Backup'),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _confirmClearData,
                      style: TextButton.styleFrom(foregroundColor: AppColors.coral),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: const Text('Clear All Data'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 4: App Info
            Center(
              child: Column(
                children: [
                  Text(
                    'Actual Track v1.1.0 • Local-First Zero-Based Ledger',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Powered by Google Gemini 2.5 Agentic AI & OpenUI Engine',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.heading3.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTypography.bodyBold.copyWith(fontSize: 13)),
                  Text(value, style: AppTypography.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 4),
              Text(description, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
