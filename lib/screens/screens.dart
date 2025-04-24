import 'package:application_telecom/NotificationsPages/notification_admin.dart';
import 'package:application_telecom/NotificationsPages/notifications.dart';
import 'package:application_telecom/RemboursementPages/addRemboursement.dart';
import 'package:application_telecom/RemboursementPages/adminremboursementList.dart';
import 'package:application_telecom/RemboursementPages/remboursementlist.dart';
import 'package:application_telecom/profilePages/profile.dart';
import 'package:application_telecom/screens/acceuil.dart';
import 'package:application_telecom/screens/assurences.dart';
import 'package:application_telecom/screens/reclamtion_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Screens extends StatefulWidget {
  const Screens({super.key});

  @override
  State<Screens> createState() => _ScreensState();
}

class _ScreensState extends State<Screens> {
  Map userData = {};
  bool isLoading = true;

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();

      userData = snapshot.data()!;
    } catch (e) {
      print(e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  final PageController _pageController = PageController();

  int currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: LoadingAnimationWidget.discreteCircle(
              size: 32,
              color: const Color.fromARGB(255, 16, 16, 16),
              secondRingColor: Colors.indigo,
              thirdRingColor: Colors.pink.shade400,
            ),
          ),
        )
        : Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
            child: GNav(
              backgroundColor: Colors.white,
              gap: 10,
              color: Colors.grey,
              activeColor: Colors.indigo,
              curve: Curves.decelerate,
              padding: const EdgeInsets.only(
                bottom: 10,
                left: 6,
                right: 6,
                top: 2,
              ),
              onTabChange: (index) {
                _pageController.jumpToPage(index);
                setState(() {
                  currentPage = index;
                });
              },
              tabs: [
                GButton(icon: Icons.home_outlined, text: 'Acceuil'),

                GButton(
                  icon: Icons.notification_important_outlined,
                  text: 'Notifications',
                ),

                userData['role'] == 'admin'
                    ? GButton(icon: Icons.book_outlined, text: 'Reclamations')
                    : GButton(icon: Icons.book_outlined, text: 'Assurance'),

                GButton(icon: Icons.person_2_outlined, text: 'Profile'),
              ],
            ),
          ),
          body: PageView(
            onPageChanged: (index) {},
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            children: [
              userData['role'] == 'admin'
                  ? RemboursementAdminList()
                  : RemboursementList(),
              userData['role'] == 'admin'
                  ? NotificationsAdmin()
                  : Notifications(),
              userData['role'] == 'admin' ? ReclamationPage() : Assurences(),
              Profile(),
            ],
          ),
        );
  }
}
