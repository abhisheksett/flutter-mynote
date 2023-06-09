import 'package:mynotes/services/auth/auth_exception.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvider();
    test('Should not be initialised to begin with', () {
      expect(provider.isInitialized, false);
    });

    test("Can't logout without initializing", () {
      expect(
        provider.logOut(),
        throwsA(const TypeMatcher<NotInitializedException>()),
      );
    });

    test("Should be able to be initialized", () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    });

    test('User should be null after initialize', () {
      expect(provider.currentUser, null);
    });

    test(
      "Should be able to initialize in less than 3 seconds",
      () async {
        await provider.initialize();
        expect(provider.isInitialized, true);
      },
      timeout: const Timeout(Duration(seconds: 3)),
    );

    test("Create user should deligate to login", () async {
      final badUser =
          provider.createUser(email: "foo@bar.com", password: "password");
      expect(
        badUser,
        throwsA(const TypeMatcher<UserNotFoundAuthException>()),
      );

      final badPassword =
          provider.createUser(email: "goodemail@email.com", password: "foobar");
      expect(
        badPassword,
        throwsA(const TypeMatcher<WrongPasswordAuthException>()),
      );

      final user = await provider.createUser(
          email: "goodemail@email.com", password: "somepassword");
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });

    test("Logged in user should be able to get verified", () async {
      await provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user?.isEmailVerified, true);
    });

    test("Should be able to logout and login again", () async {
      await provider.logOut();
      await provider.logIn(email: "email", password: "password");
      final user = provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;

  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 2));
    return logIn(email: email, password: password);
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    // await Future.delayed(const Duration(seconds: 2));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({required String email, required String password}) {
    if (!isInitialized) throw NotInitializedException();
    if (email == 'foo@bar.com') throw UserNotFoundAuthException();
    if (password == 'foobar') throw WrongPasswordAuthException();
    const user = AuthUser(
      isEmailVerified: false,
      email: 'test@email.com',
      id: 'test_id',
    );
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 2));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedException();
    final user = _user;
    if (user == null) throw UserNotFoundAuthException();
    const newUser = AuthUser(
      isEmailVerified: true,
      email: 'good@email.com',
      id: 'test_id',
    );
    _user = newUser;
  }
}
