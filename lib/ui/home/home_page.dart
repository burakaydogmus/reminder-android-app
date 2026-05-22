import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'package:reminder/ui/home/bottom_nav_bar.dart';
import 'package:reminder/ui/reminders/reminder_list_page.dart';
import 'package:reminder/ui/settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _pages = const <Widget>[
    ReminderListPage(),
    SettingsPage(),
  ];
  int _currentPage = 0;

  void _changePage(int index) {
    if (index == _currentPage) return;
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          PageTransitionSwitcher(
            transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
              return FadeThroughTransition(
                fillColor: theme.scaffoldBackgroundColor,
                animation: primaryAnimation,
                secondaryAnimation: secondaryAnimation,
                child: child,
              );
            },
            child: _pages[_currentPage],
          ),
          BottomNavBar(
            currentPage: _currentPage,
            onChanged: _changePage,
          ),
        ],
      ),
    );
  }
}
