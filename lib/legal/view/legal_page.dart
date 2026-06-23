import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/legal_bloc.dart';
import '../../models/legal_models.dart';

// Shared palette
const _kInk = Color(0xFF0D1220);
const _kBlue = Color(0xFF1463E0);
const _kBlueBg = Color(0xFFE8F0FE);
const _kPage = Color(0xFFEEF1F5);
const _kMuted = Color(0xFF9AA3B2);
const _kField = Color(0xFFF4F6FA);

// Folder accent pairs [stroke, fill], cycled by position. Kept in the same
// order as the bloc so a folder previews with the colour it will keep.
const _kFolderPalette = <List<Color>>[
  [Color(0xFF1463E0), Color(0xFFE8F0FE)],
  [Color(0xFF1A8A4A), Color(0xFFE8F5EE)],
  [Color(0xFF9B59B6), Color(0xFFF5EEFF)],
  [Color(0xFFE07A14), Color(0xFFFFF4EC)],
  [Color(0xFFC0392B), Color(0xFFFCE8E8)],
];

// Starter folders suggested per case type, drawn from how each kind of matter
// is actually filed - so a new case opens with a structure that fits its work.
const _kFolderTemplates = <String, List<String>>{
  'CIVIL': ['Pleadings', 'Discovery', 'Evidence', 'Correspondence'],
  'CRIMINAL': ['FIR', 'Bail Documents', 'Evidence', 'Witness Statements'],
  'FAMILY': ['Petition', 'Financial Disclosure', 'Custody & Welfare', 'Correspondence'],
  'CORPORATE': ['Contracts', 'Due Diligence', 'Compliance', 'Resolutions'],
};

List<String> _foldersForType(String type) => List<String>.from(
    _kFolderTemplates[type] ?? const ['Pleadings', 'Evidence', 'Correspondence']);

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LegalBloc(),
      child: const LegalView(),
    );
  }
}

