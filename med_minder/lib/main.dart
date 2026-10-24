import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  tz.initializeTimeZones();
  final TimezoneInfo timeZoneInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

  runApp(const MaterialApp(home: MedMinder()));
}

class Pill {
  String pillName = "";
  List<int> numTimesTaken = [];

  Pill(String name, List<int> numTimes) {
    pillName = name;
    numTimesTaken = numTimes;
  }

  String getName() {
    return pillName;
  }

  int getNumTimesTakenOnDay(int dayIndex) {
    return numTimesTaken[dayIndex];
  }
}

class MedMinder extends StatefulWidget {
  const MedMinder({super.key});

  @override
  State<MedMinder> createState() => MedMinderState();
}

class MedMinderState extends State<MedMinder> with WidgetsBindingObserver {
  int currentScreenIndex = 0;
  int editingDayIndex =
      2; // Tracks which day screen was being viewed before entering edit mode

  final List<String> screens = [
    "home",
    "edit",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  // History variable to persist past days' data
  List<Map<String, dynamic>> pillHistory = [];

  void rollOverToNewDay() {
    setState(() {
      // Archive expiring day's data to history before removal
      if (pillsPerDay.isNotEmpty &&
          pillNames.isNotEmpty &&
          pillCheck.isNotEmpty) {
        final expiredDayData = {
          'date': lastRecordedDate.toIso8601String(),
          'pillNames': List<String>.from(pillNames[0]),
          'pillCheck': List<int>.from(pillCheck[0]),
          'pillTargets': List<int>.from(pillTargets[0]),
          'dayCompleted': dayCheck[0],
        };
        pillHistory.add(expiredDayData);
      }

      // Capture the latest pill configuration from Today (index 0)
      // before it's removed, preserving any added or modified pills!
      final List<String> latestPillNames = List<String>.from(pillNames[0]);
      final List<int> latestPillTargets = List<int>.from(pillTargets[0]);
      final int latestPillCount = latestPillNames.length;
      final List<List<int>> latestPillNotificationsIDs = List<List<int>>.from(
        notificationIDs[0],
      );

      pillsPerDay.removeAt(0);
      pillCheck.removeAt(0);
      pillTargets.removeAt(0);
      pillNames.removeAt(0);
      dayCheck.removeAt(0);
      notificationIDs.removeAt(0);

      pillsPerDay.add(latestPillCount);
      pillCheck.add(List<int>.filled(latestPillCount, 0, growable: true));
      pillTargets.add(latestPillTargets);
      pillNames.add(latestPillNames);
      dayCheck.add(0);
      notificationIDs.add(latestPillNotificationsIDs);

      if (currentScreenIndex > 2) {
        currentScreenIndex--;
      }
    });
    saveData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  List<Pill> pills = [];
  int checkCounter = 0;

  int get selectedDayIndex {
    if (currentScreenIndex == 1) {
      return editingDayIndex - 2;
    }
    return currentScreenIndex - 2;
  }

  double timeWaking = 6;
  double timeAsleep = 22;

  final now = tz.TZDateTime.now(tz.local);
  String get dayName => DateFormat("EEEE").format(now);

  List<int> pillsPerDay = List.filled(7, 0, growable: true);

  List<List<int>> pillCheck = List.generate(
    7,
    (dayIndex) => [],
    growable: true,
  );

  List<List<int>> pillTargets = List.generate(
    7,
    (dayIndex) => [],
    growable: true,
  );

  List<List<String>> pillNames = List.generate(
    7,
    (dayIndex) => [],
    growable: true,
  );

  var lastRecordedDate = tz.TZDateTime.now(tz.local);

  List<int> dayCheck = List.filled(7, 0, growable: true);

  List<List<List<int>>> notificationIDs = List.generate(
    7,
    (_) => [],
    growable: true,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeApp();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      checkForRollOver();
    }
  }

  Future<void> checkForRollOver() async {
    final now = tz.TZDateTime.now(tz.local);

    final todayDate = tz.TZDateTime(tz.local, now.year, now.month, now.day);
    final lastDate = tz.TZDateTime(
      tz.local,
      lastRecordedDate.year,
      lastRecordedDate.month,
      lastRecordedDate.day,
    );

    int dayDifference = todayDate.difference(lastDate).inDays;

    if (dayDifference != 0) {
      for (int i = 0; i < dayDifference; i++) {
        rollOverToNewDay();
      }
    }

    lastRecordedDate = now;
    saveData();
  }

  Future<void> initializeApp() async {
    await loadData();

    if (!mounted) return;

    await checkForRollOver();
  }

  Future<void> saveData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> stringPillsPerDay = pillsPerDay
        .map((e) => e.toString())
        .toList();
    await prefs.setStringList('pillsPerDay', stringPillsPerDay);

    List<String> stringDayCheck = dayCheck.map((e) => e.toString()).toList();
    await prefs.setStringList('dayCheck', stringDayCheck);

    String encodedPillCheck = jsonEncode(pillCheck);
    await prefs.setString('pillCheck', encodedPillCheck);

    String encodedNotificationIDs = jsonEncode(notificationIDs);
    await prefs.setString('notificationIDs', encodedNotificationIDs);

    String encodedPillTargets = jsonEncode(pillTargets);
    await prefs.setString('pillTargets', encodedPillTargets);

    String encodedPillNames = jsonEncode(pillNames);
    await prefs.setString('pillNames', encodedPillNames);

    String encodedHistory = jsonEncode(pillHistory);
    await prefs.setString('pillHistory', encodedHistory);

    await prefs.setString(
      'lastRecordedDate',
      lastRecordedDate.toIso8601String(),
    );
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final savedPills = prefs.getStringList('pillsPerDay');
      if (savedPills != null) {
        pillsPerDay = savedPills
            .map((e) => int.parse(e))
            .toList(growable: true);
      }

      final savedDays = prefs.getStringList('dayCheck');
      if (savedDays != null) {
        dayCheck = savedDays.map((e) => int.parse(e)).toList(growable: true);
      }

      final savedPillCheckJson = prefs.getString('pillCheck');
      if (savedPillCheckJson != null) {
        List<dynamic> decoded = jsonDecode(savedPillCheckJson);
        pillCheck = decoded
            .map(
              (innerList) => (innerList as List)
                  .map((e) => e as int)
                  .toList(growable: true),
            )
            .toList(growable: true);
      }

      final savedPillTargetsJson = prefs.getString('pillTargets');
      if (savedPillTargetsJson != null) {
        List<dynamic> decoded = jsonDecode(savedPillTargetsJson);
        pillTargets = decoded
            .map(
              (innerList) => (innerList as List)
                  .map((e) => e as int)
                  .toList(growable: true),
            )
            .toList(growable: true);
      }

      final savedNotificationIDJson = prefs.getString('notificationIDs');
      if (savedNotificationIDJson != null) {
        List<dynamic> decoded = jsonDecode(savedNotificationIDJson);
        notificationIDs = decoded
            .map(
              (innerList) => (innerList as List)
                  .map(
                    (innerList) => (innerList as List)
                        .map((e) => e as int)
                        .toList(growable: true),
                  )
                  .toList(growable: true),
            )
            .toList(growable: true);
      }

      final savedPillNamesJson = prefs.getString('pillNames');
      if (savedPillNamesJson != null) {
        List<dynamic> decoded = jsonDecode(savedPillNamesJson);
        pillNames = decoded
            .map(
              (innerList) => (innerList as List)
                  .map((e) => e.toString())
                  .toList(growable: true),
            )
            .toList(growable: true);
      }

      final savedHistoryJson = prefs.getString('pillHistory');
      if (savedHistoryJson != null) {
        List<dynamic> decodedHistory = jsonDecode(savedHistoryJson);
        pillHistory = decodedHistory
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: true);
      }

