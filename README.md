# Runic language compiler

A toy project to build a compiler for an in-design toy language named RUNIC.

Despite being advertised as a toy language and toy project, the end goal is to
have a stable, robust and fast programming language and compiler, that can't be
considered a "toy" anymore.

## Goals

- General purpose compiled language (for libraries, executables, embedded, ...).
- C-like language with good performance (but safer).
- Ruby-like syntax that pleases the eye (but typed).
- Minimal runtime (if any) to manipulate pointers and intrinsics.

A separate, cross-platform, and optional standard-library may come later, as a
separated project.

## Status

Basic lexer, parser and semantic analyzes are functional (thought limited to the
available feature set). Preliminary code generation has been started.

Only integer and floating point numbers are supported. External symbols,
function defintions and calling symbols/functions is also supported. Neither
pointers or data structures are available.

## Licences

The Runic compiler is released under the
[CeCILL-C](http://www.cecill.info/licences/Licence_CeCILL-C_V1-en.html) license.
The license agreement can be found in LICENSE.
