import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../core/openui/openui_models.dart';
import '../../core/openui/openui_parser.dart';
import '../../core/openui/openui_renderer.dart';
import '../../core/services/gemini_ai_service.dart';
import '../../core/services/voice_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_provider.dart';
import '../../providers/navigation_provider.dart';

class AiAdvisorScreen extends StatefulWidget {
  const AiAdvisorScreen({super.key});

  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _isListening = false;
  String? _currentlySpeakingId;

  static const List<Map<String, String>> _modelOptions = [
    {
      'id': 'gemini-3.8-flash',
      'label': '⚡ Gemini 3.8 Flash (Newest)',
    },
    {
      'id': 'gemini-2.5-flash',
      'label': 'Gemini 2.5 Flash',
    },
    {
      'id': 'gemini-2.5-pro',
      'label': 'Gemini 2.5 Pro',
    },
    {
      'id': 'gemini-2.0-flash',
      'label': 'Gemini 2.0 Flash',
    },
    {
      'id': 'gemini-1.5-flash',
      'label': 'Gemini 1.5 Flash',
    },
    {
      'id': 'gemini-1.5-pro',
      'label': 'Gemini 1.5 Pro',
    },
  ];

  static const List<String> _suggestedPrompts = [
    '📊 Show 30-day cash flow chart',
    '🍩 Show category spending breakdown',
    '✉️ Check budget envelopes',
    '📈 Show investment portfolio',
    '⚡ I spent ₹450 on lunch via Cash',
    '🔄 Transfer ₹5,000 from Checking to Savings',
    '🎯 How is my financial health score?',
  ];

