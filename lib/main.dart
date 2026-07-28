import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ⚠️ 본인의 Firebase 웹 설정 키값으로 교체해주세요!
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "YOUR_API_KEY",
      appId: "YOUR_APP_ID",
      messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
      projectId: "YOUR_PROJECT_ID",
      storageBucket: "YOUR_STORAGE_BUCKET",
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taste Cabinet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const MainAppShell();
        }
        return const AuthScreen();
      },
    );
  }
}

/// 🔐 닉네임 / 비밀번호 간편 로그인 화면
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isSignUp = false;
  bool isLoading = false;

  // 닉네임/아이디를 안전한 내부 이메일 포맷으로 변환하는 함수
  String _toInternalEmail(String username) {
    final cleanUsername = Uri.encodeComponent(username.trim().replaceAll(' ', ''));
    return '$cleanUsername@tastecabinet.internal';
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임과 비밀번호를 모두 입력해 주세요.')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final internalEmail = _toInternalEmail(username);

      if (isSignUp) {
        // 회원가입 및 닉네임 저장
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: internalEmail,
          password: password,
        );
        await credential.user?.updateDisplayName(username);
      } else {
        // 로그인
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: internalEmail,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = '인증에 실패했습니다.';
      if (e.code == 'wrong-password' || e.code == 'user-not-found' || e.code == 'invalid-credential') {
        message = '닉네임 또는 비밀번호가 일치하지 않습니다.';
      } else if (e.code == 'email-already-in-use') {
        message = '이미 사용 중인 닉네임입니다.';
      } else if (e.code == 'weak-password') {
        message = '비밀번호는 6자리 이상이어야 합니다.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          maxWidth: 380,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cabinet, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 16),
              Text(
                isSignUp ? '취향 보관함 계정 만들기' : '취향 보관함 로그인',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isSignUp ? '사용하실 닉네임과 비밀번호만 설정해 주세요.' : '닉네임과 비밀번호로 로그인하세요.',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '닉네임 (또는 아이디)',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isSignUp ? '가입하기' : '로그인하기', style: const TextStyle(fontSize: 16)),
                    ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => isSignUp = !isSignUp),
                child: Text(
                  isSignUp ? '이미 계정이 있으신가요? 로그인' : '처음이신가요? 3초 만에 가입하기',
                  style: const TextStyle(color: Colors.deepPurple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🏠 로그인 성공 시 들어오는 메인 화면
class MainAppShell extends StatelessWidget {
  const MainAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nickname = user?.displayName ?? '멤버';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taste Cabinet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: '로그아웃',
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✨ $nickname 님의 취향 보관함', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('자동 로그인 적용 완료! 다음 접속 시 바로 이 화면으로 이동합니다.'),
          ],
        ),
      ),
    );
  }
}