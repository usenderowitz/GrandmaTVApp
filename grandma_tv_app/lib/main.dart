import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Added for local storage

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
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[800],
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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

  // Active channels list (will be loaded from local storage)
  List<String> activeChannels = [];
  String selectedChannelName = 'ערוץ 12';

  // Dictionary mapping channel names to yes.co.il internal IDs
  final Map<String, String> knownChannelIds = {
    'ערוץ 1': 'YSA1',
    'ערוץ 2': 'YSA2',
    'ערוץ 3': 'YSA3',
    'ערוץ 4': 'YSAU',
    'ערוץ 5': 'YS19',
    'ערוץ 6': 'YS20',
    'ערוץ 7': 'YS22',
    'ערוץ 8': 'YSAT',
    'ערוץ 9': 'TV50',
    'ערוץ 10': 'FILL_ID_HERE', // TODO: Replace when ID is found
    'ערוץ 11': 'CH30',
    'ערוץ 12': 'CH34',
    'ערוץ 13': 'CH36',
    'ערוץ 14': 'PT92',
    'ערוץ 15': 'CN28',
    'ערוץ 22': 'CH65',
    'ערוץ 181': 'TV81',
    'ערוץ 182': 'TV82',
    'ערוץ 183': 'CN03',
    'ערוץ 184': 'TV85',
    'ערוץ 185': 'CH24',
    'ערוץ 186': 'PT73',
    'ערוץ 187': 'PT74',
    'ערוץ 188': 'CH76',
    'ערוץ 191': 'PT51',
    'ערוץ 192': 'TV60',
    'ערוץ 195': 'PT45',
  };

  @override
  void initState() {
    super.initState();
    _loadSavedChannels(); // Load saved channels before fetching data
    loadTvGuide();
  }

  // Load channels from SharedPreferences (Local Storage)
  Future<void> _loadSavedChannels() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load saved list or use default if it's the first time running the app
      activeChannels = prefs.getStringList('saved_channels') ?? ['ערוץ 9', 'ערוץ 12', 'ערוץ 13', 'ערוץ 14'];
      
      // Ensure the selected channel is valid
      if (activeChannels.isNotEmpty && !activeChannels.contains(selectedChannelName)) {
        selectedChannelName = activeChannels.first;
      }
    });
  }

  // Save current active channels to SharedPreferences
  Future<void> _saveChannels() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_channels', activeChannels);
  }

  // Sort channels numerically (e.g. Channel 9 before Channel 12)
  void _sortChannels() {
    activeChannels.sort((a, b) {
      // Extract only the numbers from the strings
      int numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return numA.compareTo(numB);
    });
  }

  // Fetch real schedule from GitHub
  Future<void> loadTvGuide() async {
    setState(() {
      isLoading = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = 'https://raw.githubusercontent.com/usenderowitz/GrandmaTVApp/main/grandma_tv_app/assets/tv_guide.json?v=$timestamp';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        
        setState(() {
          tvData = decodedData;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load TV guide, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading TV guide: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getCurrentChannelId(String name) {
    if (knownChannelIds.containsKey(name)) {
      return knownChannelIds[name]!;
    }
    return 'UNKNOWN';
  }

  // Show dialog to add a new channel
  void _showAddChannelDialog() {
    TextEditingController channelController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('הוספת ערוץ חדש'),
            content: TextField(
              controller: channelController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'מספר ערוץ (לדוגמה 11)',
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ביטול', style: TextStyle(fontSize: 18)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {
                  if (channelController.text.isNotEmpty) {
                    String newChannelName = 'ערוץ ${channelController.text}';
                    
                    // Validate: Check if the channel exists in our known list
                    if (!knownChannelIds.containsKey(newChannelName)) {
                      Navigator.of(context).pop(); // Close the dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$newChannelName לא נמצא ברשימה הנתמכת.', textAlign: TextAlign.right),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      return; // Stop execution, don't add the channel
                    }

                    // If valid, add, sort, and save
                    setState(() {
                      if (!activeChannels.contains(newChannelName)) {
                        activeChannels.add(newChannelName);
                        _sortChannels(); // Sort numerically after adding
                        _saveChannels(); // Save to local storage
                      }
                      selectedChannelName = newChannelName;
                    });
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('הוסף', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  // Confirm channel deletion
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('מחיקת ערוץ'),
            content: Text(
              'האם את בטוחה שאת רוצה למחוק את $selectedChannelName?', 
              style: const TextStyle(fontSize: 20),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('לא', style: TextStyle(fontSize: 18)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  setState(() {
                    activeChannels.remove(selectedChannelName);
                    _saveChannels(); // Save to local storage after deletion
                    
                    if (activeChannels.isNotEmpty) {
                      selectedChannelName = activeChannels.first;
                    } else {
                      selectedChannelName = '';
                    }
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('כן, למחוק', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChannelButton(String channelName) {
    bool isSelected = selectedChannelName == channelName;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedChannelName = channelName;
        });
      },
      child: Container(
        width: 95,
        height: 85,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white,
          borderRadius: BorderRadius.circular(10.0),
        ),
        alignment: Alignment.center,
        child: Text(
          channelName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
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

    String currentId = _getCurrentChannelId(selectedChannelName);
    List items = tvData!['items'];
    
    List channelPrograms = items.where((item) => item['channelId'] == currentId).toList();

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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('לוח טלוויזיה לסבתא'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 40),
                          onPressed: activeChannels.isEmpty ? null : _confirmDelete,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_box, color: Colors.lightBlueAccent, size: 40),
                          onPressed: _showAddChannelDialog,
                        ),
                      ],
                    ),
                  ),

                  if (activeChannels.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.blueGrey[900],
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: activeChannels
                                .map((channel) => _buildChannelButton(channel))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  
                  const Divider(color: Colors.white54, height: 1),
                  
                  Expanded(
                    child: _buildProgramList(),
                  ),
                ],
              ),
              
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: FloatingActionButton(
          onPressed: loadTvGuide,
          backgroundColor: Colors.amber,
          child: const Icon(Icons.refresh, size: 35, color: Colors.black),
        ),
      ),
    );
  }
}