class LegalView extends StatelessWidget {
  const LegalView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LegalBloc, LegalState>(
      builder: (context, state) {
        // A "sub-screen" is a drill-down inside Cases (case detail / folder
        // detail). These bring their own back+title header, so the global
        // brand header and the section pills step out of the way.
        final inSubScreen =
            state.activeTab == 'cases' && state.selectedCaseId != null;
        final showPills = !inSubScreen && state.activeTab != 'profile';

        return Scaffold(
          backgroundColor: _kPage,
          drawer: _buildAppDrawer(context, state),
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (!inSubScreen) _buildHeader(context, state),
                    if (showPills) _buildTabs(context, state),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _buildMainContent(context, state),
                      ),
                    ),
                    _buildBottomNav(context, state),
                  ],
                ),
              ),
              if (state.selectedDate != null) _buildDateModal(context, state),
            ],
          ),
        );
      },
    );
  }

  
  // Header
  

  Widget _buildHeader(BuildContext context, LegalState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (innerContext) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Scaffold.of(innerContext).openDrawer(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: const Icon(Icons.menu_rounded, color: _kInk, size: 21),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showNotifications(context, state),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      color: _kInk, size: 21),
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
          ),
        ],
      ),
    );
  }

  /// Slide-in panel behind the hamburger: the account it belongs to, the plan
  /// it's on, and the build it's running.
  Widget _buildAppDrawer(BuildContext context, LegalState state) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: _kField,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.close, size: 16, color: _kMuted),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kBlue, Color(0xFF3D82F0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Center(
                      child: Text('AC',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alex Carter',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _kInk)),
                        SizedBox(height: 2),
                        Text('Carter & Associates',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _kMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
                decoration: BoxDecoration(
                  color: _kField,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _kPage),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Free plan',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _kInk)),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.pop(context);
                        _snack(context,
                            'Upgrades aren’t available in this preview.');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                            color: _kBlue,
                            borderRadius: BorderRadius.circular(11)),
                        child: const Text('Upgrade',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Divider(height: 1, color: Colors.grey[100]),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Version 1.0.0',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kInk)),
                  const SizedBox(width: 6),
                  Text('· Build 1',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[400])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, LegalState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kPage,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildTabItem(context, 'Documents', 'documents',
              state.activeTab == 'documents'),
          _buildTabItem(context, 'Cases', 'cases', state.activeTab == 'cases'),
          _buildTabItem(context, 'Calendar', 'calendar',
              state.activeTab == 'calendar'),
        ],
      ),
    );
  }

  Widget _buildTabItem(
      BuildContext context, String label, String value, bool isActive) {
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
                color: isActive ? _kInk : const Color(0xFF8A95A6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  
  // Routing
  

  Widget _buildMainContent(BuildContext context, LegalState state) {
    if (state.activeTab == 'documents') return _buildHomeView(context, state);
    if (state.activeTab == 'cases') {
      if (state.selectedCaseId == null) return _buildCasesListView(context, state);
      if (state.selectedCategoryId == null) {
        return _buildCaseDetailView(context, state);
      }
      return _buildCategoryDetailView(context, state);
    }
    if (state.activeTab == 'calendar') return _buildCalendarView(context, state);
    return _buildProfileView(context, state);
  }

  // Home

  Widget _buildHomeView(BuildContext context, LegalState state) {
    return ListView(
      key: const ValueKey('home'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 8),
          child: Text('Upcoming Hearings',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _kInk)),
        ),
        _buildHearingsCard(state),
        const SizedBox(height: 16),
        _buildQuickActions(context, state),
        const SizedBox(height: 16),
        _buildSearchButton(context, state),
        const Padding(
          padding: EdgeInsets.only(top: 14, bottom: 8),
          child: Text('Recent Documents',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _kInk)),
        ),
        _buildRecentDocs(state),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHearingsCard(LegalState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildHearingRow('Mehta v. State Bank', '9:30 AM · High Court, Mumbai',
              'JUN', '25', 'CRIMINAL', const Color(0xFFE07A14), const Color(0xFFFFF4EC)),
          Divider(height: 1, color: Colors.grey[100], indent: 16, endIndent: 16),
          _buildHearingRow('Smith v. Johnson', '10:00 AM · Supreme Court, NY',
              'JUN', '28', 'CIVIL', _kBlue, _kBlueBg),
        ],
      ),
    );
  }

  Widget _buildHearingRow(String title, String subtitle, String month,
      String day, String type, Color color, Color bg) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(month,
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                Text(day,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1.1)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: _kInk),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _kMuted,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Text(type,
                style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, LegalState state) {
    return Row(
      children: [
        _buildActionChip(
          Icons.center_focus_weak,
          'Scan Doc',
          () => _showCasePicker(
            context,
            state,
            title: 'Scan to case',
            subtitle: 'Choose where the scanned document is filed',
            onPick: (c) {
              context.read<LegalBloc>().add(FileUploaded(c.id, null));
              _snack(context, 'Scanned document added to ${c.name}');
            },
          ),
        ),
        const SizedBox(width: 9),
        _buildActionChip(
          Icons.text_fields,
          'OCR Text',
          () => _snack(context, 'Open a document, then run OCR to extract its text.'),
        ),
        const SizedBox(width: 9),
        _buildActionChip(
          Icons.picture_as_pdf,
          'To PDF',
          () => _snack(context, 'Open a document to export it as a PDF.'),
        ),
        const SizedBox(width: 9),
        _buildActionChip(
          Icons.folder_open,
          'Case Files',
          () => context.read<LegalBloc>().add(const TabChanged('cases')),
        ),
      ],
    );
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: _kBlue, size: 20),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _kInk),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context, LegalState state) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showSearch(context, state),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kBlue,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: _kBlue.withOpacity(0.32),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.white, size: 17),
            SizedBox(width: 10),
            Text('Search Documents',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDocs(LegalState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildRecentDocRow('Complaint_SmithJohnson.pdf',
              'Smith v. Johnson · 2.4 MB', 'Jun 21', Colors.red[50]!, Colors.red),
          Divider(height: 1, color: Colors.grey[100], indent: 16, endIndent: 16),
          _buildRecentDocRow('Witness_Statement_OCR.pdf',
              'Mehta v. State Bank · 890 KB', 'Jun 20', Colors.green[50]!, Colors.green),
          Divider(height: 1, color: Colors.grey[100], indent: 16, endIndent: 16),
          _buildRecentDocRow('Court_Order_2024CV0847.pdf',
              'Smith v. Johnson · 1.1 MB', 'Jun 18', Colors.blue[50]!, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildRecentDocRow(
      String title, String subtitle, String date, Color bg, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.description, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _kInk),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: _kMuted)),
              ],
            ),
          ),
          Text(date,
              style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFFB0B8C4),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  
  // Cases
  

  Widget _buildCasesListView(BuildContext context, LegalState state) {
    return ListView(
      key: const ValueKey('cases_list'),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('All Cases',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _kInk)),
            GestureDetector(
              onTap: () => _showNewCaseModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: _kBlue.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('New Case',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...state.cases.map((c) => _buildCaseItem(context, c)),
      ],
    );
  }

  Widget _buildCaseItem(BuildContext context, Case c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.read<LegalBloc>().add(CaseSelected(c.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _kInk)),
                      Text(c.number,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kMuted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: c.typeBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(c.type,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: c.typeColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.description, color: _kMuted, size: 14),
                const SizedBox(width: 4),
                Text('${c.docs} Docs',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kMuted)),
                Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                        color: Color(0xFFD9E0EA), shape: BoxShape.circle)),
                const Icon(Icons.calendar_today, color: _kMuted, size: 14),
                const SizedBox(width: 4),
                Text(c.hearing,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _kMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseDetailView(BuildContext context, LegalState state) {
    final selectedCase =
        state.cases.firstWhere((c) => c.id == state.selectedCaseId);
    return Stack(
      key: const ValueKey('case_detail'),
      children: [
        Column(
          children: [
            _buildDetailHeader(
              context,
              onBack: () =>
                  context.read<LegalBloc>().add(const CaseSelected(null)),
              title: selectedCase.name,
              subtitle: selectedCase.number,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: selectedCase.typeBg,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(selectedCase.type,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selectedCase.typeColor)),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildCaseOverviewCard(context, selectedCase),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Categories (${selectedCase.categories.length})',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () =>
                            _showAddCategoryModal(context, selectedCase.id),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: _kBlue, size: 14),
                            SizedBox(width: 4),
                            Text('New Folder',
                                style: TextStyle(
                                    color: _kBlue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...selectedCase.categories
                      .map((cat) => _buildCategoryItem(context, cat)),
                  if (selectedCase.uncategorizedFiles.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Files',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    ...selectedCase.uncategorizedFiles
                        .map((file) => _buildFileItem(file)),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () => context
                .read<LegalBloc>()
                .add(FileUploaded(selectedCase.id, null)),
            backgroundColor: _kBlue,
            child: const Icon(Icons.upload, color: Colors.white),
          ),
        )
      ],
    );
  }

  /// Docket-style summary of the case, shown above its folders. The left edge
  /// carries the case-type colour so the card reads as "this kind of matter".
  Widget _buildCaseOverviewCard(BuildContext context, Case c) {
    final scheduled = c.hearing != '-' && c.hearing.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                      color: c.typeColor,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 10),
                const Text('Case details',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kInk)),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showEditCaseModal(context, c),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: _kBlueBg,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 14, color: _kBlue),
                        SizedBox(width: 5),
                        Text('Edit',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _kBlue)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          _factRow('COURT', c.court),
          _factDivider(),
          _factRow('NEXT HEARING',
              scheduled ? c.hearing : 'Not scheduled',
              highlight: scheduled),
          _factDivider(),
          _factRow('CASE NO.', c.number),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _factRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 106,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _kMuted,
                    letterSpacing: 0.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: highlight ? _kBlue : _kInk)),
          ),
        ],
      ),
    );
  }

  Widget _factDivider() {
    return Divider(
        height: 1, color: Colors.grey[100], indent: 16, endIndent: 16);
  }

  void _showEditCaseModal(BuildContext context, Case c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _EditCaseModalContent(
        original: c,
        onSave: (name, number, court, type, hearing) {
          context.read<LegalBloc>().add(CaseUpdated(
                caseId: c.id,
                name: name,
                number: number,
                court: court,
                type: type,
                hearing: hearing,
              ));
          Navigator.pop(modalContext);
          _snack(context, 'Case details updated');
        },
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, Category cat) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.read<LegalBloc>().add(CategorySelected(cat.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: cat.bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.folder, color: cat.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('${cat.docs} Documents',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _kMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(CaseFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(10)),
            child:
                const Icon(Icons.description, color: Color(0xFFAAB2BF), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${file.size} • ${file.date}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _kMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDetailView(BuildContext context, LegalState state) {
    final selectedCase =
        state.cases.firstWhere((c) => c.id == state.selectedCaseId);
    final cat = selectedCase.categories
        .firstWhere((c) => c.id == state.selectedCategoryId);
    return Stack(
      key: const ValueKey('category_detail'),
      children: [
        Column(
          children: [
            _buildDetailHeader(
              context,
              onBack: () =>
                  context.read<LegalBloc>().add(const CategorySelected(null)),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: cat.bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.folder, color: cat.color, size: 16),
              ),
              title: cat.name,
              subtitle: '${cat.docs} Documents',
            ),
            Expanded(
              child: cat.files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                                color: const Color(0xFFF0F2F5),
                                borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.description,
                                color: Color(0xFFAAB2BF), size: 32),
                          ),
                          const SizedBox(height: 16),
                          const Text('No files yet',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          const Text(
                              'Upload documents to this folder\nto see them here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: _kMuted)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        ...cat.files.map((file) => _buildFileItem(file)),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () => context
                .read<LegalBloc>()
                .add(FileUploaded(selectedCase.id, cat.name)),
            backgroundColor: _kBlue,
            child: const Icon(Icons.upload, color: Colors.white),
          ),
        )
      ],
    );
  }

  /// Shared sub-screen header (back button + title + optional leading/trailing).
  Widget _buildDetailHeader(
    BuildContext context, {
    required VoidCallback onBack,
    required String title,
    required String subtitle,
    Widget? leading,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          if (leading != null) ...[leading, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kMuted)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
  
  // Calendar

  Widget _buildCalendarView(BuildContext context, LegalState state) {
    return ListView(
      key: const ValueKey('calendar'),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('June 2026',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _snack(
                      context, 'June 2026 is the only month in this preview.'),
                  child: _calNavIcon(Icons.chevron_left),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _snack(
                      context, 'June 2026 is the only month in this preview.'),
                  child: _calNavIcon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCalendarCard(context, state),
        const SizedBox(height: 12),
        const Center(
          child: Text('Tap any day to add or view a hearing',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w500, color: _kMuted)),
        ),
        const SizedBox(height: 20),
        const Text('Hearings this month',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...state.cases.map((c) => _buildMiniCaseItem(c)),
      ],
    );
  }

  Widget _calNavIcon(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 18, color: _kInk),
    );
  }

  Widget _buildCalendarCard(BuildContext context, LegalState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildCalendarGrid(context, state),
          const SizedBox(height: 16),
          Row(
            children: [
              _legendChip(_kBlue, 'Hearing day'),
              const SizedBox(width: 18),
              _legendChip(null, 'Today'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendChip(Color? fill, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill ?? Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: fill == null ? Border.all(color: _kBlue, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11.5, fontWeight: FontWeight.w600, color: _kMuted)),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context, LegalState state) {
    const headers = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    // Align day 1 under its real weekday. June 1 2026 is a Monday, so the grid
    // must offset by the weekday rather than dropping day 1 into Sunday.
    final firstWeekday = DateTime(2026, 6, 1).weekday % 7; // Mon=1..Sun=7 -> Sun=0
    const daysInMonth = 30;
    const today = 22; // 2026-06-22

    final hearingDays = <int>{};
    for (final c in state.cases) {
      final parts = c.hearing.split(' ');
      if (parts.length == 2 && parts[0] == 'Jun') {
        final d = int.tryParse(parts[1]);
        if (d != null) hearingDays.add(d);
      }
    }

    return Column(
      children: [
        Row(
          children: headers
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kMuted)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, crossAxisSpacing: 7, mainAxisSpacing: 7),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < firstWeekday) return const SizedBox();
            final day = index - firstWeekday + 1;
            final hasHearing = hearingDays.contains(day);
            final isToday = day == today;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.read<LegalBloc>().add(DateSelected('$day')),
              child: Container(
                decoration: BoxDecoration(
                  color: hasHearing
                      ? _kBlue
                      : (isToday ? const Color(0xFFEAF1FE) : _kField),
                  borderRadius: BorderRadius.circular(12),
                  border: isToday && !hasHearing
                      ? Border.all(color: _kBlue, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasHearing || isToday
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: hasHearing
                                ? Colors.white
                                : (isToday ? _kBlue : _kInk))),
                    if (hasHearing)
                      Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniCaseItem(Case c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              Text(c.hearing,
                  style: const TextStyle(fontSize: 11, color: _kMuted)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: c.typeBg, borderRadius: BorderRadius.circular(6)),
            child: Text(c.type,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.typeColor)),
          ),
        ],
      ),
    );
  }

  // Profile

  Widget _buildProfileView(BuildContext context, LegalState state) {
    final activeCases = state.cases.length;
    final totalDocs = state.cases.fold<int>(0, (sum, c) => sum + c.docs);
    final hearings = state.cases.where((c) => c.hearing != '-').length;

    return ListView(
      key: const ValueKey('profile'),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kBlue, Color(0xFF3D82F0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('AC',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alex Carter',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _kInk)),
                        const SizedBox(height: 2),
                        const Text('Litigation Attorney · Carter & Associates',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: _kMuted)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: _kBlueBg,
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('Bar No. NY-184320',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: _kBlue)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _profileStat('$activeCases', 'Active Cases'),
                  _statDivider(),
                  _profileStat('$totalDocs', 'Documents'),
                  _statDivider(),
                  _profileStat('$hearings', 'Hearings'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionLabel('ACCOUNT'),
        _settingsGroup([
          _settingRow(Icons.person_outline, 'Personal details',
              'Name, bar number, contact', () => _snack(context, 'Personal details')),
          _settingRow(Icons.notifications_none, 'Notifications',
              'Hearing reminders & alerts', () => _showNotifications(context, state)),
          _settingRow(Icons.cloud_outlined, 'Storage & sync',
              '12.4 GB of 50 GB used', () => _snack(context, 'Storage & sync')),
        ]),
        const SizedBox(height: 16),
        _sectionLabel('PREFERENCES'),
        _settingsGroup([
          _settingRow(Icons.lock_outline, 'Security & privacy',
              'Passcode, biometrics', () => _snack(context, 'Security & privacy')),
          _settingRow(Icons.help_outline, 'Help & support',
              'Guides and contact', () => _snack(context, 'Help & support')),
        ]),
        const SizedBox(height: 16),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _confirmSignOut(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 3))
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.logout, color: Color(0xFFE03A1E), size: 19),
                SizedBox(width: 12),
                Text('Sign out',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE03A1E))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _profileStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: _kInk)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: _kMuted)),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
        width: 1, height: 32, color: const Color(0xFFEEF1F5));
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kMuted,
              letterSpacing: 0.8)),
    );
  }

  Widget _settingsGroup(List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(Divider(
            height: 1, color: Colors.grey[100], indent: 56, endIndent: 16));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingRow(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: _kField, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: _kBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _kInk)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _kMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _kMuted, size: 18),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: const Text(
            "You'll need to sign in again to access your cases and documents.",
            style: TextStyle(fontSize: 13.5, color: Color(0xFF4B5563))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(
                    color: _kMuted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _snack(context, 'Signed out');
            },
            child: const Text('Sign out',
                style: TextStyle(
                    color: Color(0xFFE03A1E), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // Bottom navigation

  Widget _buildBottomNav(BuildContext context, LegalState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _kPage)),
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
              _buildNavItem(context, Icons.home_rounded, 'Home', 'documents',
                  state.activeTab == 'documents'),
              _buildNavItem(context, Icons.folder_rounded, 'Cases', 'cases',
                  state.activeTab == 'cases'),
              _buildNavItem(context, Icons.event_rounded, 'Calendar', 'calendar',
                  state.activeTab == 'calendar'),
              _buildNavItem(context, Icons.person_rounded, 'Profile', 'profile',
                  state.activeTab == 'profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label,
      String value, bool isActive) {
    final color = isActive ? _kBlue : const Color(0xFFAAB2BF);
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

  // Overlays & sheets

  Widget _buildDateModal(BuildContext context, LegalState state) {
    final day = state.selectedDate!;
    final cases = state.cases.where((c) {
      final parts = c.hearing.split(' ');
      return parts.length == 2 && parts[1] == day;
    }).toList();
    final weekday = _weekdayName(DateTime(2026, 6, int.tryParse(day) ?? 1).weekday);

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => context.read<LegalBloc>().add(const DateSelected(null)),
        child: Container(
          color: Colors.black45,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // absorb taps inside the sheet
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _grabber(),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('June $day',
                              style: const TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(weekday,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _kMuted)),
                        ],
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context
                            .read<LegalBloc>()
                            .add(const DateSelected(null)),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: _kField,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.close,
                              size: 16, color: _kMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: cases.isEmpty
                        ? SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 8),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                      color: _kField,
                                      borderRadius: BorderRadius.circular(15)),
                                  child: const Icon(Icons.event_available,
                                      color: _kMuted, size: 23),
                                ),
                                const SizedBox(height: 12),
                                const Text('Nothing scheduled',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _kInk)),
                                const SizedBox(height: 4),
                                const Text(
                                    'Add a case to set its next hearing for this day.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 12.5, color: _kMuted)),
                                const SizedBox(height: 8),
                              ],
                            ),
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: cases
                                .map((c) => _buildModalCaseItem(context, c))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 8),
                  _buildAddCaseToDayButton(context, state, day),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Case row used inside the date modal - tapping it closes the modal and
  /// jumps straight into the case detail.
  Widget _buildModalCaseItem(BuildContext context, Case c) {
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
          border: Border.all(color: _kPage),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kInk)),
                  const SizedBox(height: 2),
                  Text('${c.number} · ${c.court}',
                      style: const TextStyle(fontSize: 11.5, color: _kMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: c.typeBg, borderRadius: BorderRadius.circular(6)),
              child: Text(c.type,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: c.typeColor)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: _kMuted, size: 18),
          ],
        ),
      ),
    );
  }

  /// Pinned action inside the date sheet: schedule an existing case's next
  /// hearing onto the day the sheet is showing.
  Widget _buildAddCaseToDayButton(
      BuildContext context, LegalState state, String day) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _scheduleCaseOnDay(context, state, day),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _kBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _kBlue.withOpacity(0.28),
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

  /// Opens the case picker filtered to cases not already on this day, then
  /// sets the chosen case's hearing to it.
  void _scheduleCaseOnDay(BuildContext context, LegalState state, String day) {
    final label = 'Jun $day';
    _showCasePicker(
      context,
      state,
      title: 'Add to June $day',
      subtitle: 'Pick a case to set its next hearing for this day',
      where: (c) => c.hearing != label,
      trailingHint: (c) => c.hearing == '-' ? null : 'Now ${c.hearing}',
      emptyText: 'Every case is already on this day.',
      onPick: (c) {
        context.read<LegalBloc>().add(CaseScheduled(c.id, label));
        _snack(context, '${c.name} scheduled for $label');
      },
    );
  }

  String _weekdayName(int wd) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return names[(wd - 1) % 7];
  }

  void _showNotifications(BuildContext context, LegalState state) {
    final hearings = state.cases.where((c) => c.hearing != '-').toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _grabber(),
            const SizedBox(height: 14),
            const Text('Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Hearing reminders from your active cases',
                style: TextStyle(
                    fontSize: 12.5,
                    color: _kMuted,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            if (hearings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("You're all caught up.",
                    style: TextStyle(fontSize: 13.5, color: _kMuted)),
              )
            else
              ...hearings.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color: c.typeBg,
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.gavel_rounded,
                              color: c.typeColor, size: 19),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hearing · ${c.name}',
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: _kInk)),
                              const SizedBox(height: 2),
                              Text('${c.hearing} · ${c.court}',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: _kMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  void _showCasePicker(
    BuildContext context,
    LegalState state, {
    required String title,
    required String subtitle,
    required void Function(Case) onPick,
    bool Function(Case)? where,
    String? Function(Case)? trailingHint,
    String emptyText = 'No cases available yet.',
  }) {
    final cases =
        where == null ? state.cases : state.cases.where(where).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _grabber(),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: _kMuted,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            if (cases.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(emptyText,
                    style: const TextStyle(fontSize: 13.5, color: _kMuted)),
              )
            else
              ...cases.map((c) {
                final hint = trailingHint?.call(c);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.pop(modalContext);
                    onPick(c);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: _kField,
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: c.typeBg,
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.folder,
                              color: c.typeColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name,
                                  style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: _kInk)),
                              Text(c.number,
                                  style: const TextStyle(
                                      fontSize: 11.5, color: _kMuted)),
                            ],
                          ),
                        ),
                        if (hint != null) ...[
                          Text(hint,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _kMuted)),
                          const SizedBox(width: 8),
                        ],
                        const Icon(Icons.chevron_right, color: _kMuted, size: 18),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showSearch(BuildContext context, LegalState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _SearchSheet(
        cases: state.cases,
        onOpenCase: (caseId) {
          final bloc = context.read<LegalBloc>();
          Navigator.pop(modalContext);
          bloc.add(const TabChanged('cases'));
          bloc.add(CaseSelected(caseId));
        },
      ),
    );
  }

  Widget _grabber() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: const Color(0xFFE2E6EC),
            borderRadius: BorderRadius.circular(2)),
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
  }

  // Create modals

  void _showNewCaseModal(BuildContext context) {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final courtController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _NewCaseModalContent(
        nameController: nameController,
        numberController: numberController,
        courtController: courtController,
        onSave: (type, folders) {
          context.read<LegalBloc>().add(CaseCreated(
                name: nameController.text,
                number: numberController.text,
                court: courtController.text,
                type: type,
                folders: folders,
              ));
          Navigator.pop(modalContext);
        },
      ),
    );
  }

  void _showAddCategoryModal(BuildContext context, int caseId) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _buildInput(
                  'CATEGORY NAME', 'e.g. Discovery Documents', controller),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<LegalBloc>()
                      .add(CategoryAdded(caseId, controller.text));
                  Navigator.pop(modalContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Category',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPage)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPage)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewCaseModalContent extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController numberController;
  final TextEditingController courtController;
  final void Function(String type, List<String> folders) onSave;

  const _NewCaseModalContent({
    required this.nameController,
    required this.numberController,
    required this.courtController,
    required this.onSave,
  });

  @override
  State<_NewCaseModalContent> createState() => _NewCaseModalContentState();
}

