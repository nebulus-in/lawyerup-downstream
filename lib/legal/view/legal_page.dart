import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/legal_bloc.dart';
import '../../models/legal_models.dart';
import '../../repositories/legal_repository.dart';
import 'legal_theme.dart';
import 'widgets/home_view.dart';
import 'widgets/cases_list_view.dart';
import 'widgets/case_detail_view.dart';
import 'widgets/category_detail_view.dart';
import 'widgets/calendar_view.dart';
import 'widgets/profile_view.dart';
import 'widgets/legal_drawer.dart';
import 'widgets/legal_modals.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LegalBloc(
        repository: context.read<LegalRepository>(),
      ),
      child: const LegalView(),
    );
  }
}

class LegalView extends StatelessWidget {
  const LegalView({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTab = context.select((LegalBloc bloc) => bloc.state.activeTab);
    final selectedCaseId = context.select((LegalBloc bloc) => bloc.state.selectedCaseId);
    final selectedDate = context.select((LegalBloc bloc) => bloc.state.selectedDate);

    final inSubScreen = activeTab == 'cases' && selectedCaseId != null;
    final showPills = !inSubScreen && activeTab != 'profile';

    return BlocListener<LegalBloc, LegalState>(
      listenWhen: (prev, curr) =>
          curr.errorMessage != null && curr.errorMessage != prev.errorMessage,
      listener: (context, state) =>
          LegalModals.snack(context, state.errorMessage!),
      child: Scaffold(
        backgroundColor: LegalTheme.page,
        drawer: const LegalDrawer(),
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  if (!inSubScreen) const _Header(),
                  if (showPills) const _Tabs(),
                  const Expanded(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _MainContent(),
                    ),
                  ),
                  const _BottomNav(),
                ],
              ),
            ),
            if (selectedDate != null) const _DateModalOverlay(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (innerContext) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Scaffold.of(innerContext).openDrawer(),
              child: _HeaderIcon(icon: Icons.menu_rounded),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final state = context.read<LegalBloc>().state;
              LegalModals.showNotifications(context, state);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                _HeaderIcon(icon: Icons.notifications_none_rounded),
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE03A1E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
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
    final activeTab = context.select((LegalBloc bloc) => bloc.state.activeTab);

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
        onTap: () => context.read<LegalBloc>().add(TabChanged(value)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
    final activeTab = context.select((LegalBloc bloc) => bloc.state.activeTab);
    final selectedCaseId = context.select((LegalBloc bloc) => bloc.state.selectedCaseId);
    final selectedCategoryId = context.select((LegalBloc bloc) => bloc.state.selectedCategoryId);

    if (activeTab == 'documents') return const HomeView();
    if (activeTab == 'cases') {
      if (selectedCaseId == null) return const CasesListView();
      if (selectedCategoryId == null) return const CaseDetailView();
      return const CategoryDetailView();
    }
    if (activeTab == 'calendar') return const CalendarView();
    return const ProfileView();
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final activeTab = context.select((LegalBloc bloc) => bloc.state.activeTab);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: LegalTheme.page)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
              _NavItem(icon: Icons.event_rounded, label: 'Calendar', value: 'calendar', isActive: activeTab == 'calendar'),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', value: 'profile', isActive: activeTab == 'profile'),
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
      onTap: () => context.read<LegalBloc>().add(TabChanged(value)),
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
    final date = context.select((LegalBloc bloc) => bloc.state.selectedDate)!;
    final allCases = context.select((LegalBloc bloc) => bloc.state.cases);
    final cases =
        allCases.where((c) => c.hearingDate == date).toList();
    final weekday = LegalTheme.weekdayName(date.weekday);

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => context.read<LegalBloc>().add(const DateSelected(null)),
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
            Text('June ${date.day}',
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
          onTap: () => context.read<LegalBloc>().add(const DateSelected(null)),
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
        final bloc = context.read<LegalBloc>();
        bloc.add(const DateSelected(null));
        bloc.add(const TabChanged('cases'));
        bloc.add(CaseSelected(c.id));
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
        final state = context.read<LegalBloc>().state;
        final label = Case.formatHearing(date);
        LegalModals.showCasePicker(
          context,
          state,
          title: 'Add to June ${date.day}',
          subtitle: 'Pick a case to set its next hearing for this day',
          where: (c) => c.hearing != label,
          trailingHint: (c) => c.isScheduled ? 'Now ${c.hearing}' : null,
          emptyText: 'Every case is already on this day.',
          onPick: (c) {
            context.read<LegalBloc>().add(CaseScheduled(c.id, label));
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
                color: LegalTheme.blue.withOpacity(0.28),
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
