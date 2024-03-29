// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dgrep;

import 'dart:io';
import 'package:args/args.dart';

const String USAGE = 'usage: dart dgrep.dart [-rnS] patterns file_or_directory';
const String RECURSIVE = 'recursive';
const String LINE_NUMBER = 'line-number';
const String FOLLOW_LINKS = 'follow-links';

ArgResults argResults;

void printMatch(File file, List lines, int i) {
  StringBuffer sb = new StringBuffer();
  if (argResults[RECURSIVE]) sb.write('${file.path}:');
  if (argResults[LINE_NUMBER]) sb.write('${i + 1}:');
  sb.write(lines[i]);
  print(sb.toString());
}

searchFile(File file, List<String> searchTerms) {
  file.readAsLines().then((lines) {
    for (int i = 0; i < lines.length; i++) {
      bool found = false;
      for (int j = 0; j < searchTerms.length && !found; j++) {
        if (lines[i].contains(searchTerms[j])) {
          printMatch(file, lines, i);
          found = true;
        }
      }
    }
  }).catchError(print);
}

void main(List<String> arguments) {
  final ArgParser parser = new ArgParser()
      ..addFlag(RECURSIVE, negatable: false, abbr: 'r')
      ..addFlag(LINE_NUMBER, negatable: false, abbr: 'n')
      ..addFlag(FOLLOW_LINKS, negatable: false, abbr: 'S');


  argResults = parser.parse(arguments);

  if (argResults.rest.length < 2) {
    print(USAGE);
    exit(1);
  }

  final String searchPath = argResults.rest.last;
  final List<String> searchTerms = argResults.rest.sublist(0, argResults.rest.length - 1);

  FileSystemEntity.isDirectory(searchPath).then((bool isDir) {
    if (isDir) {
      final Directory startingDir = new Directory(searchPath);
      startingDir.list(recursive: argResults[RECURSIVE], followLinks: argResults[FOLLOW_LINKS]).listen((FileSystemEntity entity) {
        if (entity is File) {
          searchFile(entity, searchTerms);
        }
      });
    } else {
      searchFile(new File(searchPath), searchTerms);
    }
  });
}
