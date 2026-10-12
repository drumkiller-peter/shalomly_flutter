import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';
import 'package:shalomly_app/src/features/devotional/presentation/bloc/devotional_bloc.dart';
import 'package:shalomly_app/src/features/events/presentation/bloc/events_bloc.dart';

/// Ultra-compact, high-contrast screen tailored for smartwatch viewports (WearOS & watchOS).
class WatchGlanceScreen extends StatelessWidget {
  const WatchGlanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.churchColors.background,
      body: SafeArea(
        child: PageView(
          scrollDirection: Axis.vertical,
          children: const [_WatchDevotionalPage(), _WatchNextEventPage()],
        ),
      ),
    );
  }
}

class _WatchDevotionalPage extends StatelessWidget {
  const _WatchDevotionalPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DevotionalBloc, DevotionalState>(
      builder: (context, state) {
        if (state.status == DevotionalStatus.loaded &&
            state.quotes?.isNotEmpty == true) {
          final quote = state.quotes!.first;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: context.churchColors.warning,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  quote.content,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.churchColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (quote.authorName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '— ${quote.authorName}',
                    style: TextStyle(
                      color: context.churchColors.textMuted,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        return Center(
          child: CircularProgressIndicator(
            color: context.churchColors.warning,
            strokeWidth: 2,
          ),
        );
      },
    );
  }
}

class _WatchNextEventPage extends StatelessWidget {
  const _WatchNextEventPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsBloc, EventsState>(
      builder: (context, state) {
        if (state is EventsLoaded && state.events.isNotEmpty) {
          final nextEvent = state.events.first;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: context.churchColors.info,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  nextEvent.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.churchColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${nextEvent.startsAt.hour.toString().padLeft(2, '0')}:${nextEvent.startsAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: context.churchColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (nextEvent.location != null)
                  Text(
                    nextEvent.location!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.churchColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          );
        }
        return Center(
          child: Text(
            'No upcoming events',
            style: TextStyle(
              color: context.churchColors.textMuted,
              fontSize: 11,
            ),
          ),
        );
      },
    );
  }
}