class _NewCaseModalContentState extends State<_NewCaseModalContent> {
  static const _types = ['CIVIL', 'CRIMINAL', 'FAMILY', 'CORPORATE'];

  String selectedType = 'CIVIL';
  late List<String> _folders = _foldersForType(selectedType);
  final TextEditingController _folderInput = TextEditingController();

  @override
  void dispose() {
    _folderInput.dispose();
    super.dispose();
  }

  /// True while the folder list still matches the current type's template -
  /// i.e. the user hasn't removed or added anything.
  bool get _isDefaultSet {
    final template = _foldersForType(selectedType);
    if (template.length != _folders.length) return false;
    for (var i = 0; i < template.length; i++) {
      if (template[i] != _folders[i]) return false;
    }
    return true;
  }

  void _selectType(String type) {
    setState(() {
      // Only re-seed folders from the new template if the user hadn't touched
      // them yet - never silently discard a list they've customised.
      final untouched = _isDefaultSet;
      selectedType = type;
      if (untouched) _folders = _foldersForType(type);
    });
  }

  void _removeFolder(String name) => setState(() => _folders.remove(name));

  void _resetFolders() =>
      setState(() => _folders = _foldersForType(selectedType));

  void _addFolder() {
    final name = _folderInput.text.trim();
    if (name.isEmpty) return;
    final exists = _folders.any((f) => f.toLowerCase() == name.toLowerCase());
    _folderInput.clear();
    if (exists) return;
    setState(() => _folders.add(name));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Create New Case',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 20),
            _buildInput('CASE NAME', 'e.g. Doe v. Roe', widget.nameController),
            _buildInput(
                'CASE NUMBER', 'e.g. 2026-CV-001', widget.numberController),
            _buildInput(
                'COURT', 'e.g. District Court, NY', widget.courtController),
            const Text('CASE TYPE',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types
                  .map((type) => GestureDetector(
                        onTap: () => _selectType(type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selectedType == type
                                ? _kBlueBg
                                : const Color(0xFFF0F2F5),
                            border: Border.all(
                                color: selectedType == type
                                    ? _kBlue
                                    : Colors.transparent,
                                width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: selectedType == type
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: selectedType == type ? _kBlue : _kMuted,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 22),
            _buildFoldersSection(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  widget.onSave(selectedType, List<String>.from(_folders)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                  _folders.isEmpty
                      ? 'Create Case'
                      : 'Create Case · ${_folders.length} '
                          '${_folders.length == 1 ? 'folder' : 'folders'}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Editable preview of the folders the case will open with. Each chip wears
  /// the colour the folder keeps inside the case, so this reads as the case's
  /// filing structure rather than a plain tag list.
  Widget _buildFoldersSection() {
    final typeLabel =
        '${selectedType[0]}${selectedType.substring(1).toLowerCase()}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('CASE FOLDERS (${_folders.length})',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kMuted)),
            const Spacer(),
            if (!_isDefaultSet)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _resetFolders,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 13, color: _kBlue),
                    SizedBox(width: 3),
                    Text('Reset',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kBlue)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Suggested for $typeLabel cases. Remove any you don’t need or '
          'add your own - you can change these later.',
          style: const TextStyle(
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: _kMuted),
        ),
        const SizedBox(height: 12),
        if (_folders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPage),
            ),
            child: const Text(
                'No folders - the case starts empty. Add one below.',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _kMuted)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _folders.length; i++)
                _folderChip(_folders[i], i),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kPage),
                ),
                child: TextField(
                  controller: _folderInput,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addFolder(),
                  decoration: const InputDecoration(
                    hintText: 'Add a folder…',
                    isCollapsed: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: _kMuted, fontSize: 14),
                  ),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _addFolder,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _folderChip(String name, int index) {
    final colors = _kFolderPalette[index % _kFolderPalette.length];
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
      decoration: BoxDecoration(
        color: colors[1],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_rounded, size: 15, color: colors[0]),
          const SizedBox(width: 6),
          Text(name,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: _kInk)),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _removeFolder(name),
            child: Icon(Icons.close_rounded,
                size: 14, color: colors[0].withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPage)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPage)),
            ),
          ),
        ],
      ),
    );
  }
}


