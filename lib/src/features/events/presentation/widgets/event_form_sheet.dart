import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shalomly_app/src/core/constants/translation_string.dart';
import 'package:shalomly_app/src/core/theme/app_theme.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/events/domain/event_draft.dart';
import 'package:shalomly_app/src/features/events/domain/event_type.dart';
import 'package:shalomly_app/src/features/events/presentation/event_type_style.dart';
import 'package:shalomly_app/src/features/groups/domain/group.dart';

/// What the creator filled in, and the Groups they chose to share it with.
class EventFormResult {
  final EventDraft draft;
  final List<Group> shareWith;
  const EventFormResult(this.draft, {this.shareWith = const []});
}

/// The form for posting an Event, or editing one when [initial] is given.
/// [shareableGroups] are the Groups the creator may share a new Event with;
/// none are offered when editing. Returns null if the creator closed the sheet.
Future<EventFormResult?> showEventFormSheet(
  BuildContext context, {
  EventDraft? initial,
  List<Group> shareableGroups = const [],
}) {
  return showModalBottomSheet<EventFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.churchColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EventForm(initial: initial, shareableGroups: shareableGroups),
  );
}

class _EventForm extends StatefulWidget {
  final EventDraft? initial;
  final List<Group> shareableGroups;
  const _EventForm({this.initial, this.shareableGroups = const []});

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _address;
  late final TextEditingController _pdf;
  late final TextEditingController _image;

