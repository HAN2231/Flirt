import 'package:cupertino_text_button/cupertino_text_button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logintest/components/chat_bubble.dart';
import 'package:logintest/chat/chat_service.dart';
import 'package:logintest/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class ChatPage extends StatefulWidget {
  final String voteId;
  final String voterId;
  final String receiverEmail;
  final String hint1;
  final String hint2;
  final String hint3;
  final String greeting;

  const ChatPage({
    super.key,
    required this.voteId,
    required this.receiverEmail,
    required this.voterId,
    required this.hint1,
    required this.hint2,
    required this.hint3,
    required this.greeting,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  FocusNode myFocusNode = FocusNode();
  late ValueNotifier<int> chatCountNotifier;
  bool isPremiumUser = false;

  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    chatCountNotifier = ValueNotifier<int>(20);
    _loadChatCount();
    _checkPremiumStatus();
    _markMessagesAsRead();

    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        // 추가 로직을 여기에 작성할 수 있습니다.
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        _scrollPosition = _scrollController.position.pixels;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    chatCountNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadChatCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String chatRoomID = widget.voteId;
    String currentUserID = _authService.getCurrentUser()?.uid ?? "";
    chatCountNotifier.value = prefs.getInt('chatCount_${chatRoomID}_$currentUserID') ?? 20;
  }

  Future<void> _saveChatCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String chatRoomID = widget.voteId;
    String currentUserID = _authService.getCurrentUser()?.uid ?? "";
    await prefs.setInt('chatCount_${chatRoomID}_$currentUserID', chatCountNotifier.value);
  }

  Future<void> _markMessagesAsRead() async {
    String chatRoomID = widget.voteId;
    String currentUserID = _authService.getCurrentUser()?.uid ?? "";

    QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .where('receiverID', isEqualTo: currentUserID)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messagesSnapshot.docs) {
      doc.reference.update({'isRead': true});
    }

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomID)
        .update({'isRead': true});
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty && (isPremiumUser || chatCountNotifier.value > 0)) {
      String currentUserID = _authService.getCurrentUser()?.uid ?? "";
      await _chatService.sendMessage(
        widget.voteId,
        widget.voterId,
        _messageController.text,
        currentUserID,
        widget.greeting,
      );
      _messageController.clear();
      _scrollToBottom();
      if (!isPremiumUser) {
        chatCountNotifier.value--;
        _saveChatCount();
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null && (isPremiumUser || chatCountNotifier.value > 0)) {
      String currentUserID = _authService.getCurrentUser()?.uid ?? "";
      await _chatService.sendImage(
        widget.voteId,
        widget.voterId,
        image.path,
        currentUserID,
        widget.greeting,
      );
      _scrollToBottom();
      if (!isPremiumUser) {
        chatCountNotifier.value--;
        _saveChatCount();
      }
    }
  }

  Future<void> _checkPremiumStatus() async {
    String currentUserID = _authService.getCurrentUser()?.uid ?? "";
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserID)
        .get();

    if (userSnapshot.exists) {
      Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
      setState(() {
        isPremiumUser = userData['premium'] == 'on';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '상대방 힌트: #${widget.hint1}, #${widget.hint2}, #${widget.hint3}',
              style: TextStyle(fontSize: 18.sp),
            ),
          ],
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          CupertinoTextButton.icon(
            icon: CupertinoIcons.bars,
            size: 30,
            color: Colors.black,
            onTap: () {
              showModalBottomSheet(
                context: context,
                constraints: const BoxConstraints(
                  maxHeight: 100,
                ),
                builder: (context) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ListView(
                      children: [
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(3.0),
                          ),
                        ),
                        ListTile(
                          title: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '신고하기',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700),
                              ),
                              Icon(
                                Icons.wb_twilight_rounded,
                                color: Colors.red,
                              )
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            showModalBottomSheet(
                              context: context,
                              constraints: BoxConstraints(
                                maxHeight:
                                MediaQuery.of(context).size.height * 0.3,
                              ),
                              builder: (context) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                  ),
                                  padding:
                                  const EdgeInsets.fromLTRB(0, 16, 0, 0),
                                  child: ListView(
                                    children: [
                                      const Text(
                                        '신고 사유 선택',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      ListTile(
                                        title: const Text(
                                          '스팸홍보 또는 도배글',
                                          textAlign: TextAlign.left,
                                        ),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: Colors.white,
                                                title: Text(
                                                  '신고 완료',
                                                  style: TextStyle(
                                                    fontSize: 20.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                content: const Text(
                                                    '신고해 주셔서 감사합니다. \n해당 게시물이 검토될 것입니다.'),
                                                actions: [
                                                  TextButton(
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                      MaterialStateProperty
                                                          .all(Colors.blue),
                                                    ),
                                                    child: Text(
                                                      '확인',
                                                      style: TextStyle(
                                                          fontSize: 14.sp,
                                                          color: Colors.white),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      ListTile(
                                        title: const Text('혐오 발언 또는 심벌'),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: Colors.white,
                                                title: Text(
                                                  '신고 완료',
                                                  style: TextStyle(
                                                    fontSize: 20.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                content: const Text(
                                                    '신고해 주셔서 감사합니다. \n해당 게시물이 검토될 것입니다.'),
                                                actions: [
                                                  TextButton(
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                      MaterialStateProperty
                                                          .all(Colors.blue),
                                                    ),
                                                    child: Text(
                                                      '확인',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14.sp),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      ListTile(
                                        title: const Text('음란물 또는 불법정보 포함'),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: Colors.white,
                                                title: Text(
                                                  '신고 완료',
                                                  style: TextStyle(
                                                    fontSize: 20.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                content: const Text(
                                                    '신고해 주셔서 감사합니다. \n해당 게시물이 검토될 것입니다.'),
                                                actions: [
                                                  TextButton(
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                      MaterialStateProperty
                                                          .all(Colors.blue),
                                                    ),
                                                    child: Text(
                                                      '확인',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14.sp),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          SizedBox(
            width: 10,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: Colors.blue,
            ),
            padding: const EdgeInsets.all(6.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '  채팅 카드 \n  ${widget.greeting}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                if (!isPremiumUser)
                  ValueListenableBuilder<int>(
                    valueListenable: chatCountNotifier,
                    builder: (context, value, child) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '남은 횟수\n$value/20',
                            style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: Padding(
                padding: EdgeInsets.zero,
                child: _buildMessageList(),
              ),
            ),
          ),
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    String senderID = _authService.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: _chatService.getMessages(widget.voteId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading..");
        }
        List<DocumentSnapshot> documents = snapshot.data!.docs;

        if (!_initialScrollDone && documents.isNotEmpty) {
          _initialScrollDone = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: documents.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _buildMessageItem(documents[index], index == 0 ? null : documents[index - 1]);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc, DocumentSnapshot? previousDoc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderID'] == _authService.getCurrentUser()!.uid;
    String? imageUrl = data.containsKey('imageUrl') ? data['imageUrl'] : null;
    DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
    String formattedTime = _formatTimestamp(timestamp);

    DateTime? previousTimestamp;
    if (previousDoc != null) {
      Map<String, dynamic> previousData = previousDoc.data() as Map<String, dynamic>;
      previousTimestamp = (previousData['timestamp'] as Timestamp).toDate();
    }

    bool showTimestamp = previousTimestamp == null || previousTimestamp.minute != timestamp.minute;

    return Container(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(
            message: data["message"],
            isCurrentUser: isCurrentUser,
            imageUrl: imageUrl,
            timestamp: showTimestamp ? formattedTime : null,
          )
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    int hour = timestamp.hour;
    int minute = timestamp.minute;
    String period = hour < 12 ? "오전" : "오후";
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    String minuteStr = minute.toString().padLeft(2, '0');
    return "$period $hour:$minuteStr";
  }

  Widget _buildUserInput() {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: (isPremiumUser || chatCountNotifier.value > 0)
                ? () {
              showModalBottomSheet(
                backgroundColor: Colors.white,
                context: context,
                builder: (BuildContext context) {
                  return SafeArea(
                    child: Wrap(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 5, 0, 0),
                          child: ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text(
                              '앨범에서 선택',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ),
                        ListTile(
                          leading: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 5, 0, 0),
                            child: const Icon(Icons.photo_camera),
                          ),
                          title: const Text(
                            '카메라로 찍기',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _pickImage(ImageSource.camera);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }
                : null,
            icon: const Icon(
              Icons.add,
              size: 30,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: CupertinoTextField(
              padding: EdgeInsets.all(8),
              controller: _messageController,
              inputFormatters: [
                LengthLimitingTextInputFormatter(200),
              ],
              placeholder: " 메시지 보내기...",
              placeholderStyle: TextStyle(color: Colors.grey),
              style: TextStyle(color: Colors.black),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: CupertinoColors.extraLightBackgroundGray,
                border: Border.all(
                  color: CupertinoColors.extraLightBackgroundGray,
                  width: 2,
                ),
              ),
              cursorColor: CupertinoColors.systemGrey,
              focusNode: myFocusNode,
              enabled: isPremiumUser || chatCountNotifier.value > 0,
            ),
          ),
          Container(
            width: 40,
            decoration: const BoxDecoration(
              color: Color(0xff67ad5b),
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: IconButton(
              onPressed: (isPremiumUser || chatCountNotifier.value > 0)
                  ? sendMessage
                  : null,
              icon: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
}