// Edit case details


class _EditCaseModalContent extends StatefulWidget {
  final Case original;
  final void Function(String name, String number, String court, String type,
      String hearing) onSave;

  const _EditCaseModalContent({required this.original, required this.onSave});

  @override
  State<_EditCaseModalContent> createState() => _EditCaseModalContentState();
}

class _EditCaseModalContentState extends State<_EditCaseModalContent> {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _types = ['CIVIL', 'CRIMINAL', 'FAMILY', 'CORPORATE'];

  late final TextEditingController _name;
  late final TextEditingController _number;
  late final TextEditingController _court;
  late String _type;
  DateTime? _hearing;

  @override
  void initState() {
    super.initState();
    final c = widget.original;
    _name = TextEditingController(text: c.name);
    _number =
        TextEditingController(text: c.number == 'Pending' ? '' : c.number);
    _court = TextEditingController(text: c.court == 'TBD' ? '' : c.court);
    _type = _types.contains(c.type) ? c.type : 'CIVIL';
    _hearing = _parseHearing(c.hearing);
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _court.dispose();
    super.dispose();
  }

  /// Reads the stored 'MMM d' hearing label back into a date (year follows the
  /// app's June 2026 context) so the picker opens on the current value.
  DateTime? _parseHearing(String h) {
    final parts = h.split(' ');
    if (parts.length != 2) return null;
    final m = _months.indexOf(parts[0]);
    final d = int.tryParse(parts[1]);
    if (m < 0 || d == null) return null;
    return DateTime(2026, m + 1, d);
  }

