import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void snackBarMessage(BuildContext context, String message) {
  Scaffold.of(context).removeCurrentSnackBar();
  Scaffold.of(context).showSnackBar(SnackBar(
    content: Text(message),
  ));
}

void setColor(Color color, BuildContext context, String selectedDevice) async {
  try {
    var res = await http.post("http://$selectedDevice/colour", body: {
      "r": color.red.toString(),
      "g": color.green.toString(),
      "b": color.blue.toString()
    });
    if (res.statusCode != 200) {
      snackBarMessage(context, "Device Error setting color");
    }
  } on SocketException {
    snackBarMessage(context, "Connection Error");
  }
}

// POWER-WIDGET BEGINN

class PowerSwitch extends StatefulWidget {
  final String selectedDevice;
  PowerSwitch({this.selectedDevice});

  @override
  _PowerSwitchState createState() => _PowerSwitchState();
}

class _PowerSwitchState extends State<PowerSwitch> {
  Color currentColor = Colors.white;

  @override
  void initState() {
    super.initState();
  }

  Future<void> getLastColor() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("lastColor${widget.selectedDevice}")) {
      int lastColor = prefs.getInt("lastColor${widget.selectedDevice}");
      setState(() {
        currentColor = Color(lastColor);
      });
    }
  }

  void turnDeviceOn() async {
    await getLastColor();
    setColor(currentColor, context, widget.selectedDevice);
    snackBarMessage(context, "Turned on ${widget.selectedDevice}");
  }

  void turnDeviceOff() async {
    try {
      var res = await http.post("http://${widget.selectedDevice}/colour",
          body: {"r": "0", "g": "0", "b": "0"});
      if (res.statusCode == 200) {
        snackBarMessage(context, "Turned off ${widget.selectedDevice}");
      } else {
        snackBarMessage(context, "Device Error");
      }
    } on SocketException {
      snackBarMessage(context, "Connection Error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      color: Colors.deepOrangeAccent,
      title: "Power",
      onTab: null,
      actions: [
        FlatButton(
          color: Colors.black,
          child: Text(
            "Turn on",
            style: TextStyle(color: Colors.green),
          ),
          onPressed: () => turnDeviceOn(),
        ),
        SizedBox(
          width: 10,
        ),
        FlatButton(
          color: Colors.black,
          child: Text(
            "Turn off",
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () => turnDeviceOff(),
        ),
      ],
    );
  }
}

// POWER-WIDGET END

// COLOR-PICKER-WIDGET BEGINN

class ColorChanger extends StatefulWidget {
  final String selectedDevice;
  final Color color;
  ColorChanger({this.color, this.selectedDevice});

  @override
  _ColorChangerState createState() => _ColorChangerState();
}

class _ColorChangerState extends State<ColorChanger> {
  Color currentColor = Colors.white;
  bool firstUserInteraction;

  @override
  void initState() {
    firstUserInteraction = false;
    super.initState();
  }

  Future<void> getLastColor() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("lastColor${widget.selectedDevice}")) {
      int lastColor = prefs.getInt("lastColor${widget.selectedDevice}");
      setState(() {
        currentColor = Color(lastColor);
      });
    }
  }

  Icon getColorIcon() {
    if (!firstUserInteraction || firstUserInteraction == null) {
      getLastColor();
    }
    return Icon(Icons.bubble_chart, color: currentColor);
  }

  void setLastColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("lastColor${widget.selectedDevice}", color.value);
  }

  void changecolor(Color color) {
    setState(() => currentColor = color);
    // performance-issues
    // setColor(color);
  }

  void colorPicker() {
    showDialog(
        context: context,
        child: AlertDialog(
          content: SingleChildScrollView(
              child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: changecolor,
            enableAlpha: false,
          )),
          actions: [
            FlatButton(
                child: Text(
                  "set color",
                  style: TextStyle(color: Colors.amber),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  setLastColor(currentColor);
                  setColor(currentColor, context, widget.selectedDevice);
                })
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    // Shuold use a FutureBuilder
    return BaseCard(
      onTab: () {
        colorPicker();
        firstUserInteraction = true;
      },
      onDoubleTap: () => setColor(currentColor, context, widget.selectedDevice),
      color: widget.color,
      title: "Color",
      actions: [getColorIcon()],
    );
  }
}

// COLOR-PICKER-WIDGET END

// BETTER-BANNER BEGINN

class BetterBanner extends StatelessWidget {
  final backgroundColor;
  final title;
  final List<Widget> actions;
  final TextStyle titleTextStyle;
  BetterBanner(
      {this.backgroundColor, this.title, this.actions, this.titleTextStyle});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: titleTextStyle,
          ),
          Row(
            children: actions,
          )
        ],
      ),
    );
  }
}

