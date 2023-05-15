import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:system_date_time_format/system_date_time_format.dart';

class TimeWidget extends StatelessWidget {
  const TimeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: Stream.periodic(const Duration(minutes: 1)),
        builder: (BuildContext context, AsyncSnapshot<Object?> snapshot) => Text(
          DateFormat(SystemDateTimeFormat.of(context).timePattern ?? "HH:mm").format(DateTime.now()),
        ),
      );
}
