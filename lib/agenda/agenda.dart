import 'dart:convert';

import 'package:mycycy/agenda/agenda_details.dart';
import 'package:mycycy/agenda/agenda_view_model.dart';
import 'package:mycycy/agenda/agenda_week_view.dart';
import 'package:mycycy/search/search_cell_data.dart';
import 'package:mycycy/utils/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';
import 'package:requests/requests.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:stacked/stacked.dart';

import '../utils/notifications.dart';
import '../utils/preferences.dart';
import '../utils/style.dart';
import '../utils/templates.dart';
import '../utils/timestamp_utils.dart';
import 'agenda_cell.dart';
import 'agenda_cell_data.dart';

class Agenda extends StatefulWidget {
  const Agenda(
      {this.agenda = false,
      this.trash = false,
      this.search = false,
      this.data,
      this.onClosed,
      this.agendaViewModel,
      Key? key})
      : super(key: key);
  final bool agenda;
  final bool trash;
  final bool search;
  final SearchCellData? data;
  final Function? onClosed;
  final AgendaViewModel? agendaViewModel;

  @override
  State<Agenda> createState() => _AgendaState();
}

class _AgendaState extends State<Agenda> {
  List<AgendaCellData> list = [];
  ItemScrollController itemScrollController = ItemScrollController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    list.sort((a, b) => a.start.compareTo(b.start));

