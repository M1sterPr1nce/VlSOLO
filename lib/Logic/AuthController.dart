import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Helper function to generate a random 6-character string for friendUID
  String _generateRandomFriendUID() {
    const _characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random _random = Random();
    return List.generate(6, (index) => _characters[_random.nextInt(_characters.length)]).join();
  }

  // Generate a unique friendUID by checking Firestore
  Future<String> _generateUniqueFriendUID() async {
    String friendUID = _generateRandomFriendUID();
    
    // Check Firestore to ensure the friendUID is unique
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    QuerySnapshot querySnapshot = await users.where('friendUID', isEqualTo: friendUID).get();

    // If the friendUID already exists, generate a new one
    while (querySnapshot.docs.isNotEmpty) {
      friendUID = _generateRandomFriendUID();
      querySnapshot = await users.where('friendUID', isEqualTo: friendUID).get();
    }

    return friendUID;
  }

  // Link Google account to email/password account
  Future<void> linkGoogleAccountToEmailPassword(String email, String password) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
        await user.linkWithCredential(credential);
        print("Google account successfully linked with email & password");
      }
    } catch (e) {
      print("Error linking Google account: $e");
    }
  }

  // Save user's name immediately after signing up
  Future<void> saveUserName(String uid, String name) async {
    try {
      CollectionReference users = FirebaseFirestore.instance.collection('users');

      await users.doc(uid).set({
        'displayName': name,
      }, SetOptions(merge: true));
    
      print("User name saved successfully");
    } catch (e) {
      print("Error saving user name: $e");
    }
  }

  // Sign up with email and password
  Future<User?> signUpWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User user = userCredential.user!;

      // Send email verification
      await user.sendEmailVerification();

      // Generate a unique friend UID and save user data
      String friendUID = await _generateUniqueFriendUID();
      await _saveUserData(user, friendUID);

      return user;
    } catch (e) {
      print("Error signing up with email/password: $e");
      return null;
    }
  }

  // Sign in with email and password (only if email is verified)
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User user = userCredential.user!;

      if (!user.emailVerified) {
        await user.sendEmailVerification();
        print("Email is not verified. Verification email sent again.");
        return null;
      }

      await _saveUserData(user, null); // No need to generate friendUID again
      return user;
    } catch (e) {
      print("Error signing in with email/password: $e");
      return null;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut(); // Force sign out before new login attempt
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
      if (googleUser == null) return null; // User canceled sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      User user = userCredential.user!;

      // Check if the user exists in Firestore, and if not, generate and save the friendUID
      await _saveGoogleUserData(user, googleUser);
      return user;
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }

  // Forgot Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent.");
    } catch (e) {
      print("Error sending password reset email: $e");
    }
  }

  // Save basic user data (for email sign-in)
  Future<void> _saveUserData(User user, String? friendUID) async {
    try {
      CollectionReference users = FirebaseFirestore.instance.collection('users');
      DocumentSnapshot userDoc = await users.doc(user.uid).get();

      // If user does not exist, set createdAt timestamp and the friendUID
      if (!userDoc.exists) {
        await users.doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? 'Unnamed',
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(), // Set only for new users
          'lastSignInTime': FieldValue.serverTimestamp(),
          'provider': 'email',
          'emailVerified': user.emailVerified,
          'friendUID': friendUID, // Save the generated friendUID
        });
      } else {
        // If user exists, update only the lastSignInTime
        await users.doc(user.uid).update({
          'lastSignInTime': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error saving user data: $e");
      throw e;
    }
  }

  // Save Google-specific user data including friendUID if the user is new
  Future<void> _saveGoogleUserData(User user, GoogleSignInAccount googleUser) async {
    try {
      CollectionReference users = FirebaseFirestore.instance.collection('users');
      DocumentSnapshot userDoc = await users.doc(user.uid).get();

      // If the user does not exist, generate a new friendUID and save their data
      if (!userDoc.exists) {
        String friendUID = await _generateUniqueFriendUID(); // Generate the unique friendUID
        await users.doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? googleUser.displayName ?? 'Unnamed',
          'photoURL': user.photoURL ?? googleUser.photoUrl,
          'createdAt': FieldValue.serverTimestamp(), // Only for new users
          'lastSignInTime': FieldValue.serverTimestamp(),
          'provider': 'google',
          'googleData': {
            'id': googleUser.id,
            'email': googleUser.email,
            'displayName': googleUser.displayName,
            'photoUrl': googleUser.photoUrl,
          },
          'isEmailVerified': user.emailVerified,
          'friendUID': friendUID, // Save the generated friendUID
        });
      } else {
        await users.doc(user.uid).update({
          'lastSignInTime': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error saving Google user data: $e");
      throw e;
    }
  }
}
