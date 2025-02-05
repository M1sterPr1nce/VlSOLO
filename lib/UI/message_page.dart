// message_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MessagePage extends StatefulWidget {
  final String friendUid;

  MessagePage({required this.friendUid});

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final User currentUser = FirebaseAuth.instance.currentUser!;
  Map<String, dynamic>? friendData;
  DateTime? lastSignInTime;
  bool isSelectionMode = false;
  List<String> selectedMessageIds = [];

  @override
  void initState() {
    super.initState();
    _fetchFriendData();
  }

  Future<void> _fetchFriendData() async {
    DocumentSnapshot friendSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.friendUid)
        .get();

    setState(() {
      friendData = friendSnapshot['googleData'];
      lastSignInTime = friendSnapshot['lastSignInTime']?.toDate();
    });
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String chatId = currentUser.uid.compareTo(widget.friendUid) < 0
        ? '${currentUser.uid}_${widget.friendUid}'
        : '${widget.friendUid}_${currentUser.uid}';

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection('chats')
        .add({
      'senderId': currentUser.uid,
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  void _deleteSelectedMessages() async {
    String chatId = currentUser.uid.compareTo(widget.friendUid) < 0
        ? '${currentUser.uid}_${widget.friendUid}'
        : '${widget.friendUid}_${currentUser.uid}';

    for (String messageId in selectedMessageIds) {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(chatId)
          .collection('chats')
          .doc(messageId)
          .delete();
    }

    setState(() {
      selectedMessageIds.clear();
      isSelectionMode = false;
    });
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('HH:mm').format(dateTime);
  }

  String formatDate(DateTime dateTime) {
    return DateFormat('d MMM').format(dateTime);
  }

  String getLastSeen() {
    if (lastSignInTime == null) return '';
    final now = DateTime.now();
    if (now.difference(lastSignInTime!).inDays == 0) {
      return 'Last seen at ${DateFormat('HH:mm').format(lastSignInTime!)}';
    } else {
      return 'Last seen on ${formatDate(lastSignInTime!)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    String chatId = currentUser.uid.compareTo(widget.friendUid) < 0
        ? '${currentUser.uid}_${widget.friendUid}'
        : '${widget.friendUid}_${currentUser.uid}';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 21, 21),
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: const Color.fromARGB(255, 0, 0, 0),
            height: 1.5,
          ),
        ),
        title: isSelectionMode
            ? Text('${selectedMessageIds.length} selected')
            : Row(
                children: [
                  if (friendData != null && friendData!['photoUrl'] != null)
                    CircleAvatar(
                      backgroundImage: NetworkImage(friendData!['photoUrl']),
                    ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(friendData?['displayName'] ?? 'Friend', style: TextStyle(color: Colors.white),),
                      Text(
                        getLastSeen(),
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
        actions: isSelectionMode
            ? [
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: _deleteSelectedMessages,
                ),
              ]
            : [],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(chatId)
                  .collection('chats')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<DocumentSnapshot> messages = snapshot.data!.docs;
                String? lastDate;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    var senderId = message['senderId'] ?? '';
                    var isMe = senderId == currentUser.uid;
                    var timestamp = message['timestamp'] as Timestamp?;
                    var date = timestamp != null ? formatDate(timestamp.toDate()) : '';
                    var messageId = message.id;

                    bool showDateHeader = (lastDate != date);
                    lastDate = date;

                    return GestureDetector(
                      onLongPress: isMe
                          ? () {
                              setState(() {
                                isSelectionMode = true;
                                selectedMessageIds.add(messageId);
                              });
                            }
                          : null,
                      onTap: isSelectionMode && selectedMessageIds.contains(messageId)
                          ? () {
                              setState(() {
                                selectedMessageIds.remove(messageId);
                                if (selectedMessageIds.isEmpty) {
                                  isSelectionMode = false;
                                }
                              });
                            }
                          : null,
                      child: Container(
                        color: selectedMessageIds.contains(messageId)
                            ? Colors.grey.withOpacity(0.5)
                            : Colors.transparent,
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (showDateHeader)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 15.0),
                                child: Center(
                                  child: Text(
                                    date,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 7),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color.fromARGB(255, 116, 22, 16)
                                        : const Color.fromARGB(255, 20, 52, 32),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                      bottomLeft: isMe ? Radius.circular(10) : Radius.zero,  // Zero radius makes it pointy
                                      bottomRight: isMe ? Radius.zero : Radius.circular(10), // Zero radius makes it pointy
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          message['message'] ?? '',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: isMe
                                                ? const Color.fromARGB(255, 230, 230, 230)
                                                : const Color.fromARGB(255, 232, 232, 232),
                                          ),
                                        ),
                                      ),
                                      if (timestamp != null)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Text(
                                            formatTimestamp(timestamp),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isMe
                                                  ? const Color.fromARGB(255, 230, 230, 230)
                                                  : const Color.fromARGB(255, 232, 232, 232),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: TextStyle(color: const Color.fromARGB(255, 176, 176, 176)),
                      focusColor: Colors.white,
                      border: OutlineInputBorder(),
                      fillColor: const Color.fromARGB(0, 255, 255, 255),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: const Color.fromARGB(255, 192, 192, 192)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 