      // SAFETY SYNC: Ensure lists match pillsPerDay to prevent out-of-bounds errors
      while (pillsPerDay.length < 7) pillsPerDay.add(0);
      while (pillCheck.length < 7) pillCheck.add([]);
      while (pillTargets.length < 7) pillTargets.add([]);
      while (pillNames.length < 7) pillNames.add([]);
      while (dayCheck.length < 7) dayCheck.add(0);
      while (notificationIDs.length < 7) notificationIDs.add([]);

      for (int i = 0; i < 7; i++) {
        if (pillCheck[i].length < pillsPerDay[i]) {
          pillCheck[i].addAll(
            List.filled(
              pillsPerDay[i] - pillCheck[i].length,
              0,
              growable: true,
            ),
          );
        } else if (pillCheck[i].length > pillsPerDay[i]) {
          pillCheck[i] = pillCheck[i].sublist(0, pillsPerDay[i]);
        }

        if (pillTargets[i].length < pillsPerDay[i]) {
          pillTargets[i].addAll(
            List.filled(
              pillsPerDay[i] - pillTargets[i].length,
              1,
              growable: true,
            ),
          );
        } else if (pillTargets[i].length > pillsPerDay[i]) {
          pillTargets[i] = pillTargets[i].sublist(0, pillsPerDay[i]);
        }

        if (notificationIDs[i].length < pillsPerDay[i]) {
          notificationIDs[i].addAll(
            List.generate(
              pillsPerDay[i] - notificationIDs[i].length,
              (index) => <int>[],
              growable: true,
            ),
          );
        } else if (notificationIDs[i].length > pillsPerDay[i]) {
          notificationIDs[i] = notificationIDs[i].sublist(0, pillsPerDay[i]);
        }

        if (pillNames[i].length < pillsPerDay[i]) {
          int start = pillNames[i].length;
          for (int k = start; k < pillsPerDay[i]; k++) {
            pillNames[i].add("Pill ${k + 1}");
          }
        } else if (pillNames[i].length > pillsPerDay[i]) {
          pillNames[i] = pillNames[i].sublist(0, pillsPerDay[i]);
        }
      }

