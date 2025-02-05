// ProfileScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AddFriends.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  final String profileUid;
  const ProfilePage({super.key, required this.profileUid});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<String?> _getProfileImageUrl() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profileUid)
        .get();
    String? photoUrl = userDoc['googleData']?['photoUrl'];
    return photoUrl?.replaceAll("s96-c", "s900");
  }

  Future<String?> _getUserName() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.profileUid)
        .get();
    return userDoc['displayName'] as String?;
  }

  Future<String?> _getFriendUID() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc('B5WjuD6eO6UdpJY39K7t5rKnJQC3')
        .get();
    return userDoc['friendUID'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      body: Container(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Back Button with Custom Styling
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.white.withOpacity(0.8), size: 20),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Profile Container
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Color(0xFF2C2C3E),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: Offset(0, 10),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Settings button moved to top right
                                  Align(
                                    alignment: Alignment.topRight,

                                  ),
                                  const SizedBox(height: 10),
                                  // Profile Image
                                  FutureBuilder<String?>(
                                    future: _getProfileImageUrl(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const CircularProgressIndicator(color: Colors.white);
                                      }
                                      return Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: Offset(0, 5),
                                            )
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundImage: NetworkImage(snapshot.data ?? 'https://via.placeholder.com/150'),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                  // User Name
                                  FutureBuilder<String?>(
                                    future: _getUserName(),
                                    builder: (context, snapshot) {
                                      return Text(
                                        snapshot.data ?? 'Unknown User',
                                        style: TextStyle(
                                          fontSize: 24, 
                                          fontWeight: FontWeight.w600, 
                                          color: Colors.white.withOpacity(0.9),
                                          letterSpacing: 0.5,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Friend UID Section
                          // Friend UID Section
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20.0),
  child: Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Color(0xFF2C2C3E),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 15,
          offset: Offset(0, 10),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.people,
              color: Colors.white.withOpacity(0.7),
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              "Friend UID", 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
              )
            ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: FutureBuilder<String?>(
            future: _getFriendUID(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.7),
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              
              final uid = snapshot.data ?? 'No friend UID found.';
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      uid,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontFamily: 'Roboto Mono',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (uid != 'No friend UID found.') {
                        await Clipboard.setData(ClipboardData(text: uid));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('UID copied to clipboard'),
                            backgroundColor: Color(0xFF2C2C3E),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.all(20),
                          ),
                        );
                      }
                    },
                    child: Icon(
                      Icons.copy,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                  ),
                ],
              );
            },
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
                ],
              ),
            ),
            if (FirebaseAuth.instance.currentUser?.uid == widget.profileUid)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5D3FD3),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => AddFriendsPage())
                    );
                  },
                  child: Text(
                    "Add Friend", 
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 255, 255, 255)
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}