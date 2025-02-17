import 'package:animations/animations.dart';
import 'package:mycycy/utils/style.dart';
import 'package:mycycy/utils/timestamp_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:ms_undraw/ms_undraw.dart';

class Template extends StatelessWidget {
  const Template(
      {required this.title,
      required this.child,
      this.menu,
      this.back = false,
      this.compact = false,
      Key? key})
      : super(key: key);
  final String title;
  final Widget child;
  final Widget? menu;
  final bool back;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    IconButton? iconButton;
    if (back) {
      iconButton = IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: Style.text,
        ),
        onPressed: () => Navigator.pop(context),
      );
    }
    return Scaffold(
        backgroundColor: Style.background,
        appBar: AppBar(
          title: compact
              ? Text(title, style: TextStyle(color: Style.text))
              : Container(),
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  (Style.theme == 0) ? Brightness.dark : Brightness.light,
              statusBarBrightness:
                  (Style.theme == 0) ? Brightness.light : Brightness.dark),
          actions: (menu == null) ? null : [menu!],
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: iconButton,
        ),
        body: Column(
          children: [
            if (!compact)
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(left: 20, bottom: 20),
                child: Text(
                  title,
                  style: TextStyle(fontSize: 28, color: Style.text),
                ),
              ),
            Expanded(
              child: child,
            )
          ],
        ));
  }
}

class MenuTemplate extends StatelessWidget {
  const MenuTemplate({required this.items, this.onSelected, Key? key})
      : super(key: key);
  final List<PopupMenuItem<String>> items;
  final Function(String)? onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: Style.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16))),
      icon: Icon(Icons.more_vert_rounded, color: Style.text),
      itemBuilder: (BuildContext context) {
        return items;
      },
      onSelected: (value) {
        if (onSelected != null) {
          onSelected!(value);
        }
      },
    );
  }
}

class OpenContainerTemplate extends StatelessWidget {
  const OpenContainerTemplate(
      {required this.child1,
      required this.child2,
      this.onClosed,
      this.color,
      this.radius = BorderRadius.zero,
      this.elevation = 0,
      Key? key})
      : super(key: key);
  final Widget child1;
  final Widget child2;
  final Function? onClosed;
  final Color? color;
  final BorderRadiusGeometry radius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedShape: RoundedRectangleBorder(borderRadius: radius),
      closedColor: (color == null) ? Style.background : color!,
      openColor: Style.background,
      closedElevation: elevation,
      transitionType: ContainerTransitionType.fadeThrough,
      closedBuilder: (context, action) => child1,
      openBuilder: (context, action) => child2,
      onClosed: (_) {
        if (onClosed != null) {
          onClosed!();
        }
      },
    );
  }
}

class AlertDialogTemplate extends StatelessWidget {
  const AlertDialogTemplate(
      {required this.title, required this.content, this.actions, Key? key})
      : super(key: key);
  final String title;
  final String content;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(title), content: Text(content), actions: actions);
  }
}

class TextFormFieldTemplate extends StatefulWidget {
  const TextFormFieldTemplate(
      {required this.label,
      required this.icon,
      this.enabled = true,
      this.initialValue,
      this.onChanged,
      this.onTapped,
      this.date = false,
      this.time = false,
      this.dateTime,
      this.hidden = false,
      this.multiline = false,
      Key? key})
      : super(key: key);
  final String label;
  final IconData icon;
  final String? initialValue;
  final bool enabled;
  final Function(String)? onChanged;
  final Function(int)? onTapped;
  final bool date;
  final bool time;
  final DateTime? dateTime;
  final bool hidden;
  final bool multiline;

  @override
  State<TextFormFieldTemplate> createState() => _TextFormFieldTemplateState();
}

class _TextFormFieldTemplateState extends State<TextFormFieldTemplate> {
  late DateTime dateTime = widget.dateTime!;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      minLines: 1,
      maxLines: widget.multiline ? null : 1,
      keyboardType: widget.multiline ? TextInputType.multiline : null,
      obscureText: widget.hidden,
      enabled: widget.enabled,
      readOnly: widget.date || widget.time,
      cursorColor: Style.primary,
      style: TextStyle(color: Style.text),
      decoration: InputDecoration(
        filled: true,
        fillColor: Style.secondary,
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.transparent)),
        enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.transparent)),
        disabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.transparent)),
        hintText: widget.label.toLowerCase(),
        hintStyle: TextStyle(color: Style.hint),
        label: Text(widget.label, style: TextStyle(color: Style.hint)),
        icon: Icon(widget.icon, color: Style.text),
      ),
      controller: TextEditingController(
          text: !(widget.date || widget.time)
              ? widget.initialValue
              : DateFormat(
                      widget.time ? "HH:mm" : "EEEE, d MMMM y", getLocale())
                  .format(dateTime)),
      onChanged: (value) {
        if (widget.onChanged != null && !(widget.date && widget.time)) {
          widget.onChanged!(value);
        }
      },
      onTap: () {
        if (widget.time) {
          showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(dateTime))
              .then((value) {
            if (value != null) {
              setState(() {
                dateTime = DateTime(dateTime.year, dateTime.month, dateTime.day,
                    value.hour, value.minute, 0, 0, 0);
              });
              if (widget.onTapped != null) {
                widget.onTapped!(dateTime.millisecondsSinceEpoch);
              }
            }
          });
        } else if (widget.date) {
          showDatePicker(
                  context: context,
                  initialDate: dateTime,
                  lastDate: dateTime.add(const Duration(days: 30)),
                  firstDate: dateTime.subtract(const Duration(days: 30)))
              .then((value) {
            if (value != null) {
              setState(() {
                dateTime = DateTime(value.year, value.month, value.day,
                    dateTime.hour, dateTime.minute, 0, 0, 0);
              });
              if (widget.onTapped != null) {
                widget.onTapped!(dateTime.millisecondsSinceEpoch);
              }
            }
          });
        }
      },
    );
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

class WelcomePageTemplate extends StatelessWidget {
  const WelcomePageTemplate(
      {required this.content, required this.illustration, Key? key})
      : super(key: key);
  final Widget content;
  final UnDrawIllustration illustration;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height * 0.3;
    return SingleChildScrollView(
        reverse: true,
        scrollDirection: Axis.vertical,
        child: Container(
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
          alignment: Alignment.topCenter,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                margin: const EdgeInsets.only(bottom: 20),
                height: height,
                child: UnDraw(
                  color: Style.primary,
                  illustration: illustration,
                  height: height,
                )),
            content
          ]),
        ));
  }
}
