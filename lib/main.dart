import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/entry_page.dart'; // Entry page ko import kiya

// App yahan se shuru hoga
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classes Management',
      debugShowCheckedModeBanner: false,

      // ---------- THEME UPDATE KIYA HAI (LIGHT THEME) ----------
      theme: ThemeData.light().copyWith(
        // Primary color sky blue rakha hai
        primaryColor: Colors.lightBlue[400],
        scaffoldBackgroundColor: Colors.white, // Background white kar diya hai

        colorScheme: const ColorScheme.light().copyWith(
          primary: Colors.lightBlue[400]!,
          secondary: Colors.lightBlueAccent[200]!,
        ),

        // App bar ko transparent rakha hai
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black), // Icon color black kiya
            titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold) // Title color black kiya
        ),

        // Input fields ka default style light theme ke liye
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200], // Light theme ke liye fill color change kiya
        ),

        // Text theme set kiya hai light background ke liye
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      home: const EntryPage(),
    );
  }
}

