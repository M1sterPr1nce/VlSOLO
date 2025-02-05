import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_page.dart';
import 'profilescreen.dart';

class AddFriendsPage extends StatefulWidget {
  @override
  _AddFriendsPageState createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  List<DocumentSnapshot> _pinnedFriends = [];
  Map<String, String> _friendRequestStatus = {};
  bool _isLoading = false;
  List<DocumentSnapshot> _incomingRequests = [];

  // Theme colors
  final backgroundColor = Color(0xFF1E1E1E);
  final surfaceColor = Color(0xFF2D2D2D);
  final primaryColor = Color(0xFF4A90E2);
  final textColor = Colors.white;
  final secondaryTextColor = Colors.white70;

  @override
  void initState() {
    super.initState();
    _loadPinnedFriends();
    _loadIncomingRequests();
  }

  Future<void> _loadIncomingRequests() async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      QuerySnapshot requestSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('friendRequests')
          .where('status', isEqualTo: 'pending')
          .get();

      List<DocumentSnapshot> requests = [];
      for (var requestDoc in requestSnapshot.docs) {
        String requesterUid = requestDoc.id;
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(requesterUid)
            .get();

        if (userDoc.exists) {
          requests.add(userDoc);
        }
      }

      setState(() {
        _incomingRequests = requests;
      });
    } catch (e) {
      print("Error loading friend requests: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load friend requests'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadPinnedFriends() async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      QuerySnapshot pinnedFriendsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('pinnedFriends')
          .get();

      List<DocumentSnapshot> pinnedUsers = [];
      for (var friendDoc in pinnedFriendsSnapshot.docs) {
        String friendUid = friendDoc['friendUID'];
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendUid)
            .get();

        if (userDoc.exists) {
          pinnedUsers.add(userDoc);
        }
      }

      setState(() {
        _pinnedFriends = pinnedUsers;
      });
    } catch (e) {
      print("Error loading pinned friends: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load pinned friends'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _searchUsers() async {
    setState(() {
      _isLoading = true;
    });

    String friendUID = _searchController.text.trim();

    if (friendUID.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('friendUID', isEqualTo: friendUID)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No user found with this FriendUID'),
            backgroundColor: surfaceColor,
          ),
        );
      }

      setState(() {
        _searchResults = querySnapshot.docs;
        _isLoading = false;
      });

      await _checkFriendRequestStatus();
    } catch (e) {
      print("Error searching users: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to search users'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkFriendRequestStatus() async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    for (var user in _searchResults) {
      String friendUid = user['uid'];

      try {
        DocumentSnapshot sentRequestDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendUid)
            .collection('friendRequests')
            .doc(currentUserUid)
            .get();

        DocumentSnapshot receivedRequestDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .collection('friendRequests')
            .doc(friendUid)
            .get();

        if (receivedRequestDoc.exists) {
          setState(() {
            _friendRequestStatus[friendUid] = receivedRequestDoc['status'] == 'pending'
                ? 'incoming'
                : 'accepted';
          });
        } else if (sentRequestDoc.exists) {
          setState(() {
            _friendRequestStatus[friendUid] = sentRequestDoc['status'];
          });
        } else {
          setState(() {
            _friendRequestStatus[friendUid] = 'none';
          });
        }
      } catch (e) {
        print('Error checking friend request status: $e');
      }
    }
  }

  Future<void> _sendFriendRequest(String friendUid) async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .collection('friendRequests')
          .doc(currentUserUid)
          .set({
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _friendRequestStatus[friendUid] = 'pending';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error sending friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send friend request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptFriendRequest(String friendUid) async {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('friendRequests')
          .doc(friendUid)
          .update({
        'status': 'accepted',
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserUid)
          .collection('pinnedFriends')
          .doc(friendUid)
          .set({'friendUID': friendUid});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .collection('pinnedFriends')
          .doc(currentUserUid)
          .set({'friendUID': currentUserUid});

      var user = _incomingRequests.firstWhere((user) => user['uid'] == friendUid);

      setState(() {
        _pinnedFriends.add(user);
        _incomingRequests.removeWhere((req) => req['uid'] == friendUid);
        _friendRequestStatus[friendUid] = 'accepted';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request accepted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error accepting friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept friend request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildUserTile(DocumentSnapshot user, String friendUid) {
    bool isPinnedFriend = _pinnedFriends.any((friend) => friend['uid'] == friendUid);
    String requestStatus = _friendRequestStatus[friendUid] ?? 'none';

    return Card(
      color: surfaceColor,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        contentPadding: EdgeInsets.all(8),
        leading: user['photoURL'] != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(user['photoURL']),
                radius: 25,
                backgroundColor: primaryColor,
              )
            : CircleAvatar(
                child: Icon(Icons.account_circle, color: textColor),
                radius: 25,
                backgroundColor: primaryColor.withOpacity(0.7),
              ),
        title: Text(
          user['displayName'] ?? 'Unnamed',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "FriendUID: ${user['friendUID']}",
          style: TextStyle(color: secondaryTextColor),
        ),
        trailing: _buildActionButton(isPinnedFriend, requestStatus, friendUid),
      ),
    );
  }

  Widget _buildActionButton(bool isPinnedFriend, String requestStatus, String friendUid) {
    if (isPinnedFriend) {
      return ElevatedButton(
        onPressed: () => _goToMessagePage(friendUid),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textColor,
          padding: EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Text('Message'),
      );
    }

    switch (requestStatus) {
      case 'incoming':
        return ElevatedButton(
          onPressed: () => _acceptFriendRequest(friendUid),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: textColor,
            padding: EdgeInsets.symmetric(horizontal: 20),
          ),
          child: Text('Accept Request'),
        );
      case 'pending':
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: surfaceColor,
            foregroundColor: secondaryTextColor,
            padding: EdgeInsets.symmetric(horizontal: 20),
          ),
          child: Text('Request Sent'),
        );
      default:
        return ElevatedButton(
          onPressed: () => _sendFriendRequest(friendUid),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: textColor,
            padding: EdgeInsets.symmetric(horizontal: 20),
          ),
          child: Text('Send Request'),
        );
    }
  }

  void _goToMessagePage(String friendUid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(friendUid: friendUid),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        cardColor: surfaceColor,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          surface: surfaceColor,
          background: backgroundColor,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: surfaceColor,
          title: Text("Add Friends", style: TextStyle(color: textColor)),
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Search by FriendUID',
                  labelStyle: TextStyle(color: secondaryTextColor),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _searchUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: textColor,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text('Search'),
              ),
              SizedBox(height: 24),
              if (_pinnedFriends.isNotEmpty) ...[
                Text(
                  'Pinned Friends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _pinnedFriends.length,
                  itemBuilder: (context, index) {
                    var friend = _pinnedFriends[index];
                    return _buildUserTile(friend, friend['uid']);
                  },
                ),
              ],
              if (_incomingRequests.isNotEmpty) ...[
                SizedBox(height: 24),
                Text(
                  'Friend Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _incomingRequests.length,
                  itemBuilder: (context, index) {
                    var requester = _incomingRequests[index];
                    return _buildUserTile(requester, requester['uid']);
                  },
                ),
              ],
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      var user = _searchResults[index];
                      String friendUid = user['uid'];
                      return _buildUserTile(user, friendUid);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}