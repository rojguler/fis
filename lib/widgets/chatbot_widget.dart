import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chatbot_service.dart';
import '../services/language_service.dart';
import '../services/menu_service.dart';
import '../services/cart_service.dart';
import '../models/chat_message.dart';
import '../main.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> with TickerProviderStateMixin {
  bool _isOpen = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late final AnimationController _animationController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
        final lang = Provider.of<LanguageService>(context, listen: false);
        Provider.of<ChatbotService>(context, listen: false).addWelcomeMessage(lang);
        _scrollToBottom();
      } else {
        _animationController.reverse();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final chatbot = Provider.of<ChatbotService>(context);
    final lang = Provider.of<LanguageService>(context);
    final menu = Provider.of<MenuService>(context);
    final cart = Provider.of<CartService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glassmorphic Chat Window Overlay
          if (_isOpen)
            Positioned(
              bottom: 156 + keyboardHeight, // Keeps it nicely aligned above keyboard and floating button
              right: 16,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.bottomRight,
                child: _buildChatWindow(chatbot, lang, menu, cart, isDark),
              ),
            ),
            
          // Floating Action Button
          Positioned(
            bottom: 90 + keyboardHeight, // Raised standard margin to clear the bottom nav bar
            right: 16,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulseVal = _pulseController.value;
                return Transform.scale(
                  scale: _isOpen ? 1.0 : 1.0 + (pulseVal * 0.06),
                  child: GestureDetector(
                    onTap: _toggleChat,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isOpen
                              ? [Colors.redAccent, Colors.red.shade700]
                              : [IKASColors.primary, IKASColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isOpen ? Colors.red : IKASColors.primary).withOpacity(0.35 + (pulseVal * 0.15)),
                            blurRadius: 10 + (pulseVal * 8),
                            spreadRadius: pulseVal * 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: _isOpen
                            ? const Icon(Icons.close_rounded, color: Colors.white, size: 28, key: ValueKey('close'))
                            : const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 28, key: ValueKey('chat')),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatWindow(
    ChatbotService chatbot,
    LanguageService lang,
    MenuService menu,
    CartService cart,
    bool isDark,
  ) {
    final size = MediaQuery.of(context).size;
    final width = size.width > 400 ? 340.0 : size.width - 32;
    final height = size.height > 600 ? 460.0 : size.height - 160;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: (isDark ? IKASColors.darkSurface : Colors.white).withOpacity(0.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF2E4A38) : IKASColors.border.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E3125).withOpacity(0.9), IKASColors.darkSurface.withOpacity(0.7)]
                        : [IKASColors.chipBg.withOpacity(0.9), Colors.white.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: IKASColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.smart_toy_rounded, color: IKASColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.isTurkish ? 'IKAS Fis Asistanı' : 'IKAS Fis Assistant',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : IKASColors.textDark,
                            ),
                          ),
                          Row(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) {
                                  return Opacity(
                                    opacity: 0.4 + (_pulseController.value * 0.6),
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2ECC71),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 5),
                              Text(
                                lang.isTurkish ? 'Asistan Çevrimiçi' : 'Assistant Online',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: IKASColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Clear Chat
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      color: isDark ? Colors.white70 : IKASColors.textMid,
                      tooltip: lang.isTurkish ? 'Sohbeti Sıfırla' : 'Reset Chat',
                      onPressed: () {
                        chatbot.clearChat(lang);
                        _scrollToBottom();
                      },
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),

              // Chat feed
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatbot.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatbot.messages[index];
                    return _buildMessageBubble(message, lang, menu, cart, isDark);
                  },
                ),
              ),

              // Quick replies
              if (chatbot.messages.isNotEmpty)
                _buildQuickReplies(chatbot.messages.last.quickReplies, chatbot, lang, menu, cart),

              const Divider(height: 1),

              // Input bar
              _buildInputBar(chatbot, lang, menu, cart, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    LanguageService lang,
    MenuService menu,
    CartService cart,
    bool isDark,
  ) {
    final isBot = message.isBot;
    
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isBot
              ? null
              : const LinearGradient(
                  colors: [IKASColors.primary, IKASColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isBot
              ? (isDark ? IKASColors.darkCard : Colors.grey.shade100)
              : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isBot ? 4 : 16),
            bottomRight: Radius.circular(isBot ? 16 : 4),
          ),
          boxShadow: isBot
              ? []
              : [
                  BoxShadow(
                    color: IKASColors.primary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFormattedText(message.text, isBot, isDark),
            if (message.actionType == 'add_to_cart' && message.actionData != null) ...[
              const SizedBox(height: 8),
              _buildActionButton(message.actionData!, lang, menu, cart),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isBot, bool isDark) {
    final textColor = isBot
        ? (isDark ? Colors.white : IKASColors.textDark)
        : Colors.white;

    final parts = text.split('**');
    final List<TextSpan> spans = [];

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (i % 2 == 1) {
        spans.add(TextSpan(
          text: part,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ));
      } else {
        if (part.contains('_')) {
          final italicParts = part.split('_');
          for (var j = 0; j < italicParts.length; j++) {
            final ipart = italicParts[j];
            if (j % 2 == 1) {
              spans.add(TextSpan(
                text: ipart,
                style: GoogleFonts.poppins(fontStyle: FontStyle.italic),
              ));
            } else {
              spans.add(TextSpan(text: ipart));
            }
          }
        } else {
          spans.add(TextSpan(text: part));
        }
      }
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 12,
          height: 1.4,
          color: textColor,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildActionButton(
    String mealId,
    LanguageService lang,
    MenuService menu,
    CartService cart,
  ) {
    final meal = menu.meals.where((m) => m.id == mealId).firstOrNull;
    if (meal == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ElevatedButton.icon(
        onPressed: () {
          cart.addItem(meal);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lang.isTurkish
                    ? '${meal.getLocalizedName(true)} sepete eklendi! 🛒'
                    : '${meal.getLocalizedName(false)} added to cart! 🛒',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.add_shopping_cart_rounded, size: 13),
        label: Text(
          lang.isTurkish ? 'Sepete Ekle' : 'Add to Cart',
          style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: IKASColors.primary,
          elevation: 2,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildQuickReplies(
    List<String> replies,
    ChatbotService chatbot,
    LanguageService lang,
    MenuService menu,
    CartService cart,
  ) {
    if (replies.isEmpty) return const SizedBox();

    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: replies.length,
        itemBuilder: (context, index) {
          final replyText = replies[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              onPressed: () {
                chatbot.sendMessage(replyText, lang, menu, cart);
                _scrollToBottom();
              },
              backgroundColor: IKASColors.primary.withOpacity(0.08),
              side: const BorderSide(color: IKASColors.primary, width: 0.5),
              label: Text(
                replyText,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: IKASColors.primary,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(
    ChatbotService chatbot,
    LanguageService lang,
    MenuService menu,
    CartService cart,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: isDark ? IKASColors.darkSurface : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? IKASColors.darkBg : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    chatbot.sendMessage(val, lang, menu, cart);
                    _textController.clear();
                    _scrollToBottom();
                  }
                },
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? Colors.white : IKASColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: lang.isTurkish ? 'Buraya yazın...' : 'Type here...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: IKASColors.textLight),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () {
              final val = _textController.text;
              if (val.trim().isNotEmpty) {
                chatbot.sendMessage(val, lang, menu, cart);
                _textController.clear();
                _scrollToBottom();
              }
            },
            icon: const Icon(Icons.send_rounded, color: IKASColors.primary),
            visualDensity: VisualDensity.compact,
          )
        ],
      ),
    );
  }
}