    Widget menu = MenuTemplate(
        items: [
          if (widget.agenda || widget.search)
            PopupMenuItem<String>(
                value: "week_view",
                child: Text(AppLocalizations.of(context)!.week_view,
                    style: TextStyle(color: Style.text))),
          if (widget.agenda && !kIsWeb)
            PopupMenuItem<String>(
                value: "trash",
                child: Text(AppLocalizations.of(context)!.trash,
                    style: TextStyle(color: Style.text))),
          if (widget.agenda && !kIsWeb)
            PopupMenuItem<String>(
                value: "reset",
                child: Text(AppLocalizations.of(context)!.reset,
                    style: TextStyle(color: Style.text))),
          if (widget.agenda)
            PopupMenuItem<String>(
                value: "help_agenda",
                child: Text(AppLocalizations.of(context)!.help,
                    style: TextStyle(color: Style.text))),
          if (widget.trash)
            PopupMenuItem(
                value: "help_trash",
                child: Text(AppLocalizations.of(context)!.help,
                    style: TextStyle(color: Style.text))),
          if (widget.search)
            PopupMenuItem<String>(
                value: "help_search",
                child: Text(AppLocalizations.of(context)!.help,
                    style: TextStyle(color: Style.text)))
        ],
        onSelected: (value) {
          switch (value) {
            case "help_agenda":
              showDialog(
                context: context,
                builder: (context) => AlertDialogTemplate(
                    title: AppLocalizations.of(context)!.help,
                    content: AppLocalizations.of(context)!.help_agenda,
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppLocalizations.of(context)!.ok,
                              style: TextStyle(color: Style.primary))),
                    ]),
              );
              break;
            case "trash":
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          Agenda(trash: true, onClosed: () => load())));
              break;
            case "week_view":
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AgendaWeekView(data: list)));
              break;
            case "reset":
              showDialog(
                context: context,
                builder: (context) => AlertDialogTemplate(
                    title: AppLocalizations.of(context)!.reset,
                    content: AppLocalizations.of(context)!.reset_desc,
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppLocalizations.of(context)!.cancel,
                              style: TextStyle(color: Style.primary))),
                      TextButton(
                          onPressed: () {
                            reset();
                            Navigator.pop(context);
                          },
                          child: Text(AppLocalizations.of(context)!.reset,
                              style: TextStyle(color: Style.primary)))
                    ]),
              );
              break;
            case "help_trash":
              showDialog(
                  context: context,
                  builder: (context) => AlertDialogTemplate(
                          title: AppLocalizations.of(context)!.help,
                          content: AppLocalizations.of(context)!.help_trash,
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(AppLocalizations.of(context)!.ok,
                                    style: TextStyle(color: Style.primary)))
                          ]));
              break;
            case "help_search":
              showDialog(
                context: context,
                builder: (context) => AlertDialogTemplate(
                    title: AppLocalizations.of(context)!.help,
                    content: AppLocalizations.of(context)!.help_search_agenda,
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(AppLocalizations.of(context)!.ok,
                              style: TextStyle(color: Style.primary))),
                    ]),
              );
              break;
          }
        });

    Widget content = list.isEmpty
        ? Center(
            child: widget.trash
                ? Text(AppLocalizations.of(context)!.nothing_to_show)
                : TextButton(
                    onPressed: () => refresh(),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 10),
                            child: const Icon(Icons.refresh, size: 16),
                          ),
                          Text(AppLocalizations.of(context)!.refresh)
                        ])))
        : ScrollablePositionedList.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemScrollController: itemScrollController,
            scrollDirection: Axis.vertical,
            itemCount: list.length,
            itemBuilder: (context, index) {
              var data = list[index];
              Widget cell = AgendaCell(
                  data: data,
                  firstOfDay: index == 0 ||
                      !isSameDay(data.start, list[index - 1].start),
                  firstOfMonth: index == 0 ||
                      !isSameMonth(data.start, list[index - 1].start),
                  onClosed: () {
                    if (widget.agenda) {
                      load(showLoading: false);
                    }
                  },
                  editable: widget.agenda,
                  search: widget.search);
              return widget.search || kIsWeb
                  ? cell
                  : Dismissible(
                      key: UniqueKey(),
                      onDismissed: (direction) {
                        remove(data);
                      },
                      background: Container(
                          color: widget.agenda ? Colors.red : Colors.green,
                          child: Container(
                              margin:
                                  const EdgeInsets.only(left: 20, right: 20),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(
                                        widget.agenda
                                            ? Icons.delete
                                            : Icons.restore_from_trash,
                                        color: Style.text),
                                    Icon(
                                        widget.agenda
                                            ? Icons.delete
                                            : Icons.restore_from_trash,
                                        color: Style.text)
                                  ]))),
                      child: cell,
                    );
            },
          );

    Widget child = Stack(children: [
      widget.trash
          ? content
          : RefreshIndicator(
              onRefresh: () => refresh(),
              backgroundColor: Style.background,
              child: content),
      Positioned(
          bottom: 20,
          right: 20,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (!kIsWeb && widget.agenda)
              OpenContainerTemplate(
                  child1: FloatingActionButton.extended(
                      heroTag: "add",
                      elevation: 0,
                      onPressed: null,
                      backgroundColor: Colors.transparent,
                      label: Text(AppLocalizations.of(context)!.add,
                          style: TextStyle(color: Style.text)),
                      icon: Icon(Icons.add, color: Style.text)),
                  child2: const AgendaDetails(add: true),
                  onClosed: () => load(),
                  radius: const BorderRadius.all(Radius.circular(24)),
                  elevation: 6,
                  color: Style.primary.withOpacity(0.75)),
            if (list.isNotEmpty)
              Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: FloatingActionButton.extended(
                      onPressed: () => scrollToToday(),
                      backgroundColor: Style.primary.withOpacity(0.75),
                      label: Text(AppLocalizations.of(context)!.scroll_to_today,
                          style: TextStyle(color: Style.text)),
                      icon: Icon(Icons.today, color: Style.text)))
          ])),
      if (loading)
        Container(
            color: Style.background.withOpacity(0.5),
            alignment: Alignment.center,
            child: const CircularProgressIndicator())
    ]);

    if (widget.agenda &&
        !(Preferences.sharedPreferences.getBool(Preferences.helpAgenda) ??
            false)) {
      Preferences.sharedPreferences.setBool(Preferences.helpAgenda, true).then(
          (value) => showDialog(
              context: context,
              builder: (context) => AlertDialogTemplate(
                      title: AppLocalizations.of(context)!.help,
                      content: AppLocalizations.of(context)!.help_agenda,
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocalizations.of(context)!.ok,
                                style: TextStyle(color: Style.primary)))
                      ])));
    } else if (widget.trash &&
        !(Preferences.sharedPreferences.getBool(Preferences.helpTrash) ??
            false)) {
      Preferences.sharedPreferences.setBool(Preferences.helpTrash, true).then(
          (value) => showDialog(
              context: context,
              builder: (context) => AlertDialogTemplate(
                      title: AppLocalizations.of(context)!.help,
                      content: AppLocalizations.of(context)!.help_trash,
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocalizations.of(context)!.ok,
                                style: TextStyle(color: Style.primary)))
                      ])));
    } else if (widget.search &&
        !(Preferences.sharedPreferences.getBool(Preferences.helpSearchAgenda) ??
            false)) {
      Preferences.sharedPreferences
          .setBool(Preferences.helpSearchAgenda, true)
          .then((value) => showDialog(
              context: context,
              builder: (context) => AlertDialogTemplate(
                      title: AppLocalizations.of(context)!.help,
                      content: AppLocalizations.of(context)!.help_search_agenda,
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocalizations.of(context)!.ok,
                                style: TextStyle(color: Style.primary)))
                      ])));
    }

    String title = "";
    if (widget.agenda) {
      title = AppLocalizations.of(context)!.agenda;
    } else if (widget.trash) {
      title = AppLocalizations.of(context)!.trash;
    } else if (widget.search) {
      title = widget.data!.name;
    }
    Template template =
        Template(title: title, menu: menu, back: !widget.agenda, child: child);
    return widget.agenda
        ? ViewModelBuilder<AgendaViewModel>.nonReactive(
            disposeViewModel: false,
            viewModelBuilder: () => widget.agendaViewModel!,
            builder: (context, model, child) => template)
        : template;
  }

  @override
  void setState(VoidCallback fn, {bool scroll = false}) {
    if (mounted) {
      super.setState(fn);
      if (scroll) {
        Future.delayed(const Duration(milliseconds: 300))
            .then((value) => scrollToToday());
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.onClosed != null) {
      Future.delayed(const Duration(), () => widget.onClosed!());
    }
  }

  void scrollToToday() {
    if (list.isNotEmpty) {
      int now = DateTime.now().millisecondsSinceEpoch;
      int index = 0;
      if (now > list[0].start) {
        while (index < list.length &&
            !(isSameDay(list[index].start, now) || list[index].start >= now)) {
          index++;
        }
      }
      if (itemScrollController.isAttached) {
        itemScrollController.scrollTo(
            index: index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
      }
    }
  }

  Future<void> load(
      {bool scroll = false, bool showLoading = true, bool force = true}) async {
    if (showLoading) {
      setState(() => loading = true);
    }
    if (widget.agenda) {
      if (widget.agendaViewModel!.initialized && !force) {
        setState(() {
          list = widget.agendaViewModel!.list;
          loading = false;
        }, scroll: scroll);
      } else {
        var response = await Requests.post("https://services-web.cyu.fr/calendar/Home/GetCalendarData",
            body: {
              'start': DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 15))),
              'end': DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 15))),
              'resType': '104',
              'calView': 'listWeek',
              'federationIds[]': Preferences.sharedPreferences.getString(Preferences.id)
            },
            bodyEncoding: RequestBodyEncoding.FormURLEncoded);
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          if (kIsWeb) {
            setState(() {
              list = processJson(response.body);
              widget.agendaViewModel!.list = list;
              widget.agendaViewModel!.initialized = true;
              loading = false;
            }, scroll: scroll);
          } else {
            DatabaseHelper database = DatabaseHelper();
            await database.open();
            await database.insertAll(processJson(response.body));
            list = await database.getAgenda(DatabaseHelper.agenda);
            await database.close();
            setState(() {
              scheduleNotifications();
              list.removeWhere((element) => element.trashed == 1);
              widget.agendaViewModel!.list = list;
              widget.agendaViewModel!.initialized = true;
              loading = false;
            }, scroll: scroll);
          }
        } else {
          DatabaseHelper database = DatabaseHelper();
          await database.open();
          list = await database.getAgenda(DatabaseHelper.agenda);
          await database.close();
          setState(() {
            list.removeWhere((element) => element.trashed == 1);
            widget.agendaViewModel!.list = list;
            widget.agendaViewModel!.initialized = true;
            loading = false;
          }, scroll: scroll);
          showDialog(
            context: context,
            builder: (context) => AlertDialogTemplate(
                title: AppLocalizations.of(context)!.error,
                content: AppLocalizations.of(context)!.error_internet,
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.ok))
                ]),
          );
        }
      }
    } else if (widget.trash) {
      DatabaseHelper database = DatabaseHelper();
      await database.open();
      list = await database.getAgenda(DatabaseHelper.agenda);
      await database.close();
      setState(() {
        list.removeWhere((element) => element.trashed == 0);
        loading = false;
      }, scroll: scroll);
    } else if (widget.search) {


      var response = await Requests.post("https://services-web.cyu.fr/calendar/Home/GetCalendarData",
          body: {
            'start': DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(Duration(days: 15))),
            'end': DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 15))),
            'resType': '104',
            'calView': 'listWeek',
            'federationIds[]': widget.data!.id
          },
          bodyEncoding: RequestBodyEncoding.FormURLEncoded);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        setState(() {
          list = processJson(response.body);
          loading = false;
        }, scroll: scroll);
      } else {
        setState(() => loading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialogTemplate(
              title: AppLocalizations.of(context)!.error,
              content: AppLocalizations.of(context)!.error_internet,
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.ok))
              ]),
        );
      }
    }
  }

  Future<void> remove(AgendaCellData data) async {
    if (widget.agenda) {
      data.trashed = 1;
      DatabaseHelper database = DatabaseHelper();
      await database.open();
      await database.insertOrReplaceAgenda(DatabaseHelper.agenda, data);
      await database.close();
      setState(() {
        scheduleNotifications();
        list.remove(data);
      });
    } else if (widget.trash) {
      data.trashed = 0;
      DatabaseHelper database = DatabaseHelper();
      await database.open();
      await database.insertOrReplaceAgenda(DatabaseHelper.agenda, data);
      await database.close();
      setState(() => list.remove(data));
    }
  }

  Future<void> reset() async {
    DatabaseHelper database = DatabaseHelper();
    await database.open();
    await database.reset();
    await database.close();
    load();
  }

  void scheduleNotifications() {
    if (Preferences.sharedPreferences.getBool(Preferences.notifications) ??
        true) {
      Notifications.cancelNotificationsAgenda()
          .then((_) => Notifications.scheduleNotificationsAgenda(context));
    }
  }

  List<AgendaCellData> processJson(String json) {
    List<AgendaCellData> list = [];
    if (json.isNotEmpty) {
      List<dynamic> data = jsonDecode(json);
      for (int i = 0; i < data.length; i++) {
        try {
          var item = data[i];
          List<String> start = item["start"].toString().split("T");
          List<int> startDate =
              start[0].split("-").map((element) => int.parse(element)).toList();
          List<int> startTime =
              start[1].split(":").map((element) => int.parse(element)).toList();
          DateTime startDateTime = DateTime(startDate[0], startDate[1],
              startDate[2], startTime[0], startTime[1], startTime[2], 0, 0);
          int startTimestamp = startDateTime.millisecondsSinceEpoch;
          int endTimestamp = 0;
          if (item["end"].toString() != "null") {
            List<String> end = item["end"].toString().split("T");
            List<int> endDate =
                end[0].split("-").map((element) => int.parse(element)).toList();
            List<int> endTime =
                end[1].split(":").map((element) => int.parse(element)).toList();
            endTimestamp = DateTime(endDate[0], endDate[1], endDate[2],
                    endTime[0], endTime[1], endTime[2], 0, 0)
                .millisecondsSinceEpoch;
          } else {
            endTimestamp = startDateTime
                .add(Duration(hours: 21 - startTime[0]))
                .millisecondsSinceEpoch;
          }

          String description = item["description"]
              .toString()
              .replaceAll("\n", "")
              .replaceAll("\r", "")
              .replaceAll("<br />", "\n");
          description = HtmlUnescape().convert(description);
          list.add(AgendaCellData(
              id: item["id"],
              description: description,
              start: startTimestamp,
              end: endTimestamp,
              added: 0,
              trashed: 0,
              edited: 0));
        } catch (_) {}
      }
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    load(scroll: true, force: false);
  }

  Future<void> refresh() async {
    await load();
  }
}
