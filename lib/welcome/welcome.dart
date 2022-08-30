import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../utils/cipher.dart';
import '../utils/preferences.dart';
import '../utils/secret.dart';
import '../utils/style.dart';
import '../utils/templates.dart';

class Welcome extends StatefulWidget {
  const Welcome({Key? key}) : super(key: key);

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  int selectedIndex = 0;
  final PageController pageController = PageController(initialPage: 0);
  final Duration animationDuration = const Duration(milliseconds: 300);
  final Curve animationCurve = Curves.easeInOut;
  String name = "";
  String password = "";

  @override
  Widget build(BuildContext context) {
    Widget page1 = Center(
      child: Text("welcome+illu", style: TextStyle(color: Style.text)),
    );
    Widget page2 = Center(
      child: Text("features+illu", style: TextStyle(color: Style.text)),
    );
    Widget page3 = Container(
        margin: const EdgeInsets.only(left: 20, right: 20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextFormFieldTemplate(
              AppLocalizations.of(context)!.name, Icons.person,
              onChanged: (value) => name = value),
          TextFormFieldTemplate(
              AppLocalizations.of(context)!.password, Icons.password,
              onChanged: (value) => password = value, hidden: true)
        ]));
    List<Widget> pages = [page1, page2, page3];

    Widget child = Stack(children: [
      PageView(
        onPageChanged: (value) {
          name = "";
          password = "";
          setState(() => selectedIndex = value);
        },
        controller: pageController,
        children: buildPages(pages),
      ),
      Container(
          alignment: Alignment.bottomCenter,
          margin: const EdgeInsets.only(bottom: 20),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: buildDots(pages.length)))
    ]);

    return Template(AppLocalizations.of(context)!.welcome, child, back: false);
  }

  void next() {
    pageController.nextPage(duration: animationDuration, curve: animationCurve);
  }

  void previous() {
    pageController.previousPage(
        duration: animationDuration, curve: animationCurve);
  }

  void start() {
    if (name.isEmpty || password.isEmpty) {
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialogTemplate(AppLocalizations.of(context)!.error, "empty", [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.ok,
                  style: TextStyle(color: Style.primary)))
        ]),
      );
    } else {
      String encryptedName = encrypt(name, Secret.cipherKey);
      String encryptedPassword = encrypt(password, Secret.cipherKey);
      http.post(Uri.parse(Secret.serverUrl), body: <String, String>{
        "request": "cyu",
        "name": encryptedName,
        "password": encryptedPassword
      }).then((value) {
        if (value.statusCode == 200 && value.body.isNotEmpty) {
          Preferences.sharedPreferences.setString("name", encryptedName).then(
              (value) => Preferences.sharedPreferences
                  .setString("password", encryptedPassword)
                  .then((value) => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => Main(reloadTheme: () {})))));
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialogTemplate(
                AppLocalizations.of(context)!.error, "wrong", [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.ok))
            ]),
          );
        }
      });
    }
  }

  List<Widget> buildPages(List<Widget> widgets) {
    List<Widget> pages = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      List<Widget> children = [widgets[i]];
      if (i == 0 && widgets.length == 1) {
        children.add(WelcomeFABTemplate(begin: true, onPressed: () => start()));
      } else if (i == 0) {
        children.add(WelcomeFABTemplate(next: true, onPressed: () => next()));
      } else if (i == widgets.length - 1) {
        children.add(WelcomeFABTemplate(begin: true, onPressed: () => start()));
        children.add(
            WelcomeFABTemplate(previous: true, onPressed: () => previous()));
      } else {
        children.add(WelcomeFABTemplate(next: true, onPressed: () => next()));
        children.add(
            WelcomeFABTemplate(previous: true, onPressed: () => previous()));
      }
      pages.add(Stack(children: children));
    }
    return pages;
  }

  List<Widget> buildDots(int pageCount) {
    List<Widget> dots = <Widget>[];
    for (int i = 0; i < pageCount; i++) {
      dots.add(GestureDetector(
          child: Icon(
              (selectedIndex == i) ? Icons.circle : Icons.circle_outlined,
              size: 10,
              color: Style.text),
          onTap: () => pageController.animateToPage(i,
              duration: animationDuration, curve: animationCurve)));
    }
    return dots;
  }
}

class WelcomeFABTemplate extends StatelessWidget {
  const WelcomeFABTemplate(
      {this.next = false,
      this.previous = false,
      this.begin = false,
      required this.onPressed,
      Key? key})
      : super(key: key);
  final bool next;
  final bool previous;
  final bool begin;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    String label = AppLocalizations.of(context)!.next;
    IconData icon = Icons.arrow_forward;
    if (previous) {
      label = AppLocalizations.of(context)!.previous;
      icon = Icons.arrow_back;
    } else if (begin) {
      label = AppLocalizations.of(context)!.begin;
      icon = Icons.start;
    }

    return Positioned(
      bottom: 20,
      right: (next || begin) ? 20 : null,
      left: (next || begin) ? null : 20,
      child: FloatingActionButton.extended(
          heroTag: (begin) ? "add" : null,
          backgroundColor: Style.primary,
          onPressed: () => onPressed(),
          label: Text(label, style: TextStyle(color: Style.text)),
          icon: Icon(icon, color: Style.text)),
    );
  }
}
