import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Hell")),
        body: Center(
          child: Container(
            width: 300,
            height: 413.7,
            child: Card(
              color: const Color.fromARGB(255, 188, 173, 57),
              shadowColor: const Color.fromARGB(255, 255, 0, 170),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("assets/sunhyuk.png", fit: BoxFit.scaleDown),
                  Container(
                    width: 300,
                    color: Colors.white,
                    child: Column(
                      children: [
                        Center(child: Text("Raspberry Sunhyuk       \$1200")),
                        Text("Raspberries, milk, coconut oil, flour"),
                        Text("eggs, lemon juice, syrup"),
                        Center(
                          child: ElevatedButton(
                            child: Text("ADD TO CART"),
                            onPressed: () {
                              print("added raspberry sunhyuk to cart");
                            },
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
      ),
    ),
  );
}