  String _fmtHearing(DateTime dt) => '${_months[dt.month - 1]} ${dt.day}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit case details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 12),
            _input('CASE NAME', 'e.g. Doe v. Roe', _name),
            _input('CASE NUMBER', 'e.g. 2026-CV-001', _number),
            _input('COURT', 'e.g. District Court, NY', _court),
            _dateField(
              label: 'NEXT HEARING (OPTIONAL)',
              placeholder: 'Set a hearing date',
              value: _hearing == null ? null : _fmtHearing(_hearing!),
              onPick: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _hearing ?? DateTime(2026, 6, 22),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _hearing = picked);
              },
              onClear: () => setState(() => _hearing = null),
            ),
            const Text('CASE TYPE',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types
                  .map((type) => GestureDetector(
                        onTap: () => setState(() => _type = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _type == type
                                ? _kBlueBg
                                : const Color(0xFFF0F2F5),
                            border: Border.all(
                                color: _type == type
                                    ? _kBlue
                                    : Colors.transparent,
                                width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _type == type
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: _type == type ? _kBlue : _kMuted,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => widget.onSave(
                _name.text.trim(),
                _number.text.trim(),
                _court.text.trim(),
                _type,
                _hearing == null ? '-' : _fmtHearing(_hearing!),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                minimumSize: const Size(double.infinity, 50),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save changes',
                  style:
                      TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _input(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPage)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPage)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField({
    required String label,
    required String placeholder,
    required String? value,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
          const SizedBox(height: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPick,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPage),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: _kMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value ?? placeholder,
                      style: TextStyle(
                        fontSize: 15,
                        color: value == null ? _kMuted : _kInk,
                      ),
                    ),
                  ),
                  if (value != null)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onClear,
                      child: const Icon(Icons.close, size: 16, color: _kMuted),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Document search

class _DocHit {
  final String name;
  final String size;
  final String date;
  final String caseName;
  final int caseId;
  const _DocHit(this.name, this.size, this.date, this.caseName, this.caseId);
}

class _SearchSheet extends StatefulWidget {
  final List<Case> cases;
  final void Function(int caseId) onOpenCase;

  const _SearchSheet({required this.cases, required this.onOpenCase});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _controller = TextEditingController();
  String _query = '';
  late final List<_DocHit> _all;

  @override
  void initState() {
    super.initState();
    _all = [
      for (final c in widget.cases) ...[
        for (final f in c.uncategorizedFiles)
          _DocHit(f.name, f.size, f.date, c.name, c.id),
        for (final cat in c.categories)
          for (final f in cat.files)
            _DocHit(f.name, f.size, f.date, c.name, c.id),
      ]
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final results = q.isEmpty
        ? _all
        : _all
            .where((h) =>
                h.name.toLowerCase().contains(q) ||
                h.caseName.toLowerCase().contains(q))
            .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E6EC),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                  color: _kField, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Icon(Icons.search, color: _kMuted, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        hintText: 'Search documents and cases',
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        hintStyle: TextStyle(color: _kMuted, fontSize: 14),
                      ),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                      child: const Icon(Icons.close, color: _kMuted, size: 18),
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                    '${results.length} ${results.length == 1 ? 'result' : 'results'}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kMuted)),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              color: Color(0xFFCBD2DC), size: 40),
                          const SizedBox(height: 12),
                          Text('No documents match "$_query"',
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280))),
                          const SizedBox(height: 4),
                          const Text('Try a different name or case',
                              style: TextStyle(fontSize: 12, color: _kMuted)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final hit = results[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onOpenCase(hit.caseId),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: _kField,
                                borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.description,
                                      color: _kBlue, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(hit.name,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: _kInk),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(
                                          '${hit.caseName} · ${hit.size} · ${hit.date}',
                                          style: const TextStyle(
                                              fontSize: 11, color: _kMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: _kMuted, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
