import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

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
  int numTimesTaken = 0;

  Pill(String name, int numTimes) {
    pillName = name;
    numTimesTaken = numTimes;
  }

  String getName() {
    return pillName;
  }

  int getTimesTaken() {
    return numTimesTaken;
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

  void rollOverToNewDay() {
    setState(() {
      pillsPerDay.removeAt(0);
      pillCheck.removeAt(0);
      dayCheck.removeAt(0);

      final int newPillCount = pillsPerDay.last;

      pillsPerDay.add(newPillCount);
      pillCheck.add(List<int>.filled(newPillCount, 0));
      dayCheck.add(0);

      if (currentScreenIndex > 2) {
        currentScreenIndex--;
      }
    });
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

  final now = tz.TZDateTime.now(tz.local);
  String get dayName => DateFormat("EEEE").format(now);

  List<int> pillsPerDay = List.filled(7, 0, growable: true);

  List<List<int>> pillCheck = List.generate(
    7,
    (dayIndex) => [],
    growable: true,
  );

  var lastRecordedDate = tz.TZDateTime.now(tz.local);

  List<int> dayCheck = List.filled(7, 0, growable: true);

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
      } else {
        addPill();
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
      pillCheck[i] = List.filled(4, 0);
    }
  }

  bool allPillsTaken(int dayIndex) {
    for (int i = 0; i < pillsPerDay[dayIndex]; i++) {
      if (pillCheck[dayIndex][i] % 2 == 0) {
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
          child: IconButton(
            onPressed: () {
              setState(() {
                currentScreenIndex = 2;
              });
            },
            icon: const Icon(Icons.calendar_today),
          ),
        ),
      );
    } else {
      bool isEditing = (currentScreenIndex == 1);

      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 142, 192, 218),
        appBar: AppBar(
          title: Text(isEditing ? "MedMinder Edit" : "MedMinder"),
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
                        GridView.count(
                          primary: false,
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          padding: const EdgeInsets.all(10.0),
                          children: List.generate(
                            isEditing
                                ? pillsPerDay[selectedDayIndex] + 1
                                : pillsPerDay[selectedDayIndex],
                            (index) {
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
                                        onPressed: () {
                                          setState(() {
                                            pillCheck[selectedDayIndex].add(0);
                                            pillsPerDay[selectedDayIndex] =
                                                pillCheck[selectedDayIndex]
                                                    .length;
                                          });
                                          saveData();
                                          print("Add pill button clicked");
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

                              int pillNum = index + 1;
                              return Container(
                                padding: const EdgeInsets.all(7.0),
                                color: Colors.lime,
                                child: Column(
                                  children: [
                                    Center(child: Text("Pill $pillNum")),
                                    Center(
                                      child: isEditing
                                          ? ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  if (index <
                                                      pillCheck[selectedDayIndex]
                                                          .length) {
                                                    pillCheck[selectedDayIndex]
                                                        .removeAt(index);
                                                    pillsPerDay[selectedDayIndex] =
                                                        pillCheck[selectedDayIndex]
                                                            .length;
                                                  }
                                                });
                                                saveData();
                                                print("Pill $index removed");
                                              },
                                              style: ElevatedButton.styleFrom(
                                                fixedSize: const Size(145, 145),
                                                backgroundColor:
                                                    Colors.red.shade300,
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  "REMOVE",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : pillCheck[selectedDayIndex][index] %
                                                    2 ==
                                                0
                                          ? ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  pillCheck[selectedDayIndex][index]++;
                                                });
                                                saveData();
                                                print("pill $index completed");
                                              },
                                              style: ElevatedButton.styleFrom(
                                                fixedSize: const Size(145, 145),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  "MARK AS TAKEN",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  pillCheck[selectedDayIndex][index]++;
                                                });
                                                saveData();
                                                print("pill $index completed");
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
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: !allPillsTaken(selectedDayIndex)
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
                                    : dayCheck[selectedDayIndex] == 0
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
                                    : IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.check),
                                        iconSize: 65,
                                        style: ElevatedButton.styleFrom(
                                          fixedSize: const Size(400, 75),
                                        ),
                                      ),
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
