import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../legal_theme.dart';
import '../../bloc/blocs.dart';
import 'shared_widgets.dart';
import 'legal_modals.dart';

class CategoryDetailView extends StatelessWidget {
  const CategoryDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedCaseId = context.select((NavigationBloc bloc) => bloc.state.selectedCaseId);
    final selectedCategoryId = context.select((NavigationBloc bloc) => bloc.state.selectedCategoryId);
    final cases = context.select((CaseBloc bloc) => bloc.state.cases);
    final isMultiSelect = context.select((FileBloc bloc) => bloc.state.isMultiSelectMode);
    final selectedFileIds = context.select((FileBloc bloc) => bloc.state.selectedFileIds);

    final selectedCase = cases.firstWhere((c) => c.id == selectedCaseId);
    final cat = selectedCase.categories.firstWhere((c) => c.id == selectedCategoryId);

    final color = LegalTheme.getCategoryColor(cat.id);
    final bg = LegalTheme.getCategoryBg(cat.id);

    return Stack(
      key: const ValueKey('category_detail'),
      children: [
        Column(
          children: [
            if (isMultiSelect)
              SelectionHeader(
                caseId: selectedCase.id,
                selectedIds: selectedFileIds.toList(),
                onClear: () => context.read<FileBloc>().add(SelectionCleared()),
              )
            else
              DetailHeader(
                onBack: () => context.read<NavigationBloc>().add(const CategorySelected(null)),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.folder, color: color, size: 16),
                ),
                title: cat.name,
                subtitle: '${cat.docs} Documents',
                trailing: cat.files.isNotEmpty
                  ? TextButton(
                      onPressed: () {
                        context.read<FileBloc>().add(SelectionToggled(cat.files.first.id));
                      },
                      child: const Text('Select', 
                        style: TextStyle(color: LegalTheme.blue, fontWeight: FontWeight.w700)),
                    )
                  : null,
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
        if (!isMultiSelect)
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