// BETTER-BANNER END

// BASE-CARD BEGINN

class BaseCard extends StatelessWidget {
  final Color color;
  final String title;
  final List<Widget> actions;
  final Function onTab;
  final Function onDoubleTap;
  BaseCard(
      {this.color, this.title, this.actions, this.onTab, this.onDoubleTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onDoubleTap: onDoubleTap == null ? null : onDoubleTap,
            onTap: onTab == null ? null : onTab,
            child: Card(
              elevation: 0,
              color: color,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(23, 15, 15, 15),
                child: BetterBanner(
                  backgroundColor: Colors.transparent,
                  titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                  title: title,
                  actions: actions,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// BASE-CARD END

// MODE-PICKER-WIDGET BEGINN

class ModeButton extends StatelessWidget {
  final String mode;
  final Function modeFunction;
  final Color modeColor;

  ModeButton({this.mode, this.modeColor, this.modeFunction});

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: Text(mode, style: TextStyle(color: Colors.white)),
      onPressed: () => modeFunction(int.parse(mode)),
      color: modeColor,
    );
  }
}

class ModePicker extends StatefulWidget {
  final String selectedDevice;
  ModePicker({this.selectedDevice});

  @override
  _ModePickerState createState() => _ModePickerState();
}

class _ModePickerState extends State<ModePicker> {
  Color activeModeColor = Colors.indigoAccent;
  Color inactiveModeColor = Colors.indigo;

  List<Color> buttonColor;

  void setMode(int mode) async {
    try {
      var res = await http.post("http://${widget.selectedDevice}/effect",
          body: {"effect": mode.toString()});
      if (res.statusCode != 200) {
        snackBarMessage(context, "Device Error setting mode");
      }
    } on SocketException {
      snackBarMessage(context, "Connection Error");
    } on http.ClientException {
      snackBarMessage(context, "Device Error");
    }
  }

  void selectMode(int buttonIndex) {
    if (buttonColor == null) {
      return;
    }
    if (buttonColor[buttonIndex] == activeModeColor) {
      setMode(0);
      setState(() {
        buttonColor[buttonIndex] = inactiveModeColor;
      });
    } else {
      setMode(buttonIndex);
      List<Color> newButtonColor = List.filled(4, inactiveModeColor);
      newButtonColor[buttonIndex] = activeModeColor;
      setState(() {
        buttonColor = newButtonColor;
      });
    }
  }

  void initState() {
    super.initState();
    buttonColor = List.filled(4, inactiveModeColor);
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      color: Colors.indigo,
      title: "Mode",
      onTab: null,
      actions: [
        Row(
          children: [
            ModeButton(
              mode: "1",
              modeFunction: selectMode,
              modeColor: buttonColor[1],
            ),
            ModeButton(
              mode: "2",
              modeFunction: selectMode,
              modeColor: buttonColor[2],
            ),
            ModeButton(
              mode: "3",
              modeFunction: selectMode,
              modeColor: buttonColor[3],
            ),
          ],
        )
      ],
    );
  }
}

// MODE-PICKER-WIDGET END
