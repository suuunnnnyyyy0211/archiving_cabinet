import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MusicArchiveApp());
}

class MusicArchiveApp extends StatelessWidget {
  const MusicArchiveApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Music Archive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A041A),
        primaryColor: const Color(0xFF6B2D8C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6B2D8C),
          secondary: Color(0xFF00CEC9),
          surface: Color(0xFF130826),
        ),
      ),
      home: const MainShell(),
    );
  }
}

// ==========================================
// 1. 모바일 웹 쉘 (Main Shell & Navigation)
// ==========================================
class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    ArchiveCreateScreen(),
    BadgeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: const Color(0xFF0A041A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 24,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: _screens[_currentIndex],
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                color: const Color(0xFF130826).withOpacity(0.95),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: const Color(0xFFFF6B81),
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore),
                    label: '메인 피드',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.add_circle_outline, size: 32),
                    activeIcon: Icon(Icons.add_circle, size: 32),
                    label: '기록하기',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.badge_outlined),
                    activeIcon: Icon(Icons.badge),
                    label: '내 명패',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. 메인 피드 화면 (Feed Screen)
// ==========================================
class FeedScreen extends StatelessWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          backgroundColor: Colors.transparent,
          title: Text(
            'LIVE ARCHIVE FEED',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          centerTitle: true,
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D0D33).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 수정됨
                      children: [
                        const Text(
                          '인디 록 라이브 세션 #',
                          style: TextStyle(
                            color: Color(0xFF00CEC9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '2026.07.25',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '현장의 공기와 기타 리프의 울림이 고스란히 담긴 기록입니다.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            },
            childCount: 6,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 3. 6대 다차원 취향 태그 입력 화면 (Archive Create)
// ==========================================
class ArchiveCreateScreen extends StatefulWidget {
  const ArchiveCreateScreen({Key? key}) : super(key: key);

  @override
  State<ArchiveCreateScreen> createState() => _ArchiveCreateScreenState();
}

class _ArchiveCreateScreenState extends State<ArchiveCreateScreen> {
  final TextEditingController _artistController = TextEditingController(text: '오디오글라이더');
  final TextEditingController _venueController = TextEditingController(text: '홍대 벨로주');
  final TextEditingController _dateController = TextEditingController(text: '2026.07.25');

  final Map<String, List<String>> _categories = {
    '1. 아티스트 성향': ['열정적인', '실험적인', '관객 압도형', '편안한 소통형', '카리스마 넘치는'],
    '2. 사운드 질감': ['거친 디스토션', '따뜻한 아날로그', '웅장한 사운드', '청량한 톤', '로우파이 감성'],
    '3. 악기/연주 스타일': ['화려한 기타 솔로', '단단한 베이스 그루브', '타이트한 드럼 비트', '즉흥 연주 잼', '합이 돋보이는'],
    '4. 굳즈/시각 요소': ['감각적인 포스터', '유니크한 티셔츠', '조명 연출 미쳤음', '아날로그 굿즈', '미니멀리즘 디자인'],
    '5. 무대 매너/상호작용': ['떼창 유도 최고', '눈맞춤 다정', '폭발적인 에너지', '위트 있는 멘트', '관객과 하나됨'],
    '6. 공연 장소/기획': ['음향 상태 최상', '아늑한 소극장', '웅장한 페스티벌', '기획 의도 명확', '특이한 베뉴 공간'],
  };

  final Map<String, Set<String>> _selectedTags = {};

  @override
  void initState() {
    super.initState();
    for (var key in _categories.keys) {
      _selectedTags[key] = <String>{};
    }
    _selectedTags['1. 아티스트 성향'] = {'열정적인', '실험적인'};
    _selectedTags['2. 사운드 질감'] = {'거친 디스토션'};
  }

  @override
  void dispose() {
    _artistController.dispose();
    _venueController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '새로운 라이브 아카이브',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D0D33).withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  _buildTextField(controller: _artistController, label: '아티스트명', icon: Icons.mic),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _venueController, label: '공연 장소 (베뉴)', icon: Icons.place),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _dateController, label: '공연 날짜 (예: 2026.07.25)', icon: Icons.calendar_today),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '다차원 취향 태그 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00CEC9)),
            ),
            const SizedBox(height: 4),
            const Text(
              '현장에서 느낀 입체적인 감각을 복수 선택하세요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._categories.entries.map((entry) {
              final categoryName = entry.key;
              final tags = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: tags.map((tag) {
                        final isSelected = _selectedTags[categoryName]!.contains(tag);
                        return ChoiceChip(
                          label: Text(tag),
                          selected: isSelected,
                          selectedColor: const Color(0xFF6B2D8C),
                          backgroundColor: const Color(0xFF130826),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF00CEC9) : Colors.white.withOpacity(0.1),
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags[categoryName]!.add(tag);
                              } else {
                                _selectedTags[categoryName]!.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B81),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                List<String> allSelectedTags = [];
                for (var set in _selectedTags.values) {
                  allSelectedTags.addAll(set);
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArchiveResultScreen(
                      artist: _artistController.text,
                      venue: _venueController.text,
                      date: _dateController.text,
                      tags: allSelectedTags,
                    ),
                  ),
                );
              },
              child: const Text(
                '취향 아카이브 기록 완료 및 카드 생성',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF00CEC9), size: 20),
        filled: true,
        fillColor: const Color(0xFF0A041A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00CEC9), width: 1)),
      ),
    );
  }
}

