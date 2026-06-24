import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/blocs.dart';
import '../../models/legal_models.dart';
import 'legal_theme.dart';
import 'widgets/home_view.dart';
import 'widgets/cases_list_view.dart';
import 'widgets/case_detail_view.dart';
import 'widgets/category_detail_view.dart';
import 'widgets/calendar_view.dart';
import 'widgets/profile_view.dart';
import 'widgets/research_view.dart';
import 'widgets/research_webview.dart';
import 'widgets/legal_drawer.dart';
import 'widgets/legal_modals.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    // BLoCs are now provided at the app level in main.dart
    return const LegalView();
  }
}

class LegalView extends StatefulWidget {
  const LegalView({super.key});

  @override
  State<LegalView> createState() => _LegalViewState();
}

class _LegalViewState extends State<LegalView> {
  /// Drives the collapse of the bottom nav (and the browser header) when the
  /// in-app research browser is scrolled.
  final ValueNotifier<bool> _barsVisible = ValueNotifier(true);

  @override
  void dispose() {
    _barsVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = context.select((NavigationBloc bloc) => bloc.state.activeTab);
    final selectedCaseId = context.select((NavigationBloc bloc) => bloc.state.selectedCaseId);
    final selectedDate = context.select((NavigationBloc bloc) => bloc.state.selectedDate);
    final selectedSource = context.select((NavigationBloc bloc) => bloc.state.selectedSource);

    final inSubScreen = activeTab == 'cases' && selectedCaseId != null;
    final inResearchSource = activeTab == 'research' && selectedSource != null;
    final hideChrome = inSubScreen || inResearchSource;
    final showPills = !hideChrome && activeTab != 'profile';

    return MultiBlocListener(
      // Every mutation BLoC surfaces failures the same way: a transient
      // errorMessage shown as a snack. One helper keeps the three in lockstep.
      listeners: [
        _errorListener<CaseBloc, CaseState>((s) => s.errorMessage),
        _errorListener<CategoryBloc, CategoryState>((s) => s.errorMessage),
        _errorListener<FileBloc, FileState>((s) => s.errorMessage),
      ],
      child: BarVisibilityScope(
        visible: _barsVisible,
        child: Scaffold(
          backgroundColor: LegalTheme.page,
          drawer: const LegalDrawer(),
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (!hideChrome) const _Header(),
                    if (showPills) const _Tabs(),
                    const Expanded(
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _MainContent(),
                      ),
                    ),
                    CollapsibleBar(
                      visible: _barsVisible,
                      enabled: inResearchSource,
                      alignment: Alignment.bottomCenter,
                      child: const _BottomNav(),
                    ),
                  ],
                ),
              ),
              if (selectedDate != null) const _DateModalOverlay(),
              const _FileProgressBar(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A [BlocListener] that snacks the transient [errorMessage] (read via [errorOf])
/// whenever it appears or changes — the shared error-surfacing wiring for every
/// mutation BLoC.
BlocListener<B, S> _errorListener<B extends StateStreamable<S>, S>(
    String? Function(S) errorOf) {
  return BlocListener<B, S>(
    listenWhen: (prev, curr) {
      final err = errorOf(curr);
      return err != null && err != errorOf(prev);
    },
    listener: (context, state) => LegalModals.snack(context, errorOf(state)!),
  );
}

/// A thin progress bar pinned to the top while a file operation is in flight.
///
/// Owns its own [FileBloc] subscription so the in-flight toggle rebuilds only
/// this strip rather than the whole [LegalView] shell. With the in-memory
/// repository the flag is momentary; it becomes visible once the repository
/// does real async I/O. Pairs with the droppable transformers in FileBloc.
class _FileProgressBar extends StatelessWidget {
  const _FileProgressBar();

  @override
  Widget build(BuildContext context) {
    final processing =
        context.select((FileBloc bloc) => bloc.state.isProcessing);
    if (!processing) return const SizedBox.shrink();
    return const Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 3,
          child: LinearProgressIndicator(minHeight: 3),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final activeTab = context.select((NavigationBloc bloc) => bloc.state.activeTab);
    final isProfile = activeTab == 'profile';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isProfile)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final nav = context.read<NavigationBloc>();
                final back = nav.state.previousTab;
                nav.add(TabChanged(back == 'profile' ? 'documents' : back));
              },
              child: const _HeaderIcon(icon: Icons.arrow_back_rounded),
            )
          else
            Builder(
              builder: (innerContext) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Scaffold.of(innerContext).openDrawer(),
                child: const _HeaderIcon(icon: Icons.menu_rounded),
              ),
            ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                context.read<NavigationBloc>().add(const TabChanged('profile')),
            child: const _HeaderIcon(icon: Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  const _HeaderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: LegalTheme.cardDecoration(radius: 14, opacity: 0.05, blur: 12, dy: 3),
      child: Icon(icon, color: LegalTheme.ink, size: 21),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    final activeTab = context.select((NavigationBloc bloc) => bloc.state.activeTab);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LegalTheme.page,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _TabItem(label: 'Documents', value: 'documents', isActive: activeTab == 'documents'),
          _TabItem(label: 'Cases', value: 'cases', isActive: activeTab == 'cases'),
          _TabItem(label: 'Research', value: 'research', isActive: activeTab == 'research'),
          _TabItem(label: 'Calendar', value: 'calendar', isActive: activeTab == 'calendar'),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isActive;

  const _TabItem({required this.label, required this.value, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.read<NavigationBloc>().add(TabChanged(value)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? LegalTheme.ink : const Color(0xFF8A95A6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    final activeTab = context.select((NavigationBloc bloc) => bloc.state.activeTab);
    final selectedCaseId = context.select((NavigationBloc bloc) => bloc.state.selectedCaseId);
    final selectedCategoryId = context.select((NavigationBloc bloc) => bloc.state.selectedCategoryId);
    final selectedSource = context.select((NavigationBloc bloc) => bloc.state.selectedSource);

    if (activeTab == 'documents') return const HomeView();
    if (activeTab == 'cases') {
      if (selectedCaseId == null) return const CasesListView();
      if (selectedCategoryId == null) return const CaseDetailView();
      return const CategoryDetailView();
    }
    if (activeTab == 'calendar') return const CalendarView();
    if (activeTab == 'research') {
      final source = researchSourceById(selectedSource);
      if (source != null) return ResearchWebView(source: source);
      return const ResearchView();
    }
    return const ProfileView();
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final activeTab = context.select((NavigationBloc bloc) => bloc.state.activeTab);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: LegalTheme.page)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', value: 'documents', isActive: activeTab == 'documents'),
              _NavItem(icon: Icons.folder_rounded, label: 'Cases', value: 'cases', isActive: activeTab == 'cases'),
              _NavItem(icon: Icons.menu_book_rounded, label: 'Research', value: 'research', isActive: activeTab == 'research'),
              _NavItem(icon: Icons.event_rounded, label: 'Calendar', value: 'calendar', isActive: activeTab == 'calendar'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isActive;

  const _NavItem({required this.icon, required this.label, required this.value, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? LegalTheme.blue : const Color(0xFFAAB2BF);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.read<NavigationBloc>().add(TabChanged(value)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _DateModalOverlay extends StatelessWidget {
  const _DateModalOverlay();

  @override
  Widget build(BuildContext context) {
    final date = context.select((NavigationBloc bloc) => bloc.state.selectedDate)!;
    final allCases = context.select((CaseBloc bloc) => bloc.state.cases);
    final cases =
        allCases.where((c) => c.hearingDate == date).toList();
    final weekday = LegalTheme.weekdayName(date.weekday);

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => context.read<NavigationBloc>().add(const DateSelected(null)),
        child: Container(
          color: Colors.black45,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, 
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              decoration: LegalTheme.sheetDecoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LegalModals.grabber(),
                  const SizedBox(height: 14),
                  _ModalHeader(date: date, weekday: weekday),
                  const SizedBox(height: 16),
                  Flexible(
                    child: cases.isEmpty
                        ? const _EmptyDayState()
                        : ListView(
                            shrinkWrap: true,
                            children: cases
                                .map((c) => _ModalCaseItem(c: c))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 8),
                  _AddCaseToDayButton(date: date),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  final DateTime date;
  final String weekday;
  const _ModalHeader({required this.date, required this.weekday});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${LegalTheme.monthName(date.month)} ${date.day}',
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(weekday,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: LegalTheme.muted)),
          ],
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.read<NavigationBloc>().add(const DateSelected(null)),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: LegalTheme.field,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.close, size: 16, color: LegalTheme.muted),
          ),
        ),
      ],
    );
  }
}

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: LegalTheme.field,
                borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.event_available, color: LegalTheme.muted, size: 23),
          ),
          const SizedBox(height: 12),
          const Text('Nothing scheduled',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LegalTheme.ink)),
          const SizedBox(height: 4),
          const Text('Add a case to set its next hearing for this day.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: LegalTheme.muted)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ModalCaseItem extends StatelessWidget {
  final Case c;
  const _ModalCaseItem({required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final navBloc = context.read<NavigationBloc>();
        navBloc.add(const DateSelected(null));
        navBloc.add(const TabChanged('cases'));
        navBloc.add(CaseSelected(c.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LegalTheme.page),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: LegalTheme.ink)),
                  const SizedBox(height: 2),
                  Text('${c.number} · ${c.court}',
                      style: const TextStyle(fontSize: 11.5, color: LegalTheme.muted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: LegalTheme.getCaseBg(c.type), borderRadius: BorderRadius.circular(6)),
              child: Text(c.type,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: LegalTheme.getCaseColor(c.type))),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: LegalTheme.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _AddCaseToDayButton extends StatelessWidget {
  final DateTime date;
  const _AddCaseToDayButton({required this.date});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final caseState = context.read<CaseBloc>().state;
        final label = Case.formatHearing(date);
        LegalModals.showCasePicker(
          context,
          caseState,
          title: 'Add to ${LegalTheme.monthName(date.month)} ${date.day}',
          subtitle: 'Pick a case to set its next hearing for this day',
          where: (c) => c.hearing != label,
          trailingHint: (c) => c.isScheduled ? 'Now ${c.hearing}' : null,
          emptyText: 'Every case is already on this day.',
          onPick: (c) {
            context.read<CaseBloc>().add(CaseScheduled(c.id, label));
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: LegalTheme.blue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: LegalTheme.blue.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8))
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Add a case to this day',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
