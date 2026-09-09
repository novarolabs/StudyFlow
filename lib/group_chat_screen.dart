import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'group_info_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  late final AnimationController _backgroundController;

  bool _sending = false;

  CollectionReference<Map<String, dynamic>>
      get _messagesCollection {
    return _db
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages');
  }

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _senderName(User user) {
    final displayName = user.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email?.trim();

    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'StudyFlow User';
  }

  Future<void> _sendMessage() async {
    final user = _auth.currentUser;

    if (user == null || _sending) {
      return;
    }

    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await _messagesCollection.add({
        'senderId': user.uid,
        'senderName': _senderName(user),
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();

      if (!mounted) return;

      Future.delayed(
        const Duration(milliseconds: 250),
        _scrollToBottom,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1A2940),
          content: Text(
            'Could not send message: $e',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _sending = false;
      });
    }
  }

  void _scrollToBottom() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final date = timestamp.toDate().toLocal();

    final hour = date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  Widget _buildMessage(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> document,
    int index,
  ) {
    final data = document.data() ?? {};

    final currentUser = _auth.currentUser;

    final senderId =
        data['senderId']?.toString() ?? '';

    final senderName =
        data['senderName']?.toString() ??
            'StudyFlow User';

    final text =
        data['text']?.toString() ?? '';

    final timestamp =
        data['createdAt'] is Timestamp
            ? data['createdAt'] as Timestamp
            : null;

    final isMine =
        currentUser != null &&
        senderId == currentUser.uid;

    return TweenAnimationBuilder<double>(
      key: ValueKey(document.id),
      tween: Tween(
        begin: 0,
        end: 1,
      ),
      duration: Duration(
        milliseconds: 300 + math.min(index * 15, 180),
      ),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              isMine
                  ? 35 * (1 - value)
                  : -35 * (1 - value),
              10 * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),
        child: Align(
          alignment: isMine
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                _buildAvatar(
                  senderName,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context)
                                .size
                                .width *
                            0.76,
                  ),
                  padding:
                      const EdgeInsets.fromLTRB(
                    15,
                    11,
                    15,
                    9,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMine
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFFFD95A),
                              Color(0xFFD4AF37),
                            ],
                            begin:
                                Alignment.topLeft,
                            end:
                                Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [
                              Color(0xFF172A48),
                              Color(0xFF101E35),
                            ],
                            begin:
                                Alignment.topLeft,
                            end:
                                Alignment.bottomRight,
                          ),
                    borderRadius:
                        BorderRadius.only(
                      topLeft:
                          const Radius.circular(20),
                      topRight:
                          const Radius.circular(20),
                      bottomLeft:
                          Radius.circular(
                        isMine ? 20 : 5,
                      ),
                      bottomRight:
                          Radius.circular(
                        isMine ? 5 : 20,
                      ),
                    ),
                    border: Border.all(
                      color: isMine
                          ? const Color(
                              0xFFFFD95A,
                            ).withValues(alpha: 0.55)
                          : const Color(
                              0xFF31527E,
                            ).withValues(alpha: 0.65),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isMine
                            ? const Color(
                                0xFFD4AF37,
                              ).withValues(alpha: 0.14)
                            : Colors.black.withValues(
                                alpha: 0.18,
                              ),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isMine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      if (!isMine)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 4,
                          ),
                          child: Text(
                            senderName,
                            style:
                                const TextStyle(
                              color:
                                  Color(0xFFFFD95A),
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      Text(
                        text,
                        style: TextStyle(
                          color: isMine
                              ? const Color(
                                  0xFF071120,
                                )
                              : Colors.white,
                          fontSize: 16,
                          height: 1.35,
                          fontWeight:
                              FontWeight.w400,
                        ),
                      ),
                      if (timestamp != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 5,
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(
                                  timestamp,
                                ),
                                style: TextStyle(
                                  color: isMine
                                      ? const Color(
                                          0xFF435064,
                                        )
                                      : const Color(
                                          0xFF8798B0,
                                        ),
                                  fontSize: 10.5,
                                ),
                              ),
                              if (isMine) ...[
                                const SizedBox(
                                  width: 4,
                                ),
                                const Icon(
                                  Icons.done_all_rounded,
                                  size: 15,
                                  color:
                                      Color(
                                    0xFF304055,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final firstLetter =
        name.trim().isEmpty
            ? '?'
            : name.trim()[0].toUpperCase();

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD4AF37),
            Color(0xFF6E8FC1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFD4AF37),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFD4AF37,
            ).withValues(alpha: 0.18),
            blurRadius: 9,
          ),
        ],
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: const TextStyle(
            color: Color(0xFF081221),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        10,
        8,
        10,
        10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC091426),
        border: Border(
          top: BorderSide(
            color: const Color(
              0xFFD4AF37,
            ).withValues(alpha: 0.16),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.30,
            ),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            _composerButton(
              icon: Icons.add_rounded,
              onTap: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    backgroundColor:
                        Color(0xFF162238),
                    content: Text(
                      'Attachments will be added with Learning Materials.',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF101F36),
                  borderRadius:
                      BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(
                      0xFF31527E,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF2463A8,
                      ).withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: TextField(
                  controller:
                      _messageController,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization:
                      TextCapitalization.sentences,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  onSubmitted: (_) {
                    if (!_sending) {
                      _sendMessage();
                    }
                  },
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Type a message...',
                    hintStyle: TextStyle(
                      color: Color(0xFF72839A),
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _composerButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF14243C),
            border: Border.all(
              color: const Color(0xFF31527E),
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFFD95A),
            size: 27,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD95A),
            Color(0xFFD4AF37),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFD4AF37,
            ).withValues(
              alpha: _sending ? 0.08 : 0.35,
            ),
            blurRadius: _sending ? 5 : 17,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              _sending ? null : _sendMessage,
          customBorder: const CircleBorder(),
          child: Center(
            child: AnimatedSwitcher(
              duration:
                  const Duration(milliseconds: 180),
              child: _sending
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 21,
                      height: 21,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color:
                            Color(0xFF071120),
                      ),
                    )
                  : const Icon(
                      key: ValueKey('send'),
                      Icons.send_rounded,
                      color: Color(0xFF071120),
                      size: 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return CustomPaint(
              painter: _StudyFlowBackgroundPainter(
                progress:
                    _backgroundController.value,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        8,
        4,
        8,
        10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xD9091424),
        border: Border(
          bottom: BorderSide(
            color: const Color(
              0xFFD4AF37,
            ).withValues(alpha: 0.35),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFD4AF37,
            ).withValues(alpha: 0.06),
            blurRadius: 18,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF14243C),
                border: Border.all(
                  color: const Color(0xFFD4AF37),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFD4AF37,
                    ).withValues(alpha: 0.22),
                    blurRadius: 13,
                  ),
                ],
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: Color(0xFFFFD95A),
                size: 25,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration:
                            const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(
                            0xFF4DDB75,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live group chat',
                        style: TextStyle(
                          color:
                              Color(0xFF8FA1B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupInfoScreen(
                      groupId: widget.groupId,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFFFD95A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(
          begin: 0.85,
          end: 1,
        ),
        duration:
            const Duration(milliseconds: 900),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF14243C),
                border: Border.all(
                  color: const Color(
                    0xFFD4AF37,
                  ),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFD4AF37,
                    ).withValues(alpha: 0.20),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.forum_rounded,
                size: 42,
                color: Color(0xFFFFD95A),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Start the conversation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Share ideas, ask questions,\nand learn together.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8293A9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071120),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildAnimatedBackground(),

          Column(
            children: [
              _buildHeader(),

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<
                        Map<String, dynamic>>>(
                  stream: _messagesCollection
                      .orderBy(
                        'createdAt',
                        descending: false,
                      )
                      .snapshots(),
                  builder: (
                    context,
                    snapshot,
                  ) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            24,
                          ),
                          child: Text(
                            'Could not load messages.\n\n'
                            '${snapshot.error}',
                            textAlign:
                                TextAlign.center,
                            style:
                                const TextStyle(
                              color:
                                  Color(0xFFB8C2D1),
                            ),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color:
                              Color(0xFFFFD95A),
                        ),
                      );
                    }

                    final messages =
                        snapshot.data?.docs ?? [];

                    if (messages.isEmpty) {
                      return _buildEmptyState();
                    }

                    WidgetsBinding.instance
                        .addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView.builder(
                      controller:
                          _scrollController,
                      padding:
                          const EdgeInsets.only(
                        top: 16,
                        bottom: 16,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        return _buildMessage(
                          context,
                          messages[index],
                          index,
                        );
                      },
                    );
                  },
                ),
              ),

              _buildComposer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudyFlowBackgroundPainter
    extends CustomPainter {
  final double progress;

  _StudyFlowBackgroundPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint();

    // Deep futuristic base.
    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF050C19),
        Color(0xFF07162B),
        Color(0xFF061020),
      ],
    ).createShader(
      Offset.zero & size,
    );

    canvas.drawRect(
      Offset.zero & size,
      paint,
    );

    // Soft blue glow.
    final blueGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(
            0xFF1465B5,
          ).withValues(alpha: 0.16),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.15,
            size.height * 0.22,
          ),
          radius: size.width * 0.70,
        ),
      );

    canvas.drawCircle(
      Offset(
        size.width * 0.15,
        size.height * 0.22,
      ),
      size.width * 0.70,
      blueGlow,
    );

    // Gold glow.
    final goldGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(
            0xFFD4AF37,
          ).withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.90,
            size.height * 0.72,
          ),
          radius: size.width * 0.55,
        ),
      );

    canvas.drawCircle(
      Offset(
        size.width * 0.90,
        size.height * 0.72,
      ),
      size.width * 0.55,
      goldGlow,
    );

    // Moving futuristic light trails.
    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(
        0xFFD4AF37,
      ).withValues(alpha: 0.18);

    final path = Path();

    final shift =
        progress * size.width * 0.8;

    path.moveTo(
      -size.width * 0.25 + shift,
      size.height * 0.30,
    );

    path.cubicTo(
      size.width * 0.20 + shift,
      size.height * 0.05,
      size.width * 0.45 + shift,
      size.height * 0.55,
      size.width * 1.15 + shift,
      size.height * 0.18,
    );

    canvas.drawPath(
      path,
      trailPaint,
    );

    final secondTrail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(
        0xFF3B8EDB,
      ).withValues(alpha: 0.16);

    final secondPath = Path();

    final reverseShift =
        (1 - progress) *
            size.width *
            0.55;

    secondPath.moveTo(
      -size.width * 0.15 + reverseShift,
      size.height * 0.76,
    );

    secondPath.cubicTo(
      size.width * 0.25 + reverseShift,
      size.height * 0.55,
      size.width * 0.62 + reverseShift,
      size.height * 0.94,
      size.width * 1.15 + reverseShift,
      size.height * 0.65,
    );

    canvas.drawPath(
      secondPath,
      secondTrail,
    );

    // Futuristic grid.
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..color = const Color(
        0xFF4773A5,
      ).withValues(alpha: 0.055);

    const gridSize = 42.0;

    for (
      double x = 0;
      x < size.width;
      x += gridSize
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    for (
      double y = 0;
      y < size.height;
      y += gridSize
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Floating particles.
    final random = math.Random(77);

    for (int i = 0; i < 42; i++) {
      final baseX =
          random.nextDouble() *
              size.width;

      final baseY =
          random.nextDouble() *
              size.height;

      final movement =
          math.sin(
            progress *
                    math.pi *
                    2 +
                i,
          ) *
              8;

      final x = baseX + movement;

      final y =
          baseY +
              math.cos(
                    progress *
                            math.pi *
                            2 +
                        i,
                  ) *
                  6;

      final radius =
          0.7 +
              random.nextDouble() *
                  1.7;

      final isGold = i % 4 == 0;

      final particlePaint = Paint()
        ..color = (isGold
                ? const Color(
                    0xFFFFD95A,
                  )
                : const Color(
                    0xFF4B9BE8,
                  ))
            .withValues(
          alpha:
              0.18 +
                  0.20 *
                      (0.5 +
                          0.5 *
                              math.sin(
                                progress *
                                        math.pi *
                                        2 +
                                    i,
                              )),
        );

      canvas.drawCircle(
        Offset(x, y),
        radius,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _StudyFlowBackgroundPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}
