import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 142, 192, 218),
        appBar: AppBar(
          title: const Text("MedMinder"),
          backgroundColor: const Color.fromARGB(255, 84, 115, 141),
        ),
        body: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  //DAY ONE CARD
                  Center(
                    child: Container(
                      height: 300,
                      width: 200,
                      child: Card(
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/Sunhyuk.png",
                              fit: BoxFit.cover,
                            ),
                            Container(
                              padding: EdgeInsets.only(
                                top: 8.0,
                                left: 8.0,
                                right: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Day One",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Add Genshin check-in-type logic here
                                      print("Genshin check-in button pressed");
                                    },
                                    child: Text("MARK AS DONE"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  //DAY TWO CARD
                  Center(
                    child: Container(
                      height: 300,
                      width: 200,
                      child: Card(
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/Sunhyuk.png",
                              fit: BoxFit.cover,
                            ),
                            Container(
                              padding: EdgeInsets.only(
                                top: 8.0,
                                left: 8.0,
                                right: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Day Two",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Add Genshin check-in-type logic here
                                      print("Genshin check-in button pressed");
                                    },
                                    child: Text("MARK AS DONE"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        //DAY THREE CARD
                        Center(
                          child: Container(
                            height: 300,
                            width: 200,
                            child: Card(
                              child: Column(
                                children: [
                                  Image.asset(
                                    "assets/Sunhyuk.png",
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(
                                      top: 8.0,
                                      left: 8.0,
                                      right: 8.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "Day Three",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            // Add Genshin check-in-type logic here
                                            print(
                                              "Genshin check-in button pressed",
                                            );
                                          },
                                          child: Text("MARK AS DONE"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        //DAY FOUR CARD
                        Center(
                          child: Container(
                            height: 300,
                            width: 200,
                            child: Card(
                              child: Column(
                                children: [
                                  Image.asset(
                                    "assets/Sunhyuk.png",
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    padding: EdgeInsets.only(
                                      top: 8.0,
                                      left: 8.0,
                                      right: 8.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "Day Four",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            // Add Genshin check-in-type logic here
                                            print(
                                              "Genshin check-in button pressed",
                                            );
                                          },
                                          child: Text("MARK AS DONE"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

