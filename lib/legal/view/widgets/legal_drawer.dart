import 'package:flutter/material.dart';
import '../legal_theme.dart';

class LegalDrawer extends StatelessWidget {
  const LegalDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
                        color: LegalTheme.field,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.close, size: 16, color: LegalTheme.muted),
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
                        colors: [LegalTheme.blue, Color(0xFF3D82F0)],
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
                                color: LegalTheme.ink)),
                        SizedBox(height: 2),
                        Text('Carter & Associates',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: LegalTheme.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
                decoration: BoxDecoration(
                  color: LegalTheme.field,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: LegalTheme.page),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Free plan',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: LegalTheme.ink)),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                            color: LegalTheme.blue,
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
                          color: LegalTheme.ink)),
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
}
