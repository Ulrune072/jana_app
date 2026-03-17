import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/app_theme.dart';
import '../../core/api_client.dart';
import '../../shared/models/chat_message.dart';

// ─── State ────────────────────────────────────────────────────────────────────
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? sessionId;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.sessionId,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? sessionId,
    String? error,
  }) => ChatState(
    messages:  messages  ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    sessionId: sessionId ?? this.sessionId,
    error:     error,
  );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Dio _api = createApiClient();

  ChatNotifier() : super(const ChatState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      // get or create session
      final sessionRes = await _api.get('/api/chatbot/session');
      final sessionId  = sessionRes.data['session']['id'] as String;

      // load message history
      final historyRes = await _api.get('/api/chatbot/history',
        queryParameters: {'session_id': sessionId});
      final messages   = (historyRes.data['messages'] as List)
          .map((j) => ChatMessage.fromJson(j))
          .toList();

      // if no history yet, add Medi's greeting
      final allMessages = messages.isEmpty
          ? [
              ChatMessage(
                role:    'assistant',
                content: "Hi there! I'm your personal Health Assistant **Medi** 👋\nHow can I help you today?",
                sentAt:  DateTime.now().toIso8601String(),
              ),
            ]
          : messages;

      state = state.copyWith(
        isLoading: false,
        sessionId: sessionId,
        messages:  allMessages,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['error'] ?? 'Could not connect to Medi',
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.sessionId == null) return;

    // add user message immediately so UI feels responsive
    final userMsg = ChatMessage(
      role: 'user', content: text, sentAt: DateTime.now().toIso8601String());
    state = state.copyWith(
      messages:  [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      final res = await _api.post('/api/chatbot/message', data: {
        'session_id': state.sessionId,
        'message':    text,
      });

      final reply = ChatMessage(
        role:    'assistant',
        content: res.data['reply'] as String,
        sentAt:  DateTime.now().toIso8601String(),
      );

      state = state.copyWith(
        messages:  [...state.messages, reply],
        isLoading: false,
      );
    } on DioException catch (e) {
      final errMsg = ChatMessage(
        role: 'assistant',
        content: 'Sorry, something went wrong. Try again in a moment.',
        sentAt: DateTime.now().toIso8601String(),
      );
      state = state.copyWith(
        messages:  [...state.messages, errMsg],
        isLoading: false,
      );
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);

// ─── Screen ───────────────────────────────────────────────────────────────────
class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final _controller  = TextEditingController();
  final _scrollCtrl  = ScrollController();

  // The 7 quick-reply buttons from the Figma prototype
  static const _quickReplies = [
    '1) Show my latest health data',
    '2) Check my heart rate',
    '3) Show my blood pressure',
    '4) Check my glucose level',
    '5) Show today\'s oxygen saturation',
    '6) Just chat',
    '7) Other',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    // scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);

    // auto-scroll when new messages arrive
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (next.messages.length != prev?.messages.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessages(chat)),
            if (chat.isLoading) _buildTypingIndicator(),
            _buildQuickReplies(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        // Medi robot icon
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(text: const TextSpan(
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
            children: [
              TextSpan(text: 'Bot '),
              TextSpan(text: 'Medi', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          )),
          Row(children: [
            Container(width: 8, height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('online',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ]),
      ]),
    );
  }

  Widget _buildMessages(ChatState chat) {
    if (chat.error != null) {
      return Center(child: Text(chat.error!,
        style: const TextStyle(color: AppColors.textSecondary)));
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: chat.messages.length,
      itemBuilder: (_, i) => _MessageBubble(message: chat.messages[i]),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 64, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.botBubble,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text('Medi is thinking...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      ),
    );
  }

  // tappable numbered shortcut buttons - from the Figma prototype
  Widget _buildQuickReplies() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: _quickReplies.map((q) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => _send(q[0]), // just send the number
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDDDDD)),
              ),
              child: Text(q[0], // just the number as the button label
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.userBubble)),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.send,
            onSubmitted: _send,
            decoration: InputDecoration(
              hintText: 'Reply to Medi',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _send(_controller.text),
          child: Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(
              color: AppColors.userBubble, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.userBubble : AppColors.botBubble,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4  : 18),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.grey.shade300, shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.grey, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
