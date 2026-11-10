import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_message.dart';
import '../services/chat_repository.dart';
import '../services/hardware_interoperability.dart';
import '../services/localization_service.dart';
import '../theme/home_ease_theme.dart';
import 'animated_scale_button.dart';

/// Interactive Serene Hearth In-App Messaging Sheet
/// Matches Stitch Mockup 7 (Messages & In-App Chat)
class InAppChatSheet extends StatefulWidget {
  const InAppChatSheet({
    super.key,
    this.conversationId,
    this.recipientId,
    required this.recipientName,
    required this.recipientRole,
    this.serviceContext,
    this.onCallPressed,
  });

  final String? conversationId;
  final String? recipientId;
  final String recipientName;
  final String recipientRole;
  final String? serviceContext;
  final VoidCallback? onCallPressed;

  static void show(
    BuildContext context, {
    String? conversationId,
    String? recipientId,
    required String recipientName,
    required String recipientRole,
    String? serviceContext,
    VoidCallback? onCallPressed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InAppChatSheet(
        conversationId: conversationId,
        recipientId: recipientId,
        recipientName: recipientName,
        recipientRole: recipientRole,
        serviceContext: serviceContext,
        onCallPressed: onCallPressed,
      ),
    );
  }

  @override
  State<InAppChatSheet> createState() => _InAppChatSheetState();
}

class _InAppChatSheetState extends State<InAppChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _chatRepo = ChatRepository.instance;

  late String _convId;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _convId = ChatRepository.buildConversationId(
      conversationId: widget.conversationId,
      recipientId: widget.recipientId,
      recipientName: widget.recipientName,
    );
    _chatRepo.initConversation(
      conversationId: _convId,
      recipientName: widget.recipientName,
      serviceContext: widget.serviceContext,
      isUrdu: LocalizationService.isUrdu,
    );
    _messages = _chatRepo.getMessages(_convId);
    _chatRepo.addListener(_onChatRepoChanged);
  }

  void _onChatRepoChanged() {
    if (mounted) {
      setState(() {
        _messages = _chatRepo.getMessages(_convId);
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _chatRepo.removeListener(_onChatRepoChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? quickText]) {
    final text = quickText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    if (quickText == null) {
      _messageController.clear();
    }

    _chatRepo.sendMessage(
      conversationId: _convId,
      text: text,
      isMe: true,
      autoReply: true,
      isUrdu: LocalizationService.isUrdu,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = LocalizationService.isUrdu;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    final quickReplies = [
      isUrdu ? 'میں گھر پر موجود ہوں' : 'I am at home',
      isUrdu ? 'کتنی دیر میں پہنچیں گے؟' : 'When will you arrive?',
      isUrdu ? 'براہ کرم کال کریں' : 'Please call me',
    ];

    return Directionality(
      textDirection: LocalizationService.direction,
      child: Container(
        height: screenHeight * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(18, 6, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: HomeEaseTheme.outline.withValues(alpha: 0.6)),
                ),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: HomeEaseTheme.mintSoft,
                        child: Text(
                          widget.recipientName.isNotEmpty ? widget.recipientName[0].toUpperCase() : 'W',
                          style: const TextStyle(
                            color: HomeEaseTheme.brand,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: HomeEaseTheme.statusVerified,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.recipientName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: HomeEaseTheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, color: HomeEaseTheme.statusVerified, size: 15),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${widget.recipientRole} • Abbottabad',
                          style: const TextStyle(fontSize: 12, color: HomeEaseTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.phone_rounded, color: HomeEaseTheme.brand),
                    onPressed: () {
                      if (widget.onCallPressed != null) {
                        widget.onCallPressed!();
                      } else {
                        HardwareInteroperability.dialPhone('+923129845120');
                      }
                    },
                    tooltip: LocalizationService.tr('callWorker'),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.close_rounded, color: HomeEaseTheme.muted),
                    onPressed: () => Navigator.pop(context),
                    tooltip: LocalizationService.tr('close'),
                  ),
                ],
              ),
            ),

            // Messages View
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Quick Action Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quickReplies.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final reply = quickReplies[index];
                  return ActionChip(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    label: Text(
                      reply,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: HomeEaseTheme.brand,
                      ),
                    ),
                    backgroundColor: HomeEaseTheme.mintSoft,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () => _sendMessage(reply),
                  );
                },
              ),
            ),

            // Input Bar with Safe Keyboard Padding
            Container(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 12 + bottomInset),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: HomeEaseTheme.outline.withValues(alpha: 0.6)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: HomeEaseTheme.card,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        icon: const Icon(Icons.mic_none_rounded, color: HomeEaseTheme.muted, size: 22),
                        tooltip: LocalizationService.tr('voiceNote'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(LocalizationService.tr('audioMessagingNote'))),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: LocalizationService.tr('typeMessage'),
                            hintStyle: const TextStyle(fontSize: 13.5, color: HomeEaseTheme.muted),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedScaleTap(
                      onTap: () => _sendMessage(),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: HomeEaseTheme.brand,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 50),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: HomeEaseTheme.brand,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: HomeEaseTheme.brand.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.3),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.time,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.done_all_rounded, color: Color(0xFF99F6E4), size: 14),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, right: 50),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: HomeEaseTheme.outline.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.text,
                style: const TextStyle(color: HomeEaseTheme.textPrimary, fontSize: 13.5, height: 1.3),
              ),
              const SizedBox(height: 3),
              Text(
                msg.time,
                style: const TextStyle(color: HomeEaseTheme.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      );
    }
  }
}
