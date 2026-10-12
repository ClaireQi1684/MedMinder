import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: MedMinder()));
}

class MedMinder extends StatefulWidget {
  const MedMinder({super.key});

  @override
  State<MedMinder> createState() => MedMinderState();
}

class MedMinderState extends State<MedMinder> {
  int currentDayIndex = 0;
  final List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  int checkCounter = 0;

  List<int> pillsPerDay = List.filled(7, 0);

  List<List<int>> pillCheck = List.generate(7, (dayIndex) => []);

  List<int> dayCheck = List.filled(7, 0);

  String get currentDay => days[currentDayIndex];

  @override
  void initState() {
    super.initState();
    addPills();
  }

  void nextDay() {
    setState(() {
      currentDayIndex = currentDayIndex + 1;
    });
  }

  void previousDay() {
    setState(() {
      currentDayIndex = currentDayIndex - 1;
    });
  }

  //temp method before add pill function
  void addPills() {
    for (int i = 0; i < 7; i++) {
      pillsPerDay[i] = i;
      pillCheck[i] = List.filled(pillsPerDay[i], 0);
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
    if (currentDayIndex <= 6) {
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
                  (currentDay == "Monday")
                      ? SizedBox(width: 8)
                      : SizedBox(width: 0),
                  (currentDay != "Monday")
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
                  (currentDay == "Monday")
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
                  (currentDay == "Sunday")
                      ? SizedBox(width: 8)
                      : SizedBox(width: 0),
                  (currentDay != "Sunday")
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
                  (currentDay == "Sunday")
                      ? SizedBox(width: 8)
                      : SizedBox(width: 0),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold();
    }
  }
}
