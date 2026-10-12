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
  int currentIndex = 0;
  final List<String> days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];

  String get currentDay => days[currentIndex];

  void nextDay() {
    setState(() {
      currentIndex = currentIndex + 1;
    });
  }

  void previousDay() {
    setState(() {
      currentIndex = currentIndex - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentIndex <= 6) {
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
              // DAY ONE CARD
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
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(7.0),
                              color: Colors.lime,
                              child: Column(
                                children: [
                                  Center(child: Text("Pill 1")),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        print("pill one completed");
                                      },
                                      style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(145, 145),
                                      ),
                                      child: Center(
                                        child: Text("MARK AS TAKEN"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(7.0),
                              color: Colors.lime,
                              child: Column(
                                children: [
                                  Center(child: Text("Pill 2")),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        print("pill one completed");
                                      },
                                      style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(145, 145),
                                      ),
                                      child: Center(
                                        child: Text("MARK AS TAKEN"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(7.0),
                              color: Colors.lime,
                              child: Column(
                                children: [
                                  Center(child: Text("Pill 3")),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        print("pill one completed");
                                      },
                                      style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(145, 145),
                                      ),
                                      child: Center(
                                        child: Text("MARK AS TAKEN"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(7.0),
                              color: Colors.lime,
                              child: Column(
                                children: [
                                  Center(child: Text("Pill 4")),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        print("pill one completed");
                                      },
                                      style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(145, 145),
                                      ),
                                      child: Center(
                                        child: Text("MARK AS TAKEN"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(7.0),
                              color: Colors.lime,
                              child: Column(
                                children: [
                                  Center(child: Text("Pill 5")),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        print("pill one completed");
                                      },
                                      style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(145, 145),
                                      ),
                                      child: Center(
                                        child: Text("MARK AS TAKEN"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(7.0),
                              color: Colors.lime,
                              child: Column(
                                children: [
                                  Center(child: Text("Pill 6")),
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        print("pill one completed");
                                      },
                                      style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(145, 145),
                                      ),
                                      child: Center(
                                        child: Text("MARK AS TAKEN"),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Image.asset(
                        //   "assets/Sunhyuk.png",
                        //   fit: BoxFit.cover,
                        //   height: 350,
                        //   width: double.infinity,
                        // ),
                        Container(
                          padding: EdgeInsets.only(
                            // top: 8.0,
                            left: 8.0,
                            // right: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  print("Monday marked as done");
                                },
                                child: const Text(
                                  "MARK AS DONE",
                                  style: TextStyle(fontSize: 20),
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(200, 80),
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