  EventType? _type;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _repeat = false;
  final Set<int> _shareWith = {};
  List<String> _problems = const [];

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial ?? const EventDraft();
    _title = TextEditingController(text: initial.title);
    _description = TextEditingController(text: initial.description);
    _location = TextEditingController(text: initial.locationName);
    _address = TextEditingController(text: initial.address);
    _pdf = TextEditingController(text: initial.pdfUrl);
    _image = TextEditingController(text: initial.imageUrl);
    _type = initial.type;
    final start = initial.startsAt;
    if (start != null) {
      _startDate = DateTime(start.year, start.month, start.day);
      _startTime = TimeOfDay.fromDateTime(start);
    }
    final end = initial.endsAt;
    if (end != null) {
      _endDate = DateTime(end.year, end.month, end.day);
      _endTime = TimeOfDay.fromDateTime(end);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _location,
      _address,
      _pdf,
      _image,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  DateTime? _combine(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  EventDraft _draft() {
    // An end time with no end date means the same day as the start.
    final endDate = _endDate ?? _startDate;
    return EventDraft(
      title: _title.text,
      type: _type,
      startsAt: _combine(_startDate, _startTime),
      endsAt: _combine(endDate, _endTime),
      description: _description.text,
      locationName: _location.text,
      address: _address.text,
      pdfUrl: _pdf.text,
      imageUrl: _image.text,
      repeatWeeklyForMonth: _repeat && !_isEditing,
    );
  }

  void _submit() {
    final problems = <String>[
      // An end date alone can't make an end.
      if (_endDate != null && _endTime == null)
        TranslationString.eventProblemEndHalf,
      for (final problem in _draft().problems) _messageFor(problem),
    ];
    if (problems.isNotEmpty) {
      setState(() => _problems = problems);
      return;
    }
    Navigator.pop(
      context,
      EventFormResult(
        _draft(),
        shareWith: [
          for (final group in widget.shareableGroups)
            if (_shareWith.contains(group.id)) group,
        ],
      ),
    );
  }

  String _messageFor(EventDraftProblem problem) => switch (problem) {
    EventDraftProblem.missingTitle => TranslationString.eventProblemTitle,
    EventDraftProblem.missingType => TranslationString.eventProblemType,
    EventDraftProblem.missingStart => TranslationString.eventProblemStart,
    EventDraftProblem.endBeforeStart => TranslationString.eventProblemEnd,
    EventDraftProblem.badPdfLink => TranslationString.eventProblemPdf,
    EventDraftProblem.badImageLink => TranslationString.eventProblemImage,
  };

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final current = isStart ? _startDate : (_endDate ?? _startDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      // An Event being edited may be older than a year; the picker needs
      // its first date to be no later than the date it opens on.
      firstDate: (current != null && current.isBefore(DateTime(now.year - 1)))
          ? current
          : DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3, 12, 31),
    );
    if (picked == null) return;
    setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? _startTime : _endTime) ??
          const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked == null) return;
    setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.churchColors;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              (_isEditing
                      ? TranslationString.eventFormEditTitle
                      : TranslationString.eventFormPostTitle)
                  .tr(),
              style: AppTheme.serif(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: TranslationString.eventFieldTitle.tr(),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              TranslationString.eventFieldType.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in EventType.values)
                  ChoiceChip(
                    avatar: Icon(type.icon, size: 18, color: colors.primary),
                    label: Text(type.label),
                    labelStyle: const TextStyle(fontSize: 15),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 12,
                    ),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _PickerTile(
              icon: Icons.calendar_today_rounded,
              label: TranslationString.eventFieldStartDate.tr(),
              value: _startDate == null
                  ? null
                  : MaterialLocalizations.of(context)
                        .formatFullDate(_startDate!),
              onTap: () => _pickDate(isStart: true),
            ),
            _PickerTile(
              icon: Icons.schedule_rounded,
              label: TranslationString.eventFieldStartTime.tr(),
              value: _startTime?.format(context),
              onTap: () => _pickTime(isStart: true),
            ),
            _PickerTile(
              icon: Icons.event_available_rounded,
              label: TranslationString.eventFieldEndDate.tr(),
              value: _endDate == null
                  ? null
                  : MaterialLocalizations.of(context).formatFullDate(_endDate!),
              onTap: () => _pickDate(isStart: false),
            ),
            _PickerTile(
              icon: Icons.schedule_rounded,
              label: TranslationString.eventFieldEndTime.tr(),
              value: _endTime?.format(context),
              onTap: () => _pickTime(isStart: false),
            ),
            if (_endDate != null || _endTime != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(TranslationString.eventClearEnd.tr()),
                  onPressed: () => setState(() {
                    _endDate = null;
                    _endTime = null;
                  }),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: TranslationString.eventFieldDescription.tr(),
                helperText: TranslationString.eventFieldDescriptionHint.tr(),
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _location,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: TranslationString.eventFieldLocation.tr(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _address,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: TranslationString.eventFieldAddress.tr(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pdf,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: TranslationString.eventFieldPdf.tr(),
                helperText: TranslationString.eventFieldPdfHint.tr(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _image,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: TranslationString.eventFieldImage.tr(),
              ),
            ),
            if (!_isEditing)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(TranslationString.eventRepeatTitle.tr()),
                subtitle: Text(TranslationString.eventRepeatHint.tr()),
                value: _repeat,
                onChanged: (value) => setState(() => _repeat = value),
              ),
            if (!_isEditing && widget.shareableGroups.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                TranslationString.eventShareHeading.tr(),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.text),
              ),
              Text(
                TranslationString.eventShareHint.tr(),
                style: TextStyle(fontSize: 14, color: colors.textMuted),
              ),
              for (final group in widget.shareableGroups)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(group.name, style: const TextStyle(fontSize: 16)),
                  value: _shareWith.contains(group.id),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _shareWith.add(group.id);
                    } else {
                      _shareWith.remove(group.id);
                    }
                  }),
                ),
            ],
            if (_problems.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final problem in _problems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    problem.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _submit,
              child: Text(
                (_isEditing
                        ? TranslationString.eventFormSave
                        : TranslationString.eventFormPublish)
                    .tr(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable row showing a label and the chosen date or time.
class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.churchColors;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 56,
      leading: Icon(icon, color: colors.primary),
      title: Text(
        label,
        style: TextStyle(fontSize: 15, color: colors.textMuted),
      ),
      subtitle: Text(
        value ?? TranslationString.eventTapToChoose.tr(),
        style: TextStyle(
          fontSize: 17,
          fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
          color: value == null ? colors.textMuted : colors.text,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: colors.textMuted),
      onTap: onTap,
    );
  }
}
