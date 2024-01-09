import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roadeye/screens/auth/WelcomePage.dart';
import 'package:roadeye/screens/map/SearchScreen.dart';

class HeroSectionPage extends StatefulWidget {
  const HeroSectionPage({super.key});

  @override
  State<HeroSectionPage> createState() => _HeroSectionPageState();
}

class _HeroSectionPageState extends State<HeroSectionPage> {
  final user = FirebaseAuth.instance.currentUser;

  void navigateToLocation(String locationName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          initialLocation: locationName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime dateToday = DateTime.now();
    String currentDay = DateFormat('EEEE').format(dateToday);
    String currentMonth = DateFormat('LLLL').format(dateToday);
    String date = DateFormat('d').format(dateToday);
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.5),
                Colors.green.withOpacity(0.5),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WelcomePage(),
                                ),
                              );
                            },
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                              ),
                              child: Stack(
                                children: [
                                  const CircleAvatar(
                                      radius: 35,
                                      backgroundImage: AssetImage(
                                          'assets/images/profile.jpg')),
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blueAccent.withOpacity(0.3),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(CupertinoIcons.search))
                      ],
                    ),
                  ),
                  user == null
                      ? const Text(
                          'Hello',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text(
                          'Hello ${user?.displayName?.split(' ')[0]}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  const Text(
                    'Wanna take a ride today?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: TextField(
                        cursorColor: Colors.white.withOpacity(0.5),
                        cursorWidth: 1,
                        onSubmitted: (String value) {
                          navigateToLocation(value);
                        },
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(CupertinoIcons.map_pin_ellipse),
                          hintText: 'Where are you going?',
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )),
                  const SizedBox(
                    height: 15,
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.cloud_sun,
                              size: 100,
                            ),
                            RichText(
                                text: TextSpan(
                                    text: '23°',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600),
                                    children: const <TextSpan>[
                                  TextSpan(
                                      text: ' Clear',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400)),
                                  TextSpan(
                                      text: '\nVivekanand Education Society',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal))
                                ]))
                          ],
                        ),
                        Text(
                          '$date $currentMonth, $currentDay',
                          style: GoogleFonts.montserrat(fontSize: 22),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 5.0),
                    child: Text(
                      'Recently Searched',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.5), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(CupertinoIcons.pin_fill),
                    title: const Text(
                      'VIVA Institute Of Technology',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Virar, Palghar'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.5), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(CupertinoIcons.pin_fill),
                    title: const Text(
                      'Jio World BKC',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Bandra, Mumbai'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color: Colors.white.withOpacity(0.5), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(CupertinoIcons.pin_fill),
                    title: const Text(
                      'The Capital Mall',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Nalasopara, Palghar'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
