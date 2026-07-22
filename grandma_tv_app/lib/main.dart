import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const GrandmaTVApp());
}

class GrandmaTVApp extends StatelessWidget {
  const GrandmaTVApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'לוח שידורים לסבתא',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      home: const TVGuideHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TVGuideHomePage extends StatefulWidget {
  const TVGuideHomePage({Key? key}) : super(key: key);

  @override
  _TVGuideHomePageState createState() => _TVGuideHomePageState();
}

class _TVGuideHomePageState extends State<TVGuideHomePage> {
  Map<String, dynamic>? tvData;
  bool isLoading = true;
  String selectedChannelId = 'CH34';

  final Map<String, String> channels = {
    'TV50': 'ערוץ 9',
    'CH34': 'ערוץ 12',
    'CH36': 'ערוץ 13',
    'PT92': 'ערוץ 14',
  };

  @override
  void initState() {
    super.initState();
    loadTvGuide(); // Load the guide when the app starts
  }

  Future<void> loadTvGuide() async {
    try {
      // Fetch the raw JSON file directly from GitHub
      // Adding a timestamp to the URL to bypass GitHub and browser cache
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('https://raw.githubusercontent.com/usenderowitz/GrandmaTVApp/main/grandma_tv_app/assets/tv_guide.json?v=$timestamp'),
      );

      if (response.statusCode == 200) {
        // Decode the JSON data received from the network
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        
        // Update the UI with the new data and stop the loading spinner
        setState(() {
          tvData = decodedData;
          isLoading = false;
        });
      } else {
        // Throw an error if the server fails to return the file
        throw Exception('Failed to load TV guide from network');
      }
    } catch (e) {
      // Print the error to the console and stop loading
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'לוח טלוויזיה לסבתא',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.blueGrey[800],
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    color: Colors.blueGrey[900],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: channels.entries.map((entry) {
                        bool isSelected = selectedChannelId == entry.key;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected ? Colors.amber : Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedChannelId = entry.key;
                                });
                              },
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(color: Colors.white54, height: 1),
                  Expanded(
                    child: _buildProgramList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildProgramList() {
    if (tvData == null || tvData!['items'] == null) {
      return const Center(
        child: Text('אין נתונים זמינים', style: TextStyle(color: Colors.white, fontSize: 26)),
      );
    }

    List items = tvData!['items'];
    List channelPrograms = items.where((item) => item['channelId'] == selectedChannelId).toList();

    if (channelPrograms.isEmpty) {
      return const Center(
        child: Text('אין תוכניות להצגה בערוץ זה', style: TextStyle(color: Colors.white, fontSize: 26)),
      );
    }

    return ListView.builder(
      itemCount: channelPrograms.length,
      itemBuilder: (context, index) {
        var currentProgram = channelPrograms[index];
        return Card(
          color: Colors.blueGrey[800],
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        currentProgram['title'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${currentProgram['starts_local'] ?? ''}\n${currentProgram['ends_local'] ?? ''}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  currentProgram['description'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}