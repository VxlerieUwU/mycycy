import 'package:ezstudies/search/search_cell_data.dart';
import 'package:ezstudies/utils/database_helper.dart';
import 'package:ezstudies/utils/secret.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/templates.dart';
import '../utils/timestamp_utils.dart';
import 'add.dart';
import 'agenda_cell.dart';
import 'agenda_cell_data.dart';

class Agenda extends StatefulWidget {
  const Agenda(
      {this.agenda = false,
      this.trash = false,
      this.search = false,
      this.data,
      Key? key})
      : super(key: key);
  final bool agenda;
  final bool trash;
  final bool search;
  final SearchCellData? data;

  @override
  State<Agenda> createState() => _AgendaState();
}

class _AgendaState extends State<Agenda> {
  bool initialized = false;
  List<AgendaCellData> list = [];
  final TextStyle menuStyle = const TextStyle(fontSize: 16);

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      initialized = true;
      load();
    }
    list.sort((a, b) => a.start.compareTo(b.start));

    Widget content = Center(
        child: widget.trash
            ? Text(AppLocalizations.of(context)!.nothing_to_show)
            : TextButton(
                onPressed: () => refresh(),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: const Icon(Icons.refresh, size: 16),
                  ),
                  Text(AppLocalizations.of(context)!.refresh)
                ])));

    if (list.isNotEmpty) {
      content = ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: list.length,
        itemBuilder: (context, index) {
          var data = list[index];
          Widget cell = AgendaCell(
              data,
              index == 0 || !isSameDay(data.start, list[index - 1].start),
              index == 0 || !isSameMonth(data.start, list[index - 1].start),
              () => load(),
              !widget.trash,
              widget.agenda);
          return widget.search
              ? cell
              : Dismissible(
                  key: UniqueKey(),
                  onDismissed: (direction) {
                    remove(data);
                  },
                  background: Container(
                      color: widget.agenda ? Colors.red : Colors.green,
                      child: Container(
                          margin: const EdgeInsets.only(left: 20, right: 20),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(widget.agenda
                                    ? Icons.delete
                                    : Icons.restore_from_trash),
                                Icon(widget.agenda
                                    ? Icons.delete
                                    : Icons.restore_from_trash)
                              ]))),
                  child: cell,
                );
        },
      );
    }

    Widget child = widget.trash
        ? content
        : RefreshIndicator(onRefresh: () => refresh(), child: content);
    Widget? menu;
    if (widget.agenda) {
      OpenContainerTemplate add = OpenContainerTemplate(
          Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.extended(
                  onPressed: null,
                  label: Text(AppLocalizations.of(context)!.add),
                  icon: const Icon(Icons.add))),
          Add(),
          () => load());
      child = Stack(
        children: [
          child,
          Container(
            margin: const EdgeInsets.only(right: 20, bottom: 10),
            alignment: Alignment.bottomRight,
            child: add,
          )
        ],
      );

      OpenContainerTemplate trash = OpenContainerTemplate(
          Text(AppLocalizations.of(context)!.trash, style: menuStyle),
          const Agenda(trash: true),
          () => load());

      menu = MenuTemplate(<PopupMenuItem<String>>[
        PopupMenuItem<String>(value: "trash", child: trash),
        PopupMenuItem<String>(
            value: "reset", child: Text(AppLocalizations.of(context)!.reset)),
        PopupMenuItem<String>(
            value: "help", child: Text(AppLocalizations.of(context)!.help))
      ], (value) {
        switch (value) {
          case "trash":
            trash.getTrigger().call();
            break;
          case "reset":
            showDialog(
              context: context,
              builder: (context) => AlertDialogTemplate(
                  AppLocalizations.of(context)!.reset, "reset?", [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel)),
                TextButton(
                    onPressed: () {
                      reset();
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.reset))
              ]),
            );
            break;
          case "help":
            showDialog(
              context: context,
              builder: (context) => AlertDialogTemplate(
                  AppLocalizations.of(context)!.help, "help", [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.ok))
              ]),
            );
            break;
        }
      });
    } else if (widget.trash) {
      menu = MenuTemplate(<PopupMenuItem<String>>[
        PopupMenuItem(
            value: "help", child: Text(AppLocalizations.of(context)!.help))
      ], (value) {
        switch (value) {
          case "help":
            showDialog(
                context: context,
                builder: (context) => AlertDialogTemplate(
                        AppLocalizations.of(context)!.help, "help?", [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppLocalizations.of(context)!.ok))
                    ]));
            break;
        }
      });
    } else if (widget.search) {
      menu = MenuTemplate(<PopupMenuItem<String>>[
        PopupMenuItem<String>(
            value: "help", child: Text(AppLocalizations.of(context)!.help))
      ], (value) {
        switch (value) {
          case "help":
            showDialog(
              context: context,
              builder: (context) => AlertDialogTemplate(
                  AppLocalizations.of(context)!.help, "help", [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.ok))
              ]),
            );
            break;
        }
      });
    }

    String title = "";
    if (widget.agenda) {
      title = AppLocalizations.of(context)!.agenda;
    } else if (widget.trash) {
      title = AppLocalizations.of(context)!.trash;
    } else if (widget.search) {
      title = widget.data!.name;
    }

    return Template(title, child, menu, !widget.agenda);
  }

  void load() {
    if (widget.agenda || widget.trash) {
      int trash = 1;
      if (widget.trash) {
        trash = 0;
      }
      DatabaseHelper database = DatabaseHelper();
      database
          .open()
          .then((value) => database.get(DatabaseHelper.agenda).then((value) {
                setState(() {
                  list = value;
                  list.removeWhere((element) => element.trashed == trash);
                });
                database.close();
              }));
    } else if (widget.search) {
      SecretLoader().load().then((value) {
        String url = value.serverUrl;
        SharedPreferences.getInstance().then((value) {
          String name = value.getString("name") ?? "";
          String password = value.getString("password") ?? "";
          http.post(Uri.parse(url), body: <String, String>{
            "request": "cyu",
            "name": name,
            "password": password,
            "id": widget.data!.id
          }).then((value) {
            print(value.body);
          });
        });
      });
    }
  }

  void remove(AgendaCellData data) {
    if (widget.agenda) {
      data.trashed = 1;
      DatabaseHelper database = DatabaseHelper();
      database.open().then((value) => database
          .insertOrReplace(DatabaseHelper.agenda, data)
          .then((value) => database.close()));
      setState(() => list.remove(data));
    } else if (widget.trash) {
      data.trashed = 0;
      DatabaseHelper database = DatabaseHelper();
      database.open().then((value) => database
          .insertOrReplace(DatabaseHelper.agenda, data)
          .then((value) => database.close()));
      setState(() => list.remove(data));
    }
  }

  void reset() {
    DatabaseHelper database = DatabaseHelper();
    database.open().then((value) => database
        .reset()
        .then((value) => database.close().then((value) => load())));
  }

  Future<void> refresh() async {
    load();
  }
}
