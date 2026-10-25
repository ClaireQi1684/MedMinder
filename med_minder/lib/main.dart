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
  int editingDayIndex = 2;

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

  List<Map<String, dynamic>> pillHistory = [];

  void rollOverToNewDay() {
    setState(() {
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

      final List<String> latestPillNames = List<String>.from(pillNames[0]);
      final List<int> latestPillTargets = List<int>.from(pillTargets[0]);
      final List<Map<String, int>> latestPillTimes =
          List<Map<String, int>>.from(pillTimes[0]);
      final int latestPillCount = latestPillNames.length;
      final List<List<int>> latestPillNotificationsIDs = List<List<int>>.from(
        notificationIDs[0],
      );

      pillsPerDay.removeAt(0);
      pillCheck.removeAt(0);
      pillTargets.removeAt(0);
      pillNames.removeAt(0);
      pillTimes.removeAt(0);
      dayCheck.removeAt(0);
      notificationIDs.removeAt(0);

      pillsPerDay.add(latestPillCount);
      pillCheck.add(List<int>.filled(latestPillCount, 0, growable: true));
      pillTargets.add(latestPillTargets);
      pillNames.add(latestPillNames);
      pillTimes.add(latestPillTimes);
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

  List<List<Map<String, int>>> pillTimes = List.generate(
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

    await prefs.setStringList(
      'pillsPerDay',
      pillsPerDay.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      'dayCheck',
      dayCheck.map((e) => e.toString()).toList(),
    );
    await prefs.setString('pillCheck', jsonEncode(pillCheck));
    await prefs.setString('notificationIDs', jsonEncode(notificationIDs));
    await prefs.setString('pillTargets', jsonEncode(pillTargets));
    await prefs.setString('pillNames', jsonEncode(pillNames));
    await prefs.setString('pillTimes', jsonEncode(pillTimes));
    await prefs.setString('pillHistory', jsonEncode(pillHistory));
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

      final savedPillTimesJson = prefs.getString('pillTimes');
      if (savedPillTimesJson != null) {
        List<dynamic> decoded = jsonDecode(savedPillTimesJson);
        pillTimes = decoded
            .map(
              (innerList) => (innerList as List)
                  .map((e) => Map<String, int>.from(e))
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

      while (pillsPerDay.length < 7) pillsPerDay.add(0);
      while (pillCheck.length < 7) pillCheck.add([]);
      while (pillTargets.length < 7) pillTargets.add([]);
      while (pillNames.length < 7) pillNames.add([]);
      while (pillTimes.length < 7) pillTimes.add([]);
      while (dayCheck.length < 7) dayCheck.add(0);
      while (notificationIDs.length < 7) notificationIDs.add([]);

      for (int i = 0; i < 7; i++) {
        while (pillTimes[i].length < pillsPerDay[i]) {
          pillTimes[i].add({"hour": 8, "minute": 0});
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

  Future<void> sendNotification(
    int pillID,
    int dayID,
    int totalTargetClicks,
    TimeOfDay pickedTime,
  ) async {
    final now = tz.TZDateTime.now(tz.local);

    final targetWeekday = dayID + now.weekday;
    if (targetWeekday < DateTime.monday || targetWeekday > DateTime.sunday) {
      debugPrint('ERROR: Invalid dayID: $dayID');
      return;
    }

    // 1. Calculate how many doses are actually left to take
    final int currentClicks = pillCheck[dayID][pillID];
    final int remainingDoses = totalTargetClicks - currentClicks;

    // If all doses for this pill are already taken, don't schedule any new notifications!
    if (remainingDoses <= 0) {
      debugPrint(
        'All doses already taken for pill $pillID. Skipping notification schedule.',
      );
      return;
    }

    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Find the next occurrence of the selected weekday and time.
    while (scheduledTime.weekday != targetWeekday ||
        !scheduledTime.isAfter(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    debugPrint("targetWeekday: $targetWeekday");
    debugPrint("dayID: $dayID");
    int dayOfWeek = now.weekday;
    debugPrint("current day of week: $dayOfWeek");

    // Ensure the day has a list for this pill.
    while (notificationIDs[dayID].length <= pillID) {
      notificationIDs[dayID].add([]);
    }

    // Initialize list with the size of remaining doses
    notificationIDs[dayID][pillID] = List<int>.filled(remainingDoses, 0);

    final medName = pillNames[dayID][pillID];

    // 2. Define your end window (10 PM / 22:00 on that same day)
    final endTime = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      22, // 10 PM
      0,
    );

    // 3. Calculate interval using ONLY the remaining doses
    Duration interval;
    if (scheduledTime.isBefore(endTime)) {
      final totalMinutes = endTime.difference(scheduledTime).inMinutes;
      // Divide remaining time window by remaining doses
      final intervalMinutes = totalMinutes ~/ remainingDoses;
      interval = Duration(minutes: intervalMinutes);
    } else {
      interval = const Duration(hours: 4);
    }

    // 4. Loop and schedule only the remaining doses
    for (int i = 0; i < remainingDoses; i++) {
      // Offset the hash ID by currentClicks so it doesn't conflict with past taken doses
      final uniqueID = "$dayID-$pillID-${currentClicks + i}".hashCode;
      notificationIDs[dayID][pillID][i] = uniqueID;

      final doseTime = scheduledTime.add(interval * i);

      await NotificationService.scheduleNotification(
        id: uniqueID,
        title: "Take your $medName now!",
        body: "It's time to take your meds! Click into MedMinder to check it off when you're done.",
        scheduledTime: doseTime,
      );
    }

    // 5. Debug Console Log
    debugPrint(
      '--- RESCHEDULED NOTIFICATIONS FOR $medName ($remainingDoses remaining) ---',
    );
    for (int i = 0; i < remainingDoses; i++) {
      int offsetMinutes = (interval.inMinutes * i);
      DateTime doseTime = scheduledTime.add(Duration(minutes: offsetMinutes));

      debugPrint(
        'Remaining Dose ${i + 1}: ID ${notificationIDs[dayID][pillID][i]} scheduled at $doseTime',
      );
    }
    debugPrint(
      '-----------------------------------------------------------------------',
    );
  }

  void deleteNotification(int pillID, int dayID) async {
    if (pillID < notificationIDs[dayID].length) {
      for (int id in notificationIDs[dayID][pillID]) {
        await NotificationService.cancel(id);
      }
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
              const Center(
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
                                          TimeOfDay selectedTime =
                                              const TimeOfDay(
                                                hour: 8,
                                                minute: 0,
                                              );

                                          final Map<String, dynamic>?
                                          newPillData = await showDialog<Map<String, dynamic>>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return StatefulBuilder(
                                                builder: (context, setStateDialog) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                      "Add Pill & Time",
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
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        ElevatedButton.icon(
                                                          onPressed: () async {
                                                            final TimeOfDay?
                                                            picked =
                                                                await showTimePicker(
                                                                  context:
                                                                      context,
                                                                  initialTime:
                                                                      selectedTime,
                                                                );
                                                            if (picked !=
                                                                null) {
                                                              setStateDialog(
                                                                () {
                                                                  selectedTime =
                                                                      picked;
                                                                },
                                                              );
                                                            }
                                                          },
                                                          icon: const Icon(
                                                            Icons.access_time,
                                                          ),
                                                          label: Text(
                                                            "Time: ${selectedTime.format(context)}",
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
                                                              "time":
                                                                  selectedTime,
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
                                            },
                                          );

                                          if (newPillData != null) {
                                            TimeOfDay pickedT =
                                                newPillData["time"]
                                                    as TimeOfDay;
                                            setState(() {
                                              pillCheck[selectedDayIndex].add(
                                                0,
                                              );
                                              pillTargets[selectedDayIndex].add(
                                                newPillData["target"] as int,
                                              );
                                              pillNames[selectedDayIndex].add(
                                                newPillData["name"] as String,
                                              );
                                              pillTimes[selectedDayIndex].add({
                                                "hour": pickedT.hour,
                                                "minute": pickedT.minute,
                                              });
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
                                              pickedT,
                                            );
                                            saveData();
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

                              Map<String, int> timeMap =
                                  pillTimes[selectedDayIndex][index];
                              TimeOfDay pillTime = TimeOfDay(
                                hour: timeMap["hour"] ?? 8,
                                minute: timeMap["minute"] ?? 0,
                              );

                              return Container(
                                padding: const EdgeInsets.all(3.0),
                                color: Colors.lime,
                                child: Stack(
                                  children: [
                                    Column(
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
                                                    // REMOVE Button
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          if (index <
                                                              pillCheck[selectedDayIndex]
                                                                  .length) {
                                                            pillCheck[selectedDayIndex]
                                                                .removeAt(
                                                                  index,
                                                                );
                                                            pillTargets[selectedDayIndex]
                                                                .removeAt(
                                                                  index,
                                                                );
                                                            pillNames[selectedDayIndex]
                                                                .removeAt(
                                                                  index,
                                                                );
                                                            pillTimes[selectedDayIndex]
                                                                .removeAt(
                                                                  index,
                                                                );
                                                            pillsPerDay[selectedDayIndex] =
                                                                pillCheck[selectedDayIndex]
                                                                    .length;
                                                          }
                                                          deleteNotification(
                                                            index,
                                                            selectedDayIndex,
                                                          );
                                                        });
                                                        saveData();
                                                      },
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            fixedSize:
                                                                const Size(
                                                                  145,
                                                                  35,
                                                                ),
                                                            backgroundColor:
                                                                Colors
                                                                    .red
                                                                    .shade300,
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
                                                    // TARGET Button
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
                                                                  child:
                                                                      const Text(
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
                                                                  child:
                                                                      const Text(
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
                                                            fixedSize:
                                                                const Size(
                                                                  145,
                                                                  35,
                                                                ),
                                                            backgroundColor:
                                                                Colors
                                                                    .blue
                                                                    .shade300,
                                                          ),
                                                      child: Center(
                                                        child: Text(
                                                          "Target: $targetClicks",
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    // RENAME Button
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        final TextEditingController
                                                        nameController =
                                                            TextEditingController(
                                                              text:
                                                                  currentPillName,
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
                                                                  child:
                                                                      const Text(
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
                                                                  child:
                                                                      const Text(
                                                                        "Save",
                                                                      ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );

                                                        if (newName != null &&
                                                            newName
                                                                .isNotEmpty) {
                                                          setState(() {
                                                            pillNames[selectedDayIndex][index] =
                                                                newName;
                                                          });
                                                          saveData();
                                                        }
                                                      },
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                            fixedSize:
                                                                const Size(
                                                                  145,
                                                                  35,
                                                                ),
                                                            backgroundColor:
                                                                Colors
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
                                                      if (pillCheck[selectedDayIndex][index] >=
                                                          targetClicks) {
                                                        deleteNotification(
                                                          index,
                                                          selectedDayIndex,
                                                        );
                                                      }
                                                    });
                                                    saveData();
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        fixedSize: const Size(
                                                          145,
                                                          145,
                                                        ),
                                                      ),
                                                  child: Center(
                                                    child: Text(
                                                      "TAKE\n($currentClicks/$targetClicks)",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                )
                                              : IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      pillCheck[selectedDayIndex][index] =
                                                          0;
                                                      sendNotification(
                                                        index,
                                                        selectedDayIndex,
                                                        targetClicks,
                                                        pillTime,
                                                      );
                                                    });
                                                    saveData();
                                                  },
                                                  icon: const Icon(Icons.check),
                                                  iconSize: 130,
                                                  style: IconButton.styleFrom(
                                                    fixedSize: const Size(
                                                      145,
                                                      145,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                    // Alarm clock icon displays ONLY on main cards (not on edit screen)
                                    if (!isEditing)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.alarm,
                                            size: 20,
                                            color: Colors.black54,
                                          ),
                                          // Inside your alarm clock icon onPressed:
                                          onPressed: () async {
                                            final TimeOfDay? picked =
                                                await showTimePicker(
                                                  context: context,
                                                  initialTime: pillTime,
                                                );
                                            if (picked != null) {
                                              setState(() {
                                                pillTimes[selectedDayIndex][index] =
                                                    {
                                                      "hour": picked.hour,
                                                      "minute": picked.minute,
                                                    };
                                              });
                                              saveData();

                                              // 1. Cancel old alarms
                                              deleteNotification(
                                                index,
                                                selectedDayIndex,
                                              );

                                              // 2. Schedule new alarms passing the targetClicks (it will factor in currentClicks automatically)
                                              sendNotification(
                                                index,
                                                selectedDayIndex,
                                                targetClicks,
                                                picked,
                                              );
                                            }
                                          },
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
