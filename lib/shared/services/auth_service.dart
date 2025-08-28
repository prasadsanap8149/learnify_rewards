import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:learnify_rewards/shared/domain/entities/user.dart';

class AuthService {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final auth.UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    final auth.User? firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      return null;
    }

    return User(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName,
      email: firebaseUser.email,
      photoUrl: firebaseUser.photoURL,
      role: UserRole.user, // Default role
      status: UserStatus.active, // Default status
      ageGroup: AgeGroup.eighteen_plus, // Placeholder, needs to be determined
      verificationStatus: VerificationStatus.email, // Default
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  Stream<User?> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        return null;
      }
      return User(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName,
        email: firebaseUser.email,
        photoUrl: firebaseUser.photoURL,
        role: UserRole.user,
        status: UserStatus.active,
        ageGroup: AgeGroup.eighteen_plus,
        verificationStatus: VerificationStatus.email,
      );
    });
  }
}
