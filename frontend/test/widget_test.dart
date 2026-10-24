import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dil_kaa_rista/core/theme/app_theme.dart';
import 'package:dil_kaa_rista/features/matches/screens/matches_tab_screen.dart';
import 'package:dil_kaa_rista/features/search/screens/search_tab_screen.dart';
import 'package:dil_kaa_rista/features/inbox/screens/inbox_tab_screen.dart';
import 'package:dil_kaa_rista/features/account/screens/my_account_tab_screen.dart';
import 'package:dil_kaa_rista/features/home/screens/home_nav_screen.dart';
import 'package:dil_kaa_rista/features/auth/screens/welcome_screen.dart';
import 'package:dil_kaa_rista/features/profile_creation/models/profile_model.dart';
import 'package:dil_kaa_rista/features/matches/widgets/match_card_full_widget.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=http://127.0.0.1:8000/api');
  });

  testWidgets('Test WelcomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const WelcomeScreen()),
    );
    await tester.pump();
  });

  testWidgets('Test MatchesTabScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MatchesTabScreen()),
    );
    await tester.pump();
  });

  testWidgets('Test SearchTabScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const SearchTabScreen()),
    );
    await tester.pump();
  });

  testWidgets('Test InboxTabScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const InboxTabScreen()),
    );
    await tester.pump();
  });

  testWidgets('Test MyAccountTabScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MyAccountTabScreen()),
    );
    await tester.pump();
  });

  testWidgets('Test HomeNavScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const HomeNavScreen()),
    );
    await tester.pump();
  });

  testWidgets('Test MatchCardFullWidget', (WidgetTester tester) async {
    final profile = ProfileModel(
      id: 'test-user-1',
      profileId: 'DKR123456',
      fullName: 'Priya Sharma',
      gender: 'female',
      dateOfBirth: DateTime(1998, 5, 20),
      heightCm: 165,
      religion: 'Hindu',
      caste: 'Brahmin',
      motherTongue: 'Hindi',
      city: 'Mumbai',
      state: 'Maharashtra',
      occupation: 'Software Engineer',
      education: 'B.Tech',
      annualIncome: '15-20 LPA',
      matchReason: 'Matches Religion, Age, and Location',
      hobbies: ['Reading', 'Yoga', 'Cooking'],
      photos: ['https://example.com/p1.jpg', 'https://example.com/p2.jpg'],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MatchCardFullWidget(
              profile: profile,
              currentUserProfile: null,
              onInterestSent: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  });
}
