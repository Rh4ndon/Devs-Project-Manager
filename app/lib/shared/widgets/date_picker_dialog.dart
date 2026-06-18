import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<void> showDatePickerDialog({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required void Function(DateTime) onSelected,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => _DatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      onSelected: onSelected,
    ),
  );
}

class _DatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final void Function(DateTime) onSelected;

  const _DatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onSelected,
  });

  @override
  State<_DatePickerDialog> createState() => _DatePickerDialogState();
}

class _DatePickerDialogState extends State<_DatePickerDialog> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  List<int> get _validDays {
    final days = <int>[];
    for (int d = 1; d <= _daysInMonth; d++) {
      final dt = DateTime(_year, _month, d);
      if (!dt.isBefore(widget.firstDate) && !dt.isAfter(widget.lastDate)) {
        days.add(d);
      }
    }
    return days;
  }

  List<int> get _validYears {
    final years = <int>[];
    for (int y = widget.firstDate.year; y <= widget.lastDate.year; y++) {
      years.add(y);
    }
    return years;
  }

  void _submit() {
    widget.onSelected(DateTime(_year, _month, _day));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) => i + 1);
    final validDays = _validDays;
    final years = _validYears;

    return AlertDialog(
      title: const Text('Select date'),
      content: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _month,
              decoration: const InputDecoration(labelText: 'Month', isDense: true),
              items: months.map((m) => DropdownMenuItem(
                value: m,
                child: Text(DateFormat.MMM().format(DateTime(2000, m))),
              )).toList(),
              onChanged: (v) {
                if (v == null) return;
                final maxDay = DateTime(_year, v + 1, 0).day;
                setState(() {
                  _month = v;
                  if (_day > maxDay) _day = maxDay;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: validDays.contains(_day) ? _day : validDays.first,
              decoration: const InputDecoration(labelText: 'Day', isDense: true),
              items: validDays.map((d) => DropdownMenuItem(
                value: d,
                child: Text(d.toString()),
              )).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _day = v);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: years.contains(_year) ? _year : years.first,
              decoration: const InputDecoration(labelText: 'Year', isDense: true),
              items: years.map((y) => DropdownMenuItem(
                value: y,
                child: Text(y.toString()),
              )).toList(),
              onChanged: (v) {
                if (v == null) return;
                final maxDay = DateTime(v, _month + 1, 0).day;
                setState(() {
                  _year = v;
                  if (_day > maxDay) _day = maxDay;
                });
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