// ==========================================
// 4. 공유용 요약 카드 화면 & 클립보드 (Archive Result)
// ==========================================
class ArchiveResultScreen extends StatelessWidget {
  final String artist;
  final String venue;
  final String date;
  final List<String> tags;

  const ArchiveResultScreen({
    Key? key,
    required this.artist,
    required this.venue,
    required this.date,
    required this.tags,
  }) : super(key: key);

  String _generateBadgeTitle() {
    if (tags.any((t) => t.contains('디스토션') || t.contains('기타 솔로'))) {
      return '헤비 드라이브 사운드의 수호자';
    } else if (tags.any((t) => t.contains('소극장') || t.contains('아날로그'))) {
      return '소공연장 감성 탐험가';
    } else {
      return '라이브 핏빛 에너지 수집가';
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeTitle = _generateBadgeTitle();

    return Scaffold(
      backgroundColor: const Color(0xFF0A041A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('아카이브 카드 요약', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B2D8C), Color(0xFF1D0D33), Color(0xFF0A041A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00CEC9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00CEC9).withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 수정됨
                      children: [
                        const Text(
                          'LIVE MUSIC ARCHIVE',
                          style: TextStyle(
                            color: Color(0xFF00CEC9),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      artist,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place, size: 14, color: Color(0xFFFF6B81)),
                        const SizedBox(width: 4),
                        Text(venue, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: Colors.white24),
                    ),
                    Center(
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFF00CEC9),
                            child: Icon(Icons.auto_awesome, size: 28, color: Color(0xFF0A041A)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            badgeTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      children: tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: const Color(0xFF0A041A).withOpacity(0.8),
                          labelStyle: const TextStyle(color: Color(0xFF00CEC9), fontSize: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: const Color(0xFF00CEC9).withOpacity(0.4)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00CEC9),
                  foregroundColor: const Color(0xFF0A041A),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.copy),
                label: const Text(
                  '커뮤니티에 카드 공유하기 (링크 복사)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () {
                  final String shareText = '[Live Music Archive]\n아티스트: $artist\n베뉴: $venue ($date)\n뱃지: $badgeTitle\n태그: ${tags.join(", ")}';
                  Clipboard.setData(ClipboardData(text: shareText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('공유 링크가 복사되었습니다!'),
                      backgroundColor: Color(0xFF6B2D8C),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. 내 명패 및 수렴도 통계 화면 (Badge Screen)
// ==========================================
class BadgeScreen extends StatefulWidget {
  const BadgeScreen({Key? key}) : super(key: key);

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  final Map<String, int> _tagFrequency = {
    '거친 디스토션': 14,
    '화려한 기타 솔로': 12,
    '웅장한 사운드': 9,
    '아늑한 소극장': 8,
    '떼창 유도 최고': 7,
  };

  String _generateArchivistTitle() {
    if (_tagFrequency.isEmpty) return '방랑하는 음악 탐험가';
    
    var sortedTags = _tagFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    String topTag = sortedTags.first.key;

    if (topTag.contains('디스토션') || topTag.contains('기타 솔로')) {
      return '헤비 드라이브 사운드의 수호자';
    } else if (topTag.contains('소극장') || topTag.contains('아날로그')) {
      return '소공연장 감성 탐험가';
    } else {
      return '라이브 핏빛 에너지 수집가';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dynamicTitle = _generateArchivistTitle();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '내 명패 & 취향 통계',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B2D8C), Color(0xFF1D0D33)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00CEC9).withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B2D8C).withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: Color(0xFF00CEC9),
                    child: Icon(Icons.music_note, size: 40, color: Color(0xFF0A041A)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    dynamicTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '누적 아카이브 패턴 분석 기반 자동 생성된 명패',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              '취향 수렴도 분석 (Convergence)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00CEC9),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '나만의 음악적 방향성이 특정 장르와 사운드로 수렴해 나가는 과정입니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildConvergenceProgressBar('하드록 / 메탈릭 사운드', 0.88, const Color(0xFFFF6B81)),
            const SizedBox(height: 12),
            _buildConvergenceProgressBar('기타 중심 연주 세션', 0.75, const Color(0xFF00CEC9)),
            const SizedBox(height: 12),
            _buildConvergenceProgressBar('소극장 어쿠스틱 감성', 0.35, Colors.purpleAccent),
            const SizedBox(height: 12),
            _buildConvergenceProgressBar('대형 페스티벌 에너지', 0.50, Colors.amberAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildConvergenceProgressBar(String category, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D0D33).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 수정됨
            children: [
              Text(
                category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF0A041A),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}