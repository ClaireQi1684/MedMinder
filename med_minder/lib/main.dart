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

  runApp(MaterialApp(home: MedMinder()));
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

class MedMinderState extends State<MedMinder> {
  int currentScreenIndex = 2;
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

  Timer? midnightTimer;

  // Schedules rollover for the next local midnight.
  void scheduleMidnightTask() {
    midnightTimer?.cancel();

    final now = tz.TZDateTime.now(tz.local);

    final nextMidnight = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + 1,
    );

    final durationToWait = nextMidnight.difference(now);

    debugPrint('Current time: $now');
    debugPrint('Next rollover: $nextMidnight');
    debugPrint('Time remaining: $durationToWait');

    midnightTimer = Timer(durationToWait, () {
      if (!mounted) return;

      debugPrint('MIDNIGHT TIMER FIRED');

      rollOverToNewDay();
      scheduleMidnightTask();
    });
  }

  // Rolls the oldest day to the end and resets its checks.
  // Rolls the oldest day to the end and resets its checks.
  void rollOverToNewDay() {
    setState(() {
      // Remove the oldest day's data.
      final int oldPillCount = pillsPerDay.removeAt(0);
      pillCheck.removeAt(0);
      dayCheck.removeAt(0);

      // Remove the oldest weekday label.
      final String oldDay = screens.removeAt(2);

      pillsPerDay.add(oldPillCount);
      pillCheck.add(List<int>.filled(oldPillCount, 0));
      dayCheck.add(0);
      screens.add(oldDay);

      // Keep the current view anchored correctly after the shift
      if (currentScreenIndex >= 2) {
        currentScreenIndex = (currentScreenIndex > 2)
            ? currentScreenIndex - 1
            : 2;
      }
    });

    saveData();
  }

  @override
  void dispose() {
    midnightTimer?.cancel();
    super.dispose();
  }

  List<Pill> pills = [];

  int checkCounter = 0;

  final now = tz.TZDateTime.now(tz.local);
  String get dayName => DateFormat("EEEE").format(now);

  List<int> pillsPerDay = List.filled(7, 0, growable: true);

  List<List<int>> pillCheck = List.generate(
    7,
    (dayIndex) => [],
    growable: true,
  );

  List<int> dayCheck = List.filled(7, 0, growable: true);

  String get currentDay => screens[currentScreenIndex];

  int get currentDayIndex => currentScreenIndex - 2;

  @override
  void initState() {
    super.initState();
    initializeApp();
  }

  Future<void> initializeApp() async {
    await loadData();

    if (!mounted) return;

    scheduleMidnightTask();
  }

  Future<void> saveData() async {
    // Obtain shared preferences instance
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. Convert List<int> to List<String> for pillsPerDay
    List<String> stringPillsPerDay = pillsPerDay
        .map((e) => e.toString())
        .toList();
    await prefs.setStringList('pillsPerDay', stringPillsPerDay);

    // 2. Convert List<int> to List<String> for dayCheck
    List<String> stringDayCheck = dayCheck.map((e) => e.toString()).toList();
    await prefs.setStringList('dayCheck', stringDayCheck);

    // 3. Encode the nested List<List<int>> into a JSON string for pillCheck
    String encodedPillCheck = jsonEncode(pillCheck);
    await prefs.setString('pillCheck', encodedPillCheck);
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load pillsPerDay
      final savedPills = prefs.getStringList('pillsPerDay');
      if (savedPills != null) {
        pillsPerDay = savedPills
            .map((e) => int.parse(e))
            .toList(growable: true);
      } else {
        addPill(); // Fallback if first time opening
      }

      // Load dayCheck
      final savedDays = prefs.getStringList('dayCheck');
      if (savedDays != null) {
        dayCheck = savedDays.map((e) => int.parse(e)).toList(growable: true);
      }

      // Load pillCheck from JSON
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
    });
  }

  void nextDay() {
    setState(() {
      currentScreenIndex = currentScreenIndex + 1;
    });
  }

  void previousDay() {
    setState(() {
      currentScreenIndex = currentScreenIndex - 1;
    });
  }

  //temp method before add pill function
  void addPill() {
    for (int i = 0; i < 7; i++) {
      pillsPerDay[i] = i;
      pillCheck[i] = List.filled(pillsPerDay[i], 0);
      if (i == 0) {
        pillsPerDay[i] = 1;
        pillCheck[i] = List.filled(pillsPerDay[i], 0);
      }
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

  @override
  Widget build(BuildContext context) {
    if (currentScreenIndex == 0) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 142, 192, 218),
        appBar: AppBar(
          title: const Text("MedMinder"),
          backgroundColor: const Color.fromARGB(255, 84, 115, 141),
        ),
      );
    } else if (currentScreenIndex == 1) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 142, 192, 218),
        appBar: AppBar(
          title: const Text("MedMinder edit"),
          backgroundColor: const Color.fromARGB(255, 84, 115, 141),
        ),
      );
      // } else if (currentScreenIndex == 9) {
      //   return Scaffold(
      //     appBar: AppBar(title: const Text("Scheduled Notifications Demo")),
      //     body: Center(
      //       child: ElevatedButton(
      //         onPressed: () {
      //           final scheduledTime = DateTime.now().add(
      //             const Duration(seconds: 10),
      //           );
      //           NotificationService.scheduleNotification(
      //             id: 1,
      //             title: "Congratulations!!!",
      //             body: "You've successfully implemented scheduled notification",
      //             scheduledTime: scheduledTime,
      //           );
      //         },
      //         child: const Text("Schedule Notification in 10s"),
      //       ),
      //     ),
      //   );
    } else {
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
              SizedBox(height: 9),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        currentScreenIndex = 0;
                      });
                    },
                    icon: Icon(Icons.home_filled),
                  ),
                  SizedBox(width: 150),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        currentScreenIndex = 1;
                      });
                    },
                    icon: Icon(Icons.edit),
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
                          children: List.generate(pillsPerDay[currentDayIndex], (
                            index,
                          ) {
                            int pillNum = index + 1;
                            return Container(
                              padding: const EdgeInsets.all(7.0),
                              color: Colors.lime,
                              child: Column(
                                children: [
                                  Center(child: Text("Pill $pillNum")),
                                  Center(
                                    child:
                                        pillCheck[currentDayIndex][index] % 2 ==
                                            0
                                        ? ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                pillCheck[currentDayIndex][index]++;
                                              });
                                              saveData();
                                              print("pill $index completed");
                                            },
                                            style: ElevatedButton.styleFrom(
                                              fixedSize: const Size(145, 145),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "MARK AS TAKEN",
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ),
                                          )
                                        : IconButton(
                                            onPressed: () {
                                              setState(() {
                                                pillCheck[currentDayIndex][index]++;
                                              });
                                              saveData();
                                              print("pill $index completed");
                                            },
                                            icon: Icon(Icons.check),
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
                        Container(
                          padding: EdgeInsets.only(
                            // top: 8.0,
                            left: 8.0,
                            // right: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: !allPillsTaken(currentDayIndex)
                                    ? ElevatedButton(
                                        onPressed: () {
                                          print("$currentDay not completed");
                                          setState(() {
                                            dayCheck[currentDayIndex] += 0;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          fixedSize: const Size(400, 75),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "PILLS NOT TAKEN",
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      )
                                    : dayCheck[currentDayIndex] == 0
                                    ? ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            dayCheck[currentDayIndex]++;
                                          });
                                          saveData();
                                          print("$currentDay completed");
                                        },
                                        style: ElevatedButton.styleFrom(
                                          fixedSize: const Size(400, 75),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "MARK AS DONE",
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        onPressed: () {
                                          print("$currentDay completed");
                                        },
                                        icon: Icon(Icons.check),
                                        iconSize: 65,
                                        style: IconButton.styleFrom(
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
              Row(
                children: [
                  (currentScreenIndex == 2)
                      ? SizedBox(width: 8)
                      : SizedBox(width: 0),
                  (currentScreenIndex > 2)
                      ? IconButton(
                          icon: Icon(Icons.arrow_left_rounded),
                          onPressed: () {
                            previousDay();
                            saveData();
                          },
                          iconSize: 70.0,
                        )
                      : Icon(
                          Icons.arrow_left_rounded,
                          color: const Color.fromARGB(255, 128, 140, 149),
                          size: 70.0,
                        ),
                  (currentScreenIndex == 2)
                      ? SizedBox(width: 8)
                      : SizedBox(width: 0),
                  Center(
                    child: Text(
                      currentDay,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  (currentScreenIndex == screens.length - 1)
                      ? SizedBox(width: 8)
                      : SizedBox(width: 0),
                  (currentScreenIndex < screens.length - 1)
                      ? IconButton(
                          icon: Icon(Icons.arrow_right_rounded),
                          onPressed: () {
                            nextDay();
                            saveData();
                          },
                          iconSize: 70.0,
                        )
                      : Icon(
                          Icons.arrow_right_rounded,
                          color: const Color.fromARGB(255, 128, 140, 149),
                          size: 70.0,
                        ),
                  (currentScreenIndex == screens.length - 1)
                      ? SizedBox(width: 8)
                      : SizedBox(width: 0),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}
