import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/legal_bloc.dart';
import '../../models/legal_models.dart';

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
        return Scaffold(
          backgroundColor: const Color(0xFFEEF1F5),
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, state),
                    _buildTabs(context, state),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildMainContent(context, state),
                      ),
                    ),
                    _buildBottomNav(context, state),
                    _buildHomeIndicator(),
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

  Widget _buildHomeIndicator() {
    return Container(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      color: Colors.white,
      child: Center(
        child: Container(
          width: 120,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1220),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LegalState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.menu, color: Color(0xFF0D1220)),
          Stack(
            children: [
              const Icon(Icons.notifications_none, color: Color(0xFF0D1220)),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE03A1E),
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, LegalState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildTabItem(context, 'Documents', 'documents', state.activeTab == 'documents'),
          _buildTabItem(context, 'Cases', 'cases', state.activeTab == 'cases'),
          _buildTabItem(context, 'Calendar', 'calendar', state.activeTab == 'calendar'),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, String label, String value, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<LegalBloc>().add(TabChanged(value)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF0D1220) : const Color(0xFF8A95A6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, LegalState state) {
    if (state.activeTab == 'documents') return _buildHomeView(context, state);
    if (state.activeTab == 'cases') {
      if (state.selectedCaseId == null) return _buildCasesListView(context, state);
      if (state.selectedCategoryId == null) return _buildCaseDetailView(context, state);
      return _buildCategoryDetailView(context, state);
    }
    return _buildCalendarView(context, state);
  }

  Widget _buildHomeView(BuildContext context, LegalState state) {
    return ListView(
      key: const ValueKey('home'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 8),
          child: Text('Upcoming Hearings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D1220))),
        ),
        _buildHearingsCard(state),
        const SizedBox(height: 16),
        _buildQuickActions(),
        const SizedBox(height: 16),
        _buildSearchButton(),
        const Padding(
          padding: EdgeInsets.only(top: 14, bottom: 8),
          child: Text('Recent Documents', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D1220))),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildHearingRow('Mehta v. State Bank', '9:30 AM · High Court, Mumbai', 'JUN', '25', 'CRIMINAL', const Color(0xFFE07A14), const Color(0xFFFFF4EC)),
          Divider(height: 1, color: Colors.grey[100], indent: 16, endIndent: 16),
          _buildHearingRow('Smith v. Johnson', '10:00 AM · Supreme Court, NY', 'JUN', '28', 'CIVIL', const Color(0xFF1463E0), const Color(0xFFE8F0FE)),
        ],
      ),
    );
  }

  Widget _buildHearingRow(String title, String subtitle, String month, String day, String type, Color color, Color bg) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(month, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                Text(day, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color, height: 1.1)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0D1220)), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF9AA3B2), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Text(type, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionChip(Icons.center_focus_weak, 'Scan Doc'),
        const SizedBox(width: 9),
        _buildActionChip(Icons.text_fields, 'OCR Text'),
        const SizedBox(width: 9),
        _buildActionChip(Icons.picture_as_pdf, 'To PDF'),
        const SizedBox(width: 9),
        _buildActionChip(Icons.folder_open, 'Case Files'),
      ],
    );
  }

  Widget _buildActionChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1463E0), size: 20),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0D1220)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1463E0),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF1463E0).withOpacity(0.32), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, color: Colors.white, size: 17),
          SizedBox(width: 10),
          Text('Search Documents', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildRecentDocs(LegalState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildRecentDocRow('Complaint_SmithJohnson.pdf', 'Smith v. Johnson · 2.4 MB', 'Jun 21', Colors.red[50]!, Colors.red),
          Divider(height: 1, color: Colors.grey[100], indent: 16, endIndent: 16),
          _buildRecentDocRow('Witness_Statement_OCR.pdf', 'Mehta v. State Bank · 890 KB', 'Jun 20', Colors.green[50]!, Colors.green),
          Divider(height: 1, color: Colors.grey[100], indent: 16, endIndent: 16),
          _buildRecentDocRow('Court_Order_2024CV0847.pdf', 'Smith v. Johnson · 1.1 MB', 'Jun 18', Colors.blue[50]!, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildRecentDocRow(String title, String subtitle, String date, Color bg, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.description, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0D1220)), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF9AA3B2))),
              ],
            ),
          ),
          Text(date, style: const TextStyle(fontSize: 10.5, color: Color(0xFFB0B8C4), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCasesListView(BuildContext context, LegalState state) {
    return ListView(
      key: const ValueKey('cases_list'),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('All Cases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0D1220))),
            GestureDetector(
              onTap: () => _showNewCaseModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1463E0),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: const Color(0xFF1463E0).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('New Case', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
      onTap: () => context.read<LegalBloc>().add(CaseSelected(c.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
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
                      Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D1220))),
                      Text(c.number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9AA3B2))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: c.typeBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(c.type, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c.typeColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.description, color: Color(0xFF9AA3B2), size: 14),
                const SizedBox(width: 4),
                Text('${c.docs} Docs', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF9AA3B2))),
                Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 12), decoration: const BoxDecoration(color: Color(0xFFD9E0EA), shape: BoxShape.circle)),
                const Icon(Icons.calendar_today, color: Color(0xFF9AA3B2), size: 14),
                const SizedBox(width: 4),
                Text(c.hearing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF9AA3B2))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseDetailView(BuildContext context, LegalState state) {
    final selectedCase = state.cases.firstWhere((c) => c.id == state.selectedCaseId);
    return Stack(
      key: const ValueKey('case_detail'),
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.read<LegalBloc>().add(const CaseSelected(null)),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectedCase.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(selectedCase.number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9AA3B2))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: selectedCase.typeBg, borderRadius: BorderRadius.circular(8)),
                    child: Text(selectedCase.type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selectedCase.typeColor)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Categories (${selectedCase.categories.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => _showAddCategoryModal(context, selectedCase.id),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Color(0xFF1463E0), size: 14),
                            SizedBox(width: 4),
                            Text('New Folder', style: TextStyle(color: Color(0xFF1463E0), fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...selectedCase.categories.map((cat) => _buildCategoryItem(context, cat)),
                  if (selectedCase.uncategorizedFiles.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Files', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    ...selectedCase.uncategorizedFiles.map((file) => _buildFileItem(file)),
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
            onPressed: () => context.read<LegalBloc>().add(FileUploaded(selectedCase.id, null)),
            backgroundColor: const Color(0xFF1463E0),
            child: const Icon(Icons.upload, color: Colors.white),
          ),
        )
      ],
    );
  }

  Widget _buildCategoryItem(BuildContext context, Category cat) {
    return GestureDetector(
      onTap: () => context.read<LegalBloc>().add(CategorySelected(cat.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: cat.bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.folder, color: cat.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('${cat.docs} Documents', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF9AA3B2))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9AA3B2), size: 18),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.description, color: Color(0xFFAAB2BF), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${file.size} • ${file.date}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF9AA3B2))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDetailView(BuildContext context, LegalState state) {
    final selectedCase = state.cases.firstWhere((c) => c.id == state.selectedCaseId);
    final cat = selectedCase.categories.firstWhere((c) => c.id == state.selectedCategoryId);
    return Stack(
      key: const ValueKey('category_detail'),
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.read<LegalBloc>().add(const CategorySelected(null)),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: cat.bg, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.folder, color: cat.color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        Text('${cat.docs} Documents', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9AA3B2))),
                      ],
                    ),
                  ),
                ],
              ),
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
                            decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.description, color: Color(0xFFAAB2BF), size: 32),
                          ),
                          const SizedBox(height: 16),
                          const Text('No files yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          const Text('Upload documents to this folder\nto see them here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF9AA3B2))),
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
            onPressed: () => context.read<LegalBloc>().add(FileUploaded(selectedCase.id, cat.name)),
            backgroundColor: const Color(0xFF1463E0),
            child: const Icon(Icons.upload, color: Colors.white),
          ),
        )
      ],
    );
  }

  Widget _buildCalendarView(BuildContext context, LegalState state) {
    return ListView(
      key: const ValueKey('calendar'),
      padding: const EdgeInsets.all(20),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('June 2026', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Row(
              children: [
                Icon(Icons.chevron_left),
                SizedBox(width: 8),
                Icon(Icons.chevron_right),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCalendarGrid(context, state),
        const SizedBox(height: 24),
        const Text('All Cases This Month', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...state.cases.map((c) => _buildMiniCaseItem(c)),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context, LegalState state) {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((d) => Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9AA3B2)))).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: 35,
          itemBuilder: (context, index) {
            int dayNum = index + 1;
            if (dayNum > 30) return const SizedBox();
            bool hasCase = dayNum == 25 || dayNum == 28;
            return GestureDetector(
              onTap: hasCase ? () => context.read<LegalBloc>().add(DateSelected('2026-06-$dayNum')) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: hasCase ? const Color(0xFFE8F0FE) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: hasCase ? Border.all(color: const Color(0xFF1463E0)) : null,
                  boxShadow: !hasCase ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$dayNum', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: hasCase ? const Color(0xFF1463E0) : const Color(0xFF0D1220))),
                    if (hasCase) Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF1463E0), shape: BoxShape.circle)),
                  ],
                ),
              ),
            );
          },
        )
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text(c.hearing, style: const TextStyle(fontSize: 11, color: Color(0xFF9AA3B2))),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: c.typeBg, borderRadius: BorderRadius.circular(6)),
            child: Text(c.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.typeColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, LegalState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFEEF1F5)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home, 'documents', state.activeTab == 'documents'),
          _buildNavItem(context, Icons.folder, 'cases', state.activeTab == 'cases'),
          _buildNavItem(context, Icons.calendar_today, 'calendar', state.activeTab == 'calendar'),
          _buildNavItem(context, Icons.person, 'profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String value, bool isActive) {
    return GestureDetector(
      onTap: () => context.read<LegalBloc>().add(TabChanged(value)),
      child: Icon(icon, color: isActive ? const Color(0xFF0D1220) : const Color(0xFFAAB2BF), size: 22),
    );
  }

  Widget _buildDateModal(BuildContext context, LegalState state) {
    final cases = state.cases.where((c) => c.hearing.contains(state.selectedDate!.split('-').last)).toList();
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => context.read<LegalBloc>().add(const DateSelected(null)),
        child: Container(
          color: Colors.black45,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // Prevent dismissal when clicking inside
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cases on ${state.selectedDate}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(onPressed: () => context.read<LegalBloc>().add(const DateSelected(null)), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (cases.isEmpty)
                    const Text('No cases scheduled.')
                  else
                    ...cases.map((c) => _buildCaseItem(context, c)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
        onSave: (type) {
          context.read<LegalBloc>().add(CaseCreated(
            name: nameController.text,
            number: numberController.text,
            court: courtController.text,
            type: type,
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
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _buildInput('CATEGORY NAME', 'e.g. Discovery Documents', controller),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<LegalBloc>().add(CategoryAdded(caseId, controller.text));
                Navigator.pop(modalContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1463E0),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
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
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9AA3B2))),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEF1F5))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEF1F5))),
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
  final Function(String) onSave;

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
  String selectedType = 'CIVIL';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Create New Case', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          _buildInput('CASE NAME', 'e.g. Doe v. Roe', widget.nameController),
          _buildInput('CASE NUMBER', 'e.g. 2026-CV-001', widget.numberController),
          _buildInput('COURT', 'e.g. District Court, NY', widget.courtController),
          const Text('CASE TYPE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9AA3B2))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['CIVIL', 'CRIMINAL', 'FAMILY', 'CORPORATE'].map((type) => GestureDetector(
              onTap: () => setState(() => selectedType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selectedType == type ? const Color(0xFFE8F0FE) : const Color(0xFFF0F2F5),
                  border: Border.all(color: selectedType == type ? const Color(0xFF1463E0) : Colors.transparent, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selectedType == type ? FontWeight.w700 : FontWeight.w600,
                    color: selectedType == type ? const Color(0xFF1463E0) : const Color(0xFF9AA3B2),
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => widget.onSave(selectedType),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1463E0),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Create Case', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
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
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9AA3B2))),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEF1F5))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEEF1F5))),
            ),
          ),
        ],
      ),
    );
  }
}
