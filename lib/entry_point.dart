import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/services/notification_permission_service.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  final List _pages = const [
    HomeScreen(),
    DiscoverScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];
  int _currentIndex = 0;
  bool _notificationGranted = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    final granted = await NotificationPermissionService.isGranted();
    if (mounted) setState(() => _notificationGranted = granted);
  }

  Future<void> _requestNotifications() async {
    final granted = await NotificationPermissionService.request();
    if (mounted) {
      setState(() => _notificationGranted = granted);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(granted ? 'Notificaciones permitidas.' : 'No se permitió notificaciones.')),
      );
    }
  }

  Widget _pngIcon(String src, {Color? color}) {
    return Image.asset(src, height: 24, width: 24, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const SizedBox(),
        leadingWidth: 0,
        centerTitle: false,
        title: Image.asset('assets/ecomarket/png/ecomarket-logo-primary.png', height: 38),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, searchScreenRoute),
            icon: Image.asset('assets/ecomarket/navigation/png/icon-search.png', height: 24),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, notificationsScreenRoute),
            icon: Image.asset('assets/ecomarket/navigation/png/icon-notifications.png', height: 24),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_notificationGranted)
            Container(
              margin: const EdgeInsets.fromLTRB(defaultPadding, 0, defaultPadding, defaultPadding / 2),
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(defaultBorderRadious),
                border: Border.all(color: primaryColor.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Image.asset('assets/ecomarket/navigation/png/icon-notifications.png', height: 34),
                  const SizedBox(width: defaultPadding),
                  const Expanded(child: Text('Permite notificaciones para recibir estados de órdenes, ofertas y tracking.')),
                  TextButton(onPressed: _requestNotifications, child: const Text('Permitir')),
                ],
              ),
            ),
          Expanded(
            child: PageTransitionSwitcher(
              duration: defaultDuration,
              transitionBuilder: (child, animation, secondAnimation) {
                return FadeThroughTransition(animation: animation, secondaryAnimation: secondAnimation, child: child);
              },
              child: _pages[_currentIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(top: defaultPadding / 2),
        color: Colors.white,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index != _currentIndex) setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          selectedItemColor: primaryColor,
          unselectedItemColor: blackColor60,
          items: [
            BottomNavigationBarItem(
              icon: _pngIcon('assets/ecomarket/navigation/png/icon-home.png'),
              activeIcon: _pngIcon('assets/ecomarket/navigation/png/icon-home.png', color: primaryColor),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: _pngIcon('assets/ecomarket/navigation/png/icon-categories.png'),
              activeIcon: _pngIcon('assets/ecomarket/navigation/png/icon-categories.png', color: primaryColor),
              label: 'Categorías',
            ),
            BottomNavigationBarItem(
              icon: _pngIcon('assets/ecomarket/navigation/png/icon-cart.png'),
              activeIcon: _pngIcon('assets/ecomarket/navigation/png/icon-cart.png', color: primaryColor),
              label: 'Carrito',
            ),
            BottomNavigationBarItem(
              icon: _pngIcon('assets/ecomarket/navigation/png/icon-orders.png'),
              activeIcon: _pngIcon('assets/ecomarket/navigation/png/icon-orders.png', color: primaryColor),
              label: 'Órdenes',
            ),
            BottomNavigationBarItem(
              icon: _pngIcon('assets/ecomarket/navigation/png/icon-account.png'),
              activeIcon: _pngIcon('assets/ecomarket/navigation/png/icon-account.png', color: primaryColor),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
