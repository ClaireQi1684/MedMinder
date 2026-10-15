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

class MedMinderState extends State<MedMinder> with WidgetsBindingObserver {
  int currentScreenIndex = 0;
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

  // Timer? midnightTimer;

  // // Schedules rollover for the next local midnight.
  // void scheduleMidnightTask() {
  //   midnightTimer?.cancel();

  //   final now = tz.TZDateTime.now(tz.local);

  //   final nextMidnight = tz.TZDateTime(
  //     tz.local,
  //     now.year,
  //     now.month,
  //     now.day + 1,
  //   );

  //   final durationToWait = nextMidnight.difference(now);

  //   debugPrint('Current time: $now');
  //   debugPrint('Next rollover: $nextMidnight');
  //   debugPrint('Time remaining: $durationToWait');

  //   midnightTimer = Timer(durationToWait, () {
  //     if (!mounted) return;

  //     debugPrint('MIDNIGHT TIMER FIRED');

  //     rollOverToNewDay();
  //     scheduleMidnightTask();
  //   });
  // }

  // Rolls the oldest day to the end and resets its checks.
  // Rolls the oldest day to the end and resets its checks.
  // void rollOverToNewDay() {
  //   setState(() {
  //     // Remove the oldest day's data.
  //     final int oldPillCount = pillsPerDay.removeAt(0);
  //     pillCheck.removeAt(0);
  //     dayCheck.removeAt(0);

  //     // Remove the oldest weekday label.
  //     final String oldDay = screens.removeAt(2);

  //     pillsPerDay.add(oldPillCount);
  //     pillCheck.add(List<int>.filled(oldPillCount, 0));
  //     dayCheck.add(0);
  //     screens.add(oldDay);

  //     // Keep the current view anchored correctly after the shift
  //     if (currentScreenIndex >= 2) {
  //       currentScreenIndex = (currentScreenIndex > 2)
  //           ? currentScreenIndex - 1
  //           : 2;
  //     }
  //   });

  //   saveData();
  // }

  void rollOverToNewDay() {
    setState(() {
      // Remove today's data; tomorrow becomes today.
      pillsPerDay.removeAt(0);
      pillCheck.removeAt(0);
      dayCheck.removeAt(0);

      // Add a new day at the end.
      // Reuse the last day's medication count.
      final int newPillCount = pillsPerDay.last;

      pillsPerDay.add(newPillCount);
      pillCheck.add(List<int>.filled(newPillCount, 0));
      dayCheck.add(0);

      // Keep the selected calendar date selected.
      if (currentScreenIndex > 2) {
        currentScreenIndex--;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // midnightTimer?.cancel();
    super.dispose();
  }

  List<Pill> pills = [];

  int checkCounter = 0;

  int get selectedDayIndex => currentScreenIndex - 2;

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

  // String getDayName() {
  //   return screens[selectedDayIndex + 2];
  // }

  Future<void> initializeApp() async {
    await loadData();

    if (!mounted) return;

    await checkForRollOver();
    // scheduleMidnightTask();
  }

  void setDay() {}

  Future<void> saveData() async {
    // Obtain shared preferences instance
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Convert List<int> to List<String> for pillsPerDay
    List<String> stringPillsPerDay = pillsPerDay
        .map((e) => e.toString())
        .toList();
    await prefs.setStringList('pillsPerDay', stringPillsPerDay);

    // Convert List<int> to List<String> for dayCheck
    List<String> stringDayCheck = dayCheck.map((e) => e.toString()).toList();
    await prefs.setStringList('dayCheck', stringDayCheck);

    // Encode the nested List<List<int>> into a JSON string for pillCheck
    String encodedPillCheck = jsonEncode(pillCheck);
    await prefs.setString('pillCheck', encodedPillCheck);

    // Save current date string
    await prefs.setString(
      'lastRecordedDate',
      lastRecordedDate.toIso8601String(),
    );
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

  //temp method before add pill function
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

  int getDayOfYear(DateTime date) {
    return int.parse(DateFormat("D").format(date));
  }

  String getDayLabel(int index) {
    final now = tz.TZDateTime.now(tz.local);

    final today = DateTime(now.year, now.month, now.day);
    final date = today.add(Duration(days: index));

    // if (index == 0) {
    //   return 'Today - ${DateFormat('EEEE, MMM d').format(date)}';
    // }

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
        body: IconButton(
          onPressed: () {
            setState(() {
              currentScreenIndex = 2;
            });
          },
          icon: Icon(Icons.calendar_today),
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
                          children: List.generate(pillsPerDay[selectedDayIndex], (
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
                                        pillCheck[selectedDayIndex][index] %
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
                                                pillCheck[selectedDayIndex][index]++;
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
                                child: !allPillsTaken(selectedDayIndex)
                                    ? ElevatedButton(
                                        onPressed: () {
                                          // print("$currentDay not completed");
                                          setState(() {
                                            dayCheck[selectedDayIndex] += 0;
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
                                    : dayCheck[selectedDayIndex] == 0
                                    ? ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            dayCheck[selectedDayIndex]++;
                                          });
                                          saveData();
                                          // print("$currentDay completed");
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
                                          // print("$currentDay completed");
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
                      getDayLabel(currentScreenIndex - 2),
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
