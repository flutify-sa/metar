// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart'; // Import this for CupertinoSwitch
import 'package:metar/themeprovider.dart';
import 'package:provider/provider.dart'; // Import this for ThemeProvider

class MetarScreen extends StatefulWidget {
  const MetarScreen({super.key});

  @override
  MetarScreenState createState() => MetarScreenState();
}

class MetarScreenState extends State<MetarScreen> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<Map<String, dynamic>>> metarData =
      Future.value([]); // Default empty list, updated to List

  // Function to fetch METAR data
  Future<List<Map<String, dynamic>>> fetchMetar(String station) async {
    final String apiUrl =
        'https://aviationweather.gov/api/data/metar?ids=$station&format=json&taf=true'; // Updated URL

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'User-Agent': 'com.example.metar', // Your app's name
        },
      );

      // Print the raw response to debug the issue
      //  print('Response Body: ${response.body}');

      // Check if the response is successful
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        // Print error details to the terminal
        // print('Error: Failed to load METAR data');
        // print('Status Code: ${response.statusCode}');
        // print('Response Body: ${response.body}');
        throw Exception('Failed to load METAR data');
      }
    } catch (e) {
      // Catch and print any errors (like network errors)
      print('Error occurred: $e');
      throw Exception('Failed to fetch METAR data');
    }
  }

  // Trigger fetch when button is pressed
  void _fetchMetar() {
    setState(() {
      metarData = fetchMetar(_controller.text
          .toUpperCase()); // Fetch METAR for the entered airport code
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('METAR and TAF'),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.only(left: 25, top: 10, right: 25),
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dark Mode',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.inversePrimary),
                    ),
                    CupertinoSwitch(
                      value: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode,
                      onChanged: (value) =>
                          Provider.of<ThemeProvider>(context, listen: false)
                              .toggleTheme(),
                    ),
                  ],
                ),
              ),
              //     const SizedBox(height: 30),
              Container(
                margin: EdgeInsets.only(left: 25, top: 10, right: 25),
                padding: EdgeInsets.all(20),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Enter Airport ICAO Code',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _fetchMetar,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.black),
                  padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(vertical: 12, horizontal: 20)),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                child: Text(
                  'Get METAR and TAF',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: metarData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    var data = snapshot
                        .data!.first; // Access the first element of the list
                    // Display the METAR data here
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('METAR and TAF for ${data['icaoId']}'),
                          SizedBox(height: 10),
                          Text('METAR:\n${data['rawOb']}'),
                          SizedBox(height: 10),
                          Text('TAF:\n${data['rawTaf']}'),
                        ],
                      ),
                    );
                  }
                  return Center(child: Text('No data available'));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
