import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/notification_unread_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/orders_provider.dart';
import 'services/firebase_messaging_service.dart';


import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/create_new_password_screen.dart';
import 'screens/main/main_tab_navigation.dart';
import 'screens/main/store_order_screen.dart';
import 'screens/main/store_list_screen.dart';
import 'screens/main/choose_your_area_screen.dart';
import 'screens/main/add_items_screen.dart';
import 'screens/main/order_screen.dart';
import 'screens/main/order_details_screen.dart';
import 'screens/main/order_history_screen.dart';
import 'screens/main/bills_screen.dart';
import 'screens/main/chat_screen.dart';
import 'screens/main/calling_screen.dart';
import 'screens/main/my_addresses_screen.dart';
import 'screens/main/notification_screen.dart';
import 'screens/main/profile_screen.dart';
import 'screens/main/settings_screen.dart';
import 'screens/main/help_center_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseMessagingService.initialize();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const RobotInnCustomerApp());
}

class RobotInnCustomerApp extends StatelessWidget {
  const RobotInnCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => NotificationUnreadProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
      ],
      child: MaterialApp(
        title: 'RobotInn',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            background: AppColors.background,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          final args = settings.arguments as Map<String, dynamic>? ?? {};

          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/signup':
              return MaterialPageRoute(builder: (_) => const SignupScreen());
            case '/forgot-password':
              return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
            case '/create-new-password':
              return MaterialPageRoute(
                builder: (_) => CreateNewPasswordScreen(
                  email: args['email'] ?? '',
                  code: args['code'] ?? '',
                ),
              );
            case '/main':
              return MaterialPageRoute(
                builder: (_) => MainTabNavigation(initialTab: args['tab'] ?? 0),
              );
            case '/store-order':
              return MaterialPageRoute(
                builder: (_) => StoreOrderScreen(
                  store: args['store'] ?? {},
                  areaName: args['areaName'] ?? 'F-7',
                  categoryName: args['categoryName'] ?? 'Food',
                ),
              );
            case '/store-list':
              return MaterialPageRoute(
                builder: (_) => StoreListScreen(
                  categoryId: args['categoryId'] ?? '',
                  categoryName: args['categoryName'] ?? 'Stores',
                  areaName: args['areaName'] ?? 'F-7',
                ),
              );
            case '/choose-area':
              return MaterialPageRoute(builder: (_) => const ChooseYourAreaScreen());
            case '/add-order':
              return MaterialPageRoute(
                builder: (_) => OrderScreen(areaName: args['areaName'] ?? 'F-7'),
              );
            case '/order-details':
              return MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(orderId: args['orderId'] ?? ''),
              );
            case '/order-history':
              return MaterialPageRoute(
                builder: (_) => OrderHistoryScreen(filter: args['filter'] ?? 'all'),
              );
            case '/bills':
              return MaterialPageRoute(builder: (_) => const BillsScreen());
            case '/chat':
              return MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: args['conversationId'] ?? '',
                  participantId: args['participantId'] ?? '',
                  contactName: args['contactName'] ?? 'Rider',
                  orderCode: args['orderCode'],
                ),
              );
            case '/calling':
              return MaterialPageRoute(
                builder: (_) => CallingScreen(
                  name: args['name'] ?? 'Rider',
                  orderCode: args['orderCode'],
                ),
              );
            case '/addresses':
              return MaterialPageRoute(builder: (_) => const MyAddressesScreen());
            case '/notifications':
              return MaterialPageRoute(builder: (_) => const NotificationScreen());
            case '/profile':
              return MaterialPageRoute(builder: (_) => const ProfileScreen());
            case '/settings':
              return MaterialPageRoute(builder: (_) => const SettingsScreen());
            case '/help':
              return MaterialPageRoute(builder: (_) => const HelpCenterScreen());
            default:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
        },
      ),
    );
  }
}
