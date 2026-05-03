import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/home/home_screen.dart';
import '../../features/circles/presentation/screens/circles_screen.dart';
import '../../features/chat/presentation/screens/circles_chat_list.dart';
import '../../features/chat/data/unread_service.dart';
import '../../features/demands/presentation/screens/demands_screen.dart';
import '../../features/memories/presentation/screens/memories_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  final _unreadService = UnreadService();
  final supabase = Supabase.instance.client;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CirclesChatList(),
    const DemandsScreen(),
    const MemoriesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _unsubscribeFromMessages();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    if (!mounted) return;
    print('Loading unread count...');
    final count = await _unreadService.getTotalUnreadCount();
    print('Unread count: $count');
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  void _subscribeToMessages() {
    print('Subscribing to message updates...');
    // Subscribe to all message inserts to update badge in real-time
    supabase
        .channel('unread_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            print('New message received! Refreshing badge...');
            // Refresh unread count when new message arrives
            _loadUnreadCount();
          },
        )
        .subscribe();
  }

  void _unsubscribeFromMessages() {
    supabase.removeChannel(supabase.channel('unread_messages'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Refresh unread count when switching tabs
            if (index == 1) {
              _loadUnreadCount();
            }
          },
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _unreadCount > 0
                  ? Badge(
                      label: Text(_unreadCount > 99 ? '99+' : '$_unreadCount'),
                      child: const Icon(Icons.chat_bubble_rounded),
                    )
                  : const Icon(Icons.chat_bubble_rounded),
              label: 'Chat',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded),
              label: 'Demands',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.photo_library_rounded),
              label: 'Memories',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
