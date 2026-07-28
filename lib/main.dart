import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 Firestore 패키지 추가
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C2C2C),
          primary: const Color(0xFFFF5252),
        ),
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
        if (snapshot.hasData) return const MainAppShell();
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _toInternalEmail(String username) {
    final cleanUsername = Uri.encodeComponent(username.trim().replaceAll(' ', ''));
    return '$cleanUsername@tastecabinet.internal';
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) return;

    setState(() => isLoading = true);
    try {
      final internalEmail = _toInternalEmail(username);
      if (isSignUp) {
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: internalEmail, password: password,
        );
        await credential.user?.updateDisplayName(username);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: internalEmail, password: password,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인/가입 실패')));
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
              const Icon(Icons.music_note, size: 64, color: Colors.black87),
              const SizedBox(height: 16),
              Text(
                isSignUp ? '공연 취향 보관함 가입' : '공연 취향 보관함 로그인', 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _usernameController, 
                decoration: const InputDecoration(labelText: '닉네임', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController, 
                obscureText: true, 
                decoration: const InputDecoration(labelText: '비밀번호', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50), 
                        backgroundColor: Colors.black87, 
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isSignUp ? '가입하기' : '로그인하기'),
                    ),
              TextButton(
                onPressed: () => setState(() => isSignUp = !isSignUp),
                child: Text(
                  isSignUp ? '이미 계정이 있으신가요? 로그인' : '처음이신가요? 가입하기', 
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🏠 메인 화면: Firestore DB 연동 및 실시간 데이터 바인딩
class MainAppShell extends StatelessWidget {
  const MainAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nickname = user?.displayName ?? '멤버';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Live Gig Archive', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            maxWidth: 650,
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔥 $nickname 님이 오늘 발견한 라이브 취향', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // 📝 1. 취향 기록 폼
                const GigTasteFormWidget(),

                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 16),
                
                // 🗂 2. Firestore 실시간 취향 아카이브 리스트
                const Text('최근 보관된 취향', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                StreamBuilder<QuerySnapshot>(
                  // 로그인한 사용자의 취향을 작성일시(createdAt) 내림차순으로 조회
                  stream: FirebaseFirestore.instance
                      .collection('tastes')
                      .where('userId', isEqualTo: user?.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            '아직 기록된 공연 취향이 없습니다.\n위 폼을 작성하여 첫 번째 취향을 보관해 보세요!', 
                            textAlign: TextAlign.center, 
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final item = docs[index].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), 
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                                      child: Text(item['type'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(item['category'] ?? '', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('${item['artist'] ?? ''} 발견', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(item['detail'] ?? '', style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
                                const SizedBox(height: 12),
                                if (item['aiSummary'] != null && (item['aiSummary'] as String).isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    width: double.infinity,
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                    child: Text('✨ AI 요약: ${item['aiSummary']}', style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontStyle: FontStyle.italic)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🎸 라이브 공연 취향 기록 폼 (Firestore 데이터 저장)
class GigTasteFormWidget extends StatefulWidget {
  const GigTasteFormWidget({super.key});

  @override
  State<GigTasteFormWidget> createState() => _GigTasteFormWidgetState();
}

class _GigTasteFormWidgetState extends State<GigTasteFormWidget> {
  final _artistController = TextEditingController();
  final _detailController = TextEditingController();
  
  String _selectedGigType = '라이브 펍 소공연';
  final List<String> _gigTypes = ['라이브 펍 소공연', '단독 공연', '페스티벌'];
  
  String _selectedCategory = '🎸 악기/사운드';
  final List<String> _categories = [
    '🎤 보컬/음색', '🎸 악기/사운드', '🕺 무대/퍼포먼스', 
    '🌃 공연장 분위기', '🤝 관객 호응/관람 형태', '👕 머치/팬 문화'
  ];

  String _aiSummary = '';
  bool _isLoadingAi = false;
  bool _isSaving = false;

  final String _geminiApiKey = "YOUR_GEMINI_API_KEY";

  @override
  void dispose() {
    _artistController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _generateAiSummary() async {
    final detail = _detailController.text.trim();
    final artist = _artistController.text.trim();
    if (detail.isEmpty || artist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('아티스트와 발견한 취향 내용을 먼저 적어주세요!')));
      return;
    }

    if (_geminiApiKey == "YOUR_GEMINI_API_KEY") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gemini API 키를 설정해주세요!')));
      return;
    }

    setState(() {
      _isLoadingAi = true;
      _aiSummary = '';
    });

    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _geminiApiKey);
      final prompt = '''
너는 라이브 음악 공연을 전문으로 리뷰하는 감성 에디터야.
사용자가 오늘 다녀온 '$_selectedGigType'에서 발견한 취향을 읽고 아카이빙 카드로 예쁘게 정리해줘.

[사용자가 발견한 아티스트/공연명]: $artist
[선택한 취향 카테고리]: $_selectedCategory
[구체적 취향 내용]: $detail

위 내용을 바탕으로 딱 2가지만 출력해. (군더더기 인사말 금지)
1. ✨ 감성 한 줄 요약: (공연의 분위기와 취향이 드러나는 30자 내외의 시적인 문장)
2. 🏷️ 추천 태그: (아티스트, 악기, 분위기 등을 조합한 해시태그 3개)
''';

      final response = await model.generateContent([Content.text(prompt)]);
      if (mounted) {
        setState(() => _aiSummary = response.text?.trim() ?? '분석 실패');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _aiSummary = 'AI 요약 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAi = false);
      }
    }
  }

  /// 💾 Firestore에 취향 데이터 저장
  Future<void> _saveRecord() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_artistController.text.isEmpty || _detailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('필수 내용을 모두 입력해주세요.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('tastes').add({
        'userId': user.uid,
        'type': _selectedGigType,
        'category': _selectedCategory,
        'artist': _artistController.text.trim(),
        'detail': _detailController.text.trim(),
        'aiSummary': _aiSummary,
        'createdAt': FieldValue.serverTimestamp(), // 서버 시간 등록
      });

      _artistController.clear();
      _detailController.clear();
      setState(() => _aiSummary = '');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firestore DB에 성공적으로 보관되었습니다! 🎸')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('어떤 공연이었나요?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedGigType,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              items: _gigTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGigType = val);
              },
            ),
            const SizedBox(height: 20),

            const Text('오늘 가장 꽂힌 취향 포인트는?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = category);
                  },
                  selectedColor: const Color(0xFFFF5252),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  backgroundColor: Colors.grey.shade200,
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text('새롭게 발견한 아티스트(또는 곡명)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(hintText: '예: 실리카겔, 한남동 뮤직펍 FF 베이시스트', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            const Text('어떤 디테일이 좋았나요? (나만의 관점)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _detailController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '단순히 "좋았다"보다 구체적으로!\n예: 원래 보컬 위주로 듣는데, 오늘 기타 리프랑 베이스 터지는 사운드에 심장이 뛰는 걸 느낌.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoadingAi ? null : _generateAiSummary,
                icon: const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                label: Text(_isLoadingAi ? 'AI가 멋지게 다듬는 중...' : 'Gemini AI로 취향 태그/요약 다듬기', style: const TextStyle(color: Colors.deepPurple)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Colors.deepPurple)),
              ),
            ),
            if (_aiSummary.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(_aiSummary, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
              ),
            ],
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveRecord,
                icon: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.save),
                label: Text(_isSaving ? '저장하는 중...' : '내 취향 보관함에 아카이빙', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2C), 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}