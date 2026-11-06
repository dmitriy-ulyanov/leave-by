import 'package:flutter/widgets.dart';

const double wideBreakpoint = 900;
const double contentMaxWidth = 1200;
const double formMaxWidth = 560;
const double listMaxWidth = 720;
const double plannerFormWidth = 420;

const EdgeInsets formScrollPadding = EdgeInsets.fromLTRB(20, 20, 20, 140);

bool isWideWidth(double width) => width >= wideBreakpoint;
