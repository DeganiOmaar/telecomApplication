import 'package:application_telecom/RemboursementPages/addRemboursement.dart';
import 'package:application_telecom/profilePages/profile.dart';
import 'package:application_telecom/screens/acceuil.dart';
import 'package:application_telecom/screens/assurences.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';


class Screens extends StatefulWidget {
  const Screens({super.key});

  @override
  State<Screens> createState() => _ScreensState();
}

class _ScreensState extends State<Screens> {

    final PageController _pageController = PageController();

  int currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
     return 
         Scaffold(
            // backgroundColor: Colors.white,
            bottomNavigationBar: Padding(
              padding:
                   EdgeInsets.only(
                    left: 10,
                   right: 10, 
                   top: 4, 
                   bottom: 4),
              child: GNav(
                gap: 10,
                color: Colors.grey,
                activeColor: Colors.indigo,
                curve: Curves.decelerate,
                padding: const EdgeInsets.only(bottom: 10, left: 6, right: 6, top: 2),
                onTabChange: (index) {
                  _pageController.jumpToPage(index);
                  setState(() {
                    currentPage = index;
                  });
                },
                tabs: const [
                      GButton(
                          icon: Icons.home_outlined,
                          text: 'Acceuil',
                        ),
                         GButton(
                          icon: Icons.add_circle_outline,
                          text: 'Remboursement',
                        ),
                        GButton(
                          icon: Icons.book_outlined,
                          text: 'Assurance',
                        ),
                        GButton(
                          icon: Icons.person_2_outlined,
                          text: 'Profile',
                        ),
                ],
              ),
            ),
            body: PageView(
              onPageChanged: (index) {},
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              children: const [
                 PageAcceuil(),
                 AddRemboursement(),
                 Assurences(),
                 Profile(),
              ],
            ),
          );
  }
}