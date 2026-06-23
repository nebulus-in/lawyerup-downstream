import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../legal_theme.dart';
import '../../bloc/legal_bloc.dart';
import 'shared_widgets.dart';
import 'legal_modals.dart';

class CategoryDetailView extends StatelessWidget {
  const CategoryDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final cases = context.select((LegalBloc bloc) => bloc.state.cases);
    final selectedCaseId = context.select((LegalBloc bloc) => bloc.state.selectedCaseId);
    final selectedCategoryId = context.select((LegalBloc bloc) => bloc.state.selectedCategoryId);

    final selectedCase = cases.firstWhere((c) => c.id == selectedCaseId);
    final cat = selectedCase.categories.firstWhere((c) => c.id == selectedCategoryId);

    // Using cat.id as index for color stability in this preview
    final color = LegalTheme.getCategoryColor(cat.id);
    final bg = LegalTheme.getCategoryBg(cat.id);

    return Stack(
      key: const ValueKey('category_detail'),
      children: [
        Column(
          children: [
            DetailHeader(
              onBack: () => context.read<LegalBloc>().add(const CategorySelected(null)),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.folder, color: color, size: 16),
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
                              style: TextStyle(fontSize: 13, color: LegalTheme.muted)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        ...cat.files.map((file) => FileItem(caseId: selectedCase.id, file: file)),
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
            onPressed: () => LegalModals.showAddDocumentSheet(
              context,
              caseId: selectedCase.id,
              categoryName: cat.name,
              destinationLabel: cat.name,
            ),
            backgroundColor: LegalTheme.blue,
            tooltip: 'Add document',
            child: const Icon(Icons.add, color: Colors.white),
          ),
        )
      ],
    );
  }
}
