import 'package:flutter/material.dart';

import '../fg/screens/fg_screen.dart';
import '../material/screens/material_screen.dart';
import '../staff/screens/staff_screen.dart';
import '../trucks/screens/trucks_screen.dart';

class ChartsLandingScreen extends StatelessWidget {
  const ChartsLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Charts'),
          bottom: TabBar(
            isScrollable: false,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            dividerColor: theme.colorScheme.outlineVariant,
            tabs: const [
              Tab(text: 'Material'),
              Tab(text: 'Staff'),
              Tab(text: 'FG'),
              Tab(text: 'Trucks'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MaterialScreen(),
            StaffScreen(),
            FgScreen(),
            TrucksScreen(),
          ],
        ),
      ),
    );
  }
}
