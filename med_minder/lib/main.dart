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
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DAY ONE CARD
              Center(
                child: Container(
                  height: 300,
                  width: 200,
                  margin: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/Sunhyuk.png",
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            left: 8.0,
                            right: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
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
                                  print("Day One marked as done");
                                },
                                child: const Text("MARK AS DONE"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // DAY TWO CARD
              Center(
                child: Container(
                  height: 300,
                  width: 200,
                  margin: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/Sunhyuk.png",
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            left: 8.0,
                            right: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
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
                                  print("Day Two marked as done");
                                },
                                child: const Text("MARK AS DONE"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // DAY THREE CARD
              Center(
                child: Container(
                  height: 300,
                  width: 200,
                  margin: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/Sunhyuk.png",
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            left: 8.0,
                            right: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
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
                                  print("Day Three marked as done");
                                },
                                child: const Text("MARK AS DONE"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // DAY FOUR CARD
              Center(
                child: Container(
                  height: 300,
                  width: 200,
                  margin: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/Sunhyuk.png",
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            left: 8.0,
                            right: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
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
                                  print("Day Four marked as done");
                                },
                                child: const Text("MARK AS DONE"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // DAY FIVE CARD
              Center(
                child: Container(
                  height: 300,
                  width: 200,
                  margin: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/Sunhyuk.png",
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            left: 8.0,
                            right: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    "Day Five",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  print("Day Five marked as done");
                                },
                                child: const Text("MARK AS DONE"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // DAY SIX CARD
              Center(
                child: Container(
                  height: 300,
                  width: 200,
                  margin: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/Sunhyuk.png",
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            left: 8.0,
                            right: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    "Day Six",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  print("Day Six marked as done");
                                },
                                child: const Text("MARK AS DONE"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // DAY SEVEN CARD
              Center(
                child: Container(
                  height: 300,
                  width: 200,
                  margin: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/Sunhyuk.png",
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                            left: 8.0,
                            right: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    "Day Seven",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  print("Day Seven marked as done");
                                },
                                child: const Text("MARK AS DONE"),
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
      ),
    ),
  );
}
