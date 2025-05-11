import 'package:flutter/material.dart';
import '../services/navigation_service.dart';

/// A reusable bottom navigation bar for the app
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Planner',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Add Item',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        if (index == currentIndex) return;

        switch (index) {
          case 0:
            NavigationService.navigateToHome(context);
            break;
          case 1:
            NavigationService.navigateToPlanner(context);
            break;
          case 2:
            NavigationService.navigateToAddItem(context);
            break;
          case 3:
            NavigationService.navigateToCart(context);
            break;
          case 4:
            NavigationService.navigateToProfile(context);
            break;
        }
      },
    );
  }
}
