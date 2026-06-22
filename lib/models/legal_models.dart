import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CaseFile extends Equatable {
  final int id;
  final String name;
  final String size;
  final String date;

  const CaseFile({
    required this.id,
    required this.name,
    required this.size,
    required this.date,
  });

  @override
  List<Object?> get props => [id, name, size, date];
}

class Category extends Equatable {
  final int id;
  final String name;
  final int docs;
  final Color color;
  final Color bg;
  final List<CaseFile> files;

  const Category({
    required this.id,
    required this.name,
    required this.docs,
    required this.color,
    required this.bg,
    this.files = const [],
  });

  @override
  List<Object?> get props => [id, name, docs, color, bg, files];

  Category copyWith({List<CaseFile>? files, int? docs}) {
    return Category(
      id: id,
      name: name,
      docs: docs ?? this.docs,
      color: color,
      bg: bg,
      files: files ?? this.files,
    );
  }
}

class Case extends Equatable {
  final int id;
  final String name;
  final String number;
  final String court;
  final String type;
  final Color typeColor;
  final Color typeBg;
  final int docs;
  final String hearing;
  final List<CaseFile> uncategorizedFiles;
  final List<Category> categories;

  const Case({
    required this.id,
    required this.name,
    required this.number,
    required this.court,
    required this.type,
    required this.typeColor,
    required this.typeBg,
    required this.docs,
    required this.hearing,
    this.uncategorizedFiles = const [],
    this.categories = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        number,
        court,
        type,
        typeColor,
        typeBg,
        docs,
        hearing,
        uncategorizedFiles,
        categories,
      ];

  Case copyWith({
    List<Category>? categories,
    List<CaseFile>? uncategorizedFiles,
    int? docs,
  }) {
    return Case(
      id: id,
      name: name,
      number: number,
      court: court,
      type: type,
      typeColor: typeColor,
      typeBg: typeBg,
      docs: docs ?? this.docs,
      hearing: hearing,
      uncategorizedFiles: uncategorizedFiles ?? this.uncategorizedFiles,
      categories: categories ?? this.categories,
    );
  }
}