      final savedDateString = prefs.getString('lastRecordedDate');
      if (savedDateString != null) {
        lastRecordedDate = tz.TZDateTime.parse(tz.local, savedDateString);
      } else {
        lastRecordedDate = tz.TZDateTime.now(tz.local);
      }
    });
  }

  void nextDay() {
    if (currentScreenIndex < 8) {
      setState(() {
        currentScreenIndex++;
      });
    }
  }

  void previousDay() {
    if (currentScreenIndex > 2) {
      setState(() {
        currentScreenIndex--;
      });
    }
  }

  void addPill() {
    for (int i = 0; i < 7; i++) {
      pillsPerDay[i] = 4;
      pillCheck[i] = List.filled(4, 0, growable: true);
      pillTargets[i] = List.filled(4, 1, growable: true);
      pillNames[i] = List.generate(4, (index) => "Pill ${index + 1}");
    }
  }

  bool allPillsTaken(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= pillsPerDay.length) return false;
    for (int i = 0; i < pillsPerDay[dayIndex]; i++) {
      if (i >= pillCheck[dayIndex].length ||
          i >= pillTargets[dayIndex].length) {
        return false;
      }
      if (pillCheck[dayIndex][i] < pillTargets[dayIndex][i]) {
        return false;
      }
    }
    return true;
  }

  String getDayLabel(int index) {
    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final date = today.add(Duration(days: index));
    return DateFormat('EEEE').format(date);
  }

  void sendNotification(int pillID, int dayID, int timesTaken) {
    DateTime now = tz.TZDateTime.now(tz.local);
    double timeBetween = 0;
    if (((now.weekday - 1) != dayID) || (now.hour >= 22)) {
      timeBetween = (timeAsleep - timeWaking) / timesTaken;
    } else {
      int hoursToBedtime = 22 - now.hour;
      DateTime bedtimeToday = now.add(Duration(hours: hoursToBedtime));
      bedtimeToday = bedtimeToday.copyWith(minute: 0, second: 0);
      timeBetween = (bedtimeToday.hour - now.hour - 1) / timesTaken;
    }

    while (notificationIDs[dayID].length <= pillID) {
      notificationIDs[dayID].add([]);
    }
    notificationIDs[dayID][pillID] = List.filled(timesTaken, 0, growable: true);

    String medName = pillNames[dayID][pillID];
    for (int i = 1; i <= timesTaken; i++) {
      int uniqueID = "$dayID-$pillID-$i".hashCode;
      notificationIDs[dayID][pillID].add(uniqueID);
      int j = 0;
      while (j <= timeBetween) {
        j++;
      }
      DateTime timeScheduled = now.add(Duration(hours: j * i));
      NotificationService.scheduleNotification(
        id: uniqueID,
        title: "Take your $medName now!",
        body: "It's time to take your meds! Click into MedMinder to check it off when you're done!",
        scheduledTime: timeScheduled,
      );
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void deleteNotification(int pillID, int dayID) async {
    for (int i = 0; i < pillTargets[dayID][pillID]; i++) {
      int id = notificationIDs[dayID][pillID][i];
      await flutterLocalNotificationsPlugin.cancel(id: id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentScreenIndex == 0) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 142, 192, 218),
        appBar: AppBar(
          title: const Text("MedMinder"),
          backgroundColor: const Color.fromARGB(255, 84, 115, 141),
        ),
        body: Center(
          child: Column(
            children: [
              Center(
                child: Text(
                  "WELCOMED TO MEDMINDERRRRUYIUWHUHS",
                  style: TextStyle(fontSize: 70),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    currentScreenIndex = 2;
                  });
                },
                iconSize: 300,
                icon: const Icon(Icons.calendar_today),
              ),
            ],
          ),
        ),
      );
    } else {
      bool isEditing = (currentScreenIndex == 1);

      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 142, 192, 218),
        appBar: AppBar(
          title: const Text("MedMinder"),
          backgroundColor: const Color.fromARGB(255, 84, 115, 141),
        ),
        body: FittedBox(
          fit: BoxFit.contain,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 9),
              Row(
                children: [
                  isEditing
                      ? IconButton(
                          onPressed: () {
                            setState(() {
                              currentScreenIndex = editingDayIndex;
                            });
                          },
                          icon: const Icon(Icons.arrow_back),
                        )
                      : IconButton(
                          onPressed: () {
                            setState(() {
                              currentScreenIndex = 0;
                            });
                          },
                          icon: const Icon(Icons.home_filled),
                        ),
                  const SizedBox(width: 150),
                  isEditing
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: () {
                            setState(() {
                              editingDayIndex = currentScreenIndex;
                              currentScreenIndex = 1;
                            });
                          },
                          icon: const Icon(Icons.edit),
                        ),
                ],
              ),
              // DAY CARD
              Center(
                child: Container(
                  height: 680,
                  width: 400,
                  margin: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: GridView.count(
                            primary: false,
                            physics: const ClampingScrollPhysics(),
                            shrinkWrap: true,
                            crossAxisCount: 2,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                            padding: const EdgeInsets.all(10.0),
                            children: List.generate(isEditing ? pillsPerDay[selectedDayIndex] + 1 : pillsPerDay[selectedDayIndex], (
                              index,
                            ) {
                              if (isEditing &&
                                  index == pillsPerDay[selectedDayIndex]) {
                                // Gray addition button in edit mode
                                return Container(
                                  padding: const EdgeInsets.all(7.0),
                                  color: Colors.grey.shade400,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          final TextEditingController
                                          nameController = TextEditingController(
                                            text:
                                                "Pill ${pillCheck[selectedDayIndex].length + 1}",
                                          );
                                          final TextEditingController
                                          targetController =
                                              TextEditingController(text: "1");

                                          final Map<String, dynamic>?
                                          newPillData =
                                              await showDialog<
                                                Map<String, dynamic>
                                              >(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                      "Add Pill",
                                                    ),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        TextField(
                                                          controller:
                                                              nameController,
                                                          decoration:
                                                              const InputDecoration(
                                                                labelText:
                                                                    "Pill Name",
                                                              ),
                                                          autofocus: true,
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        TextField(
                                                          controller:
                                                              targetController,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          decoration:
                                                              const InputDecoration(
                                                                labelText: "Required Clicks",
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(),
                                                        child: const Text(
                                                          "Cancel",
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          final int? targetVal =
                                                              int.tryParse(
                                                                targetController
                                                                    .text,
                                                              );
                                                          final String nameVal =
                                                              nameController
                                                                  .text
                                                                  .trim();
                                                          if (nameVal
                                                                  .isNotEmpty &&
                                                              targetVal !=
                                                                  null &&
                                                              targetVal > 0) {
                                                            Navigator.of(
                                                              context,
                                                            ).pop({
                                                              "name": nameVal,
                                                              "target":
                                                                  targetVal,
                                                            });
                                                          }
                                                        },
                                                        child: const Text(
                                                          "Add",
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );

                                          if (newPillData != null) {
                                            setState(() {
                                              // Adds pill ONLY to the selected day
                                              pillCheck[selectedDayIndex].add(
                                                0,
                                              );
                                              pillTargets[selectedDayIndex].add(
                                                newPillData["target"] as int,
                                              );
                                              pillNames[selectedDayIndex].add(
                                                newPillData["name"] as String,
                                              );
                                              pillsPerDay[selectedDayIndex] =
                                                  pillCheck[selectedDayIndex]
                                                      .length;

                                              while (notificationIDs[selectedDayIndex]
                                                      .length <
                                                  pillsPerDay[selectedDayIndex]) {
                                                notificationIDs[selectedDayIndex]
                                                    .add([]);
                                              }
                                            });
                                            sendNotification(
                                              pillsPerDay[selectedDayIndex] - 1,
                                              selectedDayIndex,
                                              pillTargets[selectedDayIndex][pillsPerDay[selectedDayIndex] -
                                                  1],
                                            );
                                            saveData();
                                            // print("Add pill button clicked");
                                          }
                                        },
                                        icon: const Icon(Icons.add),
                                        iconSize: 100,
                                        style: IconButton.styleFrom(
                                          fixedSize: const Size(145, 145),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              String currentPillName =
                                  pillNames[selectedDayIndex][index];
                              int currentClicks =
                                  pillCheck[selectedDayIndex][index];
                              int targetClicks =
                                  pillTargets[selectedDayIndex][index];
                              bool isTaken = currentClicks >= targetClicks;

                              return Container(
                                padding: const EdgeInsets.all(3.0),
                                color: Colors.lime,
                                child: Column(
                                  children: [
                                    Center(
                                      child: Text(
                                        currentPillName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: isEditing
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                // Top Button: Remove
                                                ElevatedButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      // Removes pill ONLY from the selected day
                                                      if (index <
                                                          pillCheck[selectedDayIndex]
                                                              .length) {
                                                        pillCheck[selectedDayIndex]
                                                            .removeAt(index);
                                                        pillTargets[selectedDayIndex]
                                                            .removeAt(index);
                                                        pillNames[selectedDayIndex]
                                                            .removeAt(index);
                                                        pillsPerDay[selectedDayIndex] =
                                                            pillCheck[selectedDayIndex]
                                                                .length;
                                                      }
                                                      deleteNotification(
                                                        pillsPerDay[selectedDayIndex],
                                                        selectedDayIndex,
                                                      );
                                                    });
                                                    saveData();
                                                    // print(
                                                    //   "Pill $index removed",
                                                    // );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        fixedSize: const Size(
                                                          145,
                                                          35,
                                                        ),
                                                        backgroundColor:
                                                            Colors.red.shade300,
                                                      ),
                                                  child: const Center(
                                                    child: Text(
                                                      "REMOVE",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                // Middle Button: Input target number
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    final TextEditingController
                                                    targetController =
                                                        TextEditingController(
                                                          text: targetClicks
                                                              .toString(),
                                                        );
                                                    final int?
                                                    newTarget = await showDialog<int>(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                            "Set Required Clicks",
                                                          ),
                                                          content: TextField(
                                                            controller:
                                                                targetController,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            decoration:
                                                                const InputDecoration(
                                                                  labelText: "Required clicks",
                                                                ),
                                                            autofocus: true,
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                              child: const Text(
                                                                "Cancel",
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () {
                                                                final int?
                                                                val = int.tryParse(
                                                                  targetController
                                                                      .text,
                                                                );
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(val);
                                                              },
                                                              child: const Text(
                                                                "Save",
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );

                                                    if (newTarget != null &&
                                                        newTarget > 0) {
                                                      setState(() {
                                                        // Updates target ONLY on the selected day
                                                        pillTargets[selectedDayIndex][index] =
                                                            newTarget;
                                                        if (pillCheck[selectedDayIndex][index] >
                                                            newTarget) {
                                                          pillCheck[selectedDayIndex][index] =
                                                              newTarget;
                                                        }
                                                      });
                                                      saveData();
                                                    }
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        fixedSize: const Size(
                                                          145,
                                                          35,
                                                        ),
                                                        backgroundColor: Colors
                                                            .blue
                                                            .shade300,
                                                      ),
                                                  child: Center(
                                                    child: Text(
                                                      "Target: $targetClicks",
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                // Bottom Button: Edit Pill Name
                                                ElevatedButton(
                                                  onPressed: () async {
                                                    final TextEditingController
                                                    nameController =
                                                        TextEditingController(
                                                          text: currentPillName,
                                                        );
                                                    final String?
                                                    newName = await showDialog<String>(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          title: const Text(
                                                            "Edit Pill Name",
                                                          ),
                                                          content: TextField(
                                                            controller:
                                                                nameController,
                                                            decoration:
                                                                const InputDecoration(
                                                                  labelText: "Pill Name",
                                                                ),
                                                            autofocus: true,
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                              child: const Text(
                                                                "Cancel",
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () {
                                                                Navigator.of(
                                                                  context,
                                                                ).pop(
                                                                  nameController
                                                                      .text
                                                                      .trim(),
                                                                );
                                                              },
                                                              child: const Text(
                                                                "Save",
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );

                                                    if (newName != null &&
                                                        newName.isNotEmpty) {
                                                      setState(() {
                                                        // Updates name ONLY on the selected day
                                                        pillNames[selectedDayIndex][index] =
                                                            newName;
                                                      });
                                                      saveData();
                                                    }
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        fixedSize: const Size(
                                                          145,
                                                          35,
                                                        ),
                                                        backgroundColor: Colors
                                                            .orangeAccent
                                                            .shade200,
                                                      ),
                                                  child: const Center(
                                                    child: Text(
                                                      "Edit Name",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : !isTaken
                                          ? ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  pillCheck[selectedDayIndex][index]++;
                                                });
                                                saveData();
                                                // print("pill $index completed");
                                              },
                                              style: ElevatedButton.styleFrom(
                                                fixedSize: const Size(145, 145),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "TAKE\n($currentClicks/$targetClicks)",
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            )
                                          : IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  pillCheck[selectedDayIndex][index] =
                                                      0;
                                                });
                                                saveData();
                                                // print("pill $index reset");
                                              },
                                              icon: const Icon(Icons.check),
                                              iconSize: 130,
                                              style: IconButton.styleFrom(
                                                fixedSize: const Size(145, 145),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child:
                                    !allPillsTaken(selectedDayIndex) &&
                                        !isEditing
                                    ? ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            dayCheck[selectedDayIndex] += 0;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          fixedSize: const Size(400, 75),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "PILLS NOT TAKEN",
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      )
                                    : dayCheck[selectedDayIndex] == 0 &&
                                          !isEditing
                                    ? ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            dayCheck[selectedDayIndex]++;
                                          });
                                          saveData();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          fixedSize: const Size(400, 75),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "MARK AS DONE",
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      )
                                    : !isEditing
                                    ? IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.check),
                                        iconSize: 65,
                                        style: ElevatedButton.styleFrom(
                                          fixedSize: const Size(400, 75),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              isEditing
                  ? const SizedBox.shrink()
                  : Row(
                      children: [
                        (currentScreenIndex == 2)
                            ? const SizedBox(width: 8)
                            : const SizedBox(width: 0),
                        (currentScreenIndex > 2)
                            ? IconButton(
                                icon: const Icon(Icons.arrow_left_rounded),
                                onPressed: () {
                                  previousDay();
                                },
                                iconSize: 70.0,
                              )
                            : const Icon(
                                Icons.arrow_left_rounded,
                                color: Color.fromARGB(255, 128, 140, 149),
                                size: 70.0,
                              ),
                        (currentScreenIndex == 2)
                            ? const SizedBox(width: 8)
                            : const SizedBox(width: 0),
                        Center(
                          child: Text(
                            getDayLabel(currentScreenIndex - 2),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        (currentScreenIndex == screens.length - 1)
                            ? const SizedBox(width: 8)
                            : const SizedBox(width: 0),
                        (currentScreenIndex < screens.length - 1)
                            ? IconButton(
                                icon: const Icon(Icons.arrow_right_rounded),
                                onPressed: () {
                                  nextDay();
                                },
                                iconSize: 70.0,
                              )
                            : const Icon(
                                Icons.arrow_right_rounded,
                                color: Color.fromARGB(255, 128, 140, 149),
                                size: 70.0,
                              ),
                        (currentScreenIndex == screens.length - 1)
                            ? const SizedBox(width: 8)
                            : const SizedBox(width: 0),
                      ],
                    ),
            ],
          ),
        ),
      );
    }
  }
}