  @override
  void initState() {
    super.initState();
    const welcomeText = '''
Namaste! I am **Actual AI**, powered by **Gemini 3.8 Flash** and **OpenUI**.

I can generate real-time interactive financial charts, check your envelope budgets, and propose transactions for your approval.

Try asking:
• *"Show my 30-day cash flow graph"*
• *"Show spending breakdown donut chart"*
• *"I spent ₹350 at Starbucks from Main Checking"*
• *"Transfer ₹10,000 from Checking to Zerodha"*

```openui
kpi = Metric(label: "Spendable Liquid Cash", value: "₹24,850.00", badge: "Spendable", icon: "wallet")
```
''';
    _messages.add(
      ChatMessage(
        id: 'welcome',
        role: 'model',
        text: welcomeText,
        timestamp: DateTime.now(),
        segments: OpenUiParser.parseMessage(welcomeText),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    VoiceService.instance.stopSpeaking();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? textToSend]) async {
    final text = textToSend ?? _promptController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _promptController.clear();
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
      segments: [OpenUiSegment.markdown(text)],
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    final provider = context.read<AppProvider>();
    final reply = await GeminiAiService.instance.sendMessage(
      prompt: text,
      history: _messages,
      provider: provider,
    );

    if (mounted) {
      setState(() {
        _messages.add(reply);
        _isLoading = false;
      });
      _scrollToBottom();

      // Auto-play voice if voice is enabled
      if (provider.aiVoiceEnabled && reply.text.isNotEmpty) {
        _playSpeech(reply.id, reply.text);
      }
    }
  }

  void _toggleVoiceInput() {
    if (_isListening) {
      VoiceService.instance.stopListening();
      setState(() => _isListening = false);
    } else {
      VoiceService.instance.startListening(
        onResult: (text) {
          setState(() {
            _promptController.text = text;
          });
        },
        onDone: () {
          setState(() => _isListening = false);
        },
      );
      setState(() => _isListening = true);
    }
  }

  void _playSpeech(String msgId, String rawText) {
    if (_currentlySpeakingId == msgId) {
      VoiceService.instance.stopSpeaking();
      setState(() => _currentlySpeakingId = null);
    } else {
      // Strip openui code fences before reading aloud so speech sounds natural
      final cleanText = rawText.replaceAll(RegExp(r'```(?:openui|OpenUI)[\s\S]*?```'), '').trim();
      VoiceService.instance.speak(cleanText);
      setState(() => _currentlySpeakingId = msgId);
    }
  }

  Future<void> _handleActionConfirmed(OpenUiActionFormNode form) async {
    final provider = context.read<AppProvider>();
    final success = await GeminiAiService.instance.executeActionFormNode(form, provider);
    if (mounted) {
      setState(() {});
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✔ ${form.title} confirmed and saved to ledger!'),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to apply action. Please check parameters.'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleActionCancelled(OpenUiActionFormNode form) {
    setState(() {
      form.status = OpenUiActionStatus.cancelled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Action cancelled. Database unchanged.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            _buildTopBar(provider),
            const Divider(height: 1, color: AppColors.border),

            // Main Chat Stream (Full width)
            Expanded(
              child: _buildMessagesList(),
            ),

            if (_isLoading) _buildLoadingIndicator(),

            // Suggested Chips
            _buildSuggestedChips(),

            // Composer Area
            _buildInputArea(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppProvider provider) {
    final currentModel = provider.geminiModel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/app_icon.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.auto_awesome,
                      color: AppColors.emerald,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Actual AI Advisor', style: AppTypography.heading3.copyWith(fontSize: 15)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.cobaltLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'OpenUI',
                          style: TextStyle(
                            color: AppColors.cobalt,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Zero-based financial intelligence • Generative UI',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          // Right Controls: Model Selector Dropdown & Actions
          Row(
            children: [
              // Model Quick Selector Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _modelOptions.any((m) => m['id'] == currentModel)
                        ? currentModel
                        : _modelOptions.first['id'],
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.emerald),
                    items: _modelOptions.map((m) {
                      return DropdownMenuItem<String>(
                        value: m['id'],
                        child: Text(
                          m['label']!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
              const SizedBox(width: 8),

              // Clear chat button
              IconButton(
                tooltip: 'Clear Conversation',
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
                onPressed: () {
                  setState(() {
                    _messages.clear();
                    _messages.add(
                      ChatMessage(
                        id: 'welcome_reset',
                        role: 'model',
                        text: 'Conversation reset. What would you like to analyze or log?',
                        timestamp: DateTime.now(),
                        segments: OpenUiParser.parseMessage('Conversation reset. What would you like to analyze or log?'),
                      ),
                    );
                  });
                },
              ),

              // Settings button
              IconButton(
                tooltip: 'AI & API Settings',
                icon: const Icon(Icons.settings_outlined, size: 20, color: AppColors.textSecondary),
                onPressed: () => context.read<NavigationProvider>().setIndex(7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedChips() {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestedPrompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _suggestedPrompts[index];
          return ActionChip(
            label: Text(
              prompt,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _sendMessage(prompt),
          );
        },
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg.role == 'user';
        return _buildMessageRow(msg, isUser);
      },
    );
  }

  Widget _buildMessageRow(ChatMessage msg, bool isUser) {
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 60),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.emerald,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: AppColors.softShadow,
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    // Model Message (Card with Markdown & OpenUI Components)
    final isSpeaking = _currentlySpeakingId == msg.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 20, right: 40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar of Assistant Message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: AppColors.emerald),
                    const SizedBox(width: 8),
                    Text('Actual AI', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.read<AppProvider>().geminiModel,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.emerald),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: isSpeaking ? 'Stop Voice' : 'Listen via Voice',
                      icon: Icon(
                        isSpeaking ? Icons.volume_up_rounded : Icons.volume_mute_outlined,
                        size: 18,
                        color: isSpeaking ? AppColors.emerald : AppColors.textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _playSpeech(msg.id, msg.text),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      Formatters.shortTime(msg.timestamp),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Message Content: Renders Markdown & OpenUI Segments
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: msg.segments.map((segment) {
                if (!segment.isOpenUi && segment.markdownText != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MarkdownBody(
                      data: segment.markdownText!,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: AppTypography.body.copyWith(height: 1.5, fontSize: 13.5),
                        h1: AppTypography.heading1.copyWith(fontSize: 20),
                        h2: AppTypography.heading2.copyWith(fontSize: 17),
                        h3: AppTypography.heading3.copyWith(fontSize: 15),
                        strong: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        em: const TextStyle(fontStyle: FontStyle.italic),
                        blockquote: const TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        blockquoteDecoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          border: const Border(left: BorderSide(color: AppColors.emerald, width: 3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        code: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          backgroundColor: AppColors.surfaceSecondary,
                          color: AppColors.cobalt,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        listBullet: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.bold),
                        tableBorder: TableBorder.all(color: AppColors.border, width: 1),
                        tableHead: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                  );
                } else if (segment.isOpenUi) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: segment.nodes.map((node) {
                      return OpenUiRenderer(
                        node: node,
                        onActionConfirmed: _handleActionConfirmed,
                        onActionCancelled: _handleActionCancelled,
                      );
                    }).toList(),
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.only(left: 20, bottom: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald),
          ),
          const SizedBox(width: 12),
          Text(
            'Actual AI is analyzing and generating OpenUI components...',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          if (_isListening)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.coralLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, size: 14, color: AppColors.coral),
                  SizedBox(width: 6),
                  Text(
                    'Listening... Speak in Hindi or English (tap mic to stop)',
                    style: TextStyle(color: AppColors.coral, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Push to Talk Mic Button
              IconButton(
                tooltip: _isListening ? 'Stop Listening' : 'Push-to-Talk Voice',
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: _isListening ? AppColors.coral : AppColors.emerald,
                  size: 22,
                ),
                onPressed: _toggleVoiceInput,
              ),
              const SizedBox(width: 8),

              // Text Field
              Expanded(
                child: TextField(
                  controller: _promptController,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Ask anything or type e.g. "Add ₹450 for coffee"...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (val) => _sendMessage(),
                ),
              ),

              const SizedBox(width: 8),

              // Send Button
              IconButton(
                tooltip: 'Send Prompt',
                icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  padding: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : () => _sendMessage(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
