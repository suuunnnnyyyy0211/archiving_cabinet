import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ⚠️ 1. 본인의 Firebase 웹 설정 키값으로 교체해주세요!
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD4lz8x03zRblRUYtHwO7nBUlVCmeCtEbE",
      appId: "1:601693526110:web:5f4b72e6e7e84cd0febccf",
      messagingSenderId: "601693526110",
      projectId: "tastecabinet-14d22",
      storageBucket: "tastecabinet-14d22.firebasestorage.app",
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

/// 🔑 로그인 감지 및 자동 로그인 게이트
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
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: internalEmail,
          password: password,
        );
        await credential.user?.updateDisplayName(username);
      } else {
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

/// 🏠 로그인 후 메인 홈 화면 (Gemini AI 탑재)
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
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            maxWidth: 600,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text('✨ $nickname 님의 취향 보관함', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('자동 로그인 적용 완료! 나만의 취향을 기록하고 AI 분석을 받아보세요.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                
                // 🤖 Gemini AI 분석기 위젯
                const AiTasteAnalyzerWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🤖 Gemini AI 취향 분석기 위젯
class AiTasteAnalyzerWidget extends StatefulWidget {
  const AiTasteAnalyzerWidget({super.key});

  @override
  State<AiTasteAnalyzerWidget> createState() => _AiTasteAnalyzerWidgetState();
}

class _AiTasteAnalyzerWidgetState extends State<AiTasteAnalyzerWidget> {
  final _memoController = TextEditingController();
  String _aiResult = '';
  bool _isLoading = false;

  // ⚠️ 2. 여기에 아까 복사하신 Gemini API 키를 붙여넣으세요! (AIzaSy...)
  final String _geminiApiKey = "YOUR_GEMINI_API_KEY";

  Future<void> _analyzeTaste() async {
    final text = _memoController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('분석할 취향 내용을 적어주세요!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _aiResult = '';
    });

    try {
      // Gemini 1.5 Flash 모델 사용
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
      );

      final prompt = '''
너는 취향 아카이빙 전문가이자 감성 에디터야.
사용자가 입력한 아래 메모나 장소/음악 느낌을 읽고:

1. ✨ [감성 한 줄 요약] (30자 이내의 근사한 문장)
2. 🏷️ [추천 태그] (태그 3개, 예: #어두운조명 #시각적낭만 #우디향)
3. 💡 [취향 팁] (이 취향과 어울리는 추천 음료, 시간대, 혹은 음악 분위기 1줄)

위 양식대로 깔끔하고 위트 있게 한국어로 답변해줘.

[사용자 입력 내용]: $text
''';

      final response = await model.generateContent([Content.text(prompt)]);
      
      setState(() {
        _aiResult = response.text ?? '분석 결과를 가져올 수 없습니다.';
      });
    } catch (e) {
      setState(() {
        _aiResult = 'AI 분석 중 오류가 발생했습니다.\nKey 설정이나 네트워크를 확인해 주세요: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 28),
                SizedBox(width: 10),
                Text('AI 취향 에디터 (Gemini)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                hintText: '좋아하는 공간, 음악, 분위기를 적어보세요...\n예: 비 오는 날 방문한 어두운 원목 LP바. 잔잔한 재즈와 묵직한 위스키 향',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analyzeTaste,
              icon: const Icon(Icons.psychology),
              label: Text(_isLoading ? 'Gemini가 생각하는 중...' : 'Gemini에게 취향 분석받기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (_aiResult.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Text(_aiResult, style: const TextStyle(fontSize: 15, height: 1.6)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}