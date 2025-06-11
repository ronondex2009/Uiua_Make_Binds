# Uiua Binder
### What does this do?
This is a Uiua program that converts C header files into Uiua binds. This is mainly intended for people who want to use the &ffi interface on large libraries and do not want to manually write out every struct and type definition.
### What gets converted?
Right now, parsing is a best-effort conversion. There is no guarantee that all type definitions and structs in a header file get converted properly. A lot of generated binds from complicated header files will end up using types that never got bound. **The program will automatically comment out invalid binds.**
The program will put the generated binds into parsed.ua. This can then be used immediately as all invalid binds are automatically commented out.
Here is what is currently supported by the internal parser:
- All &ffi supported types by default (shorts, longs, ints, doubles, chars, unsigned/signed values, structs)
- Pointers
- `typedef`s
- `typedef struct`s
- `#define` (handled by cpp.exe)
- `#include` (handled by cpp.exe)
- `#ifndef` `#ifdef` `#endif` ...

Here is what is **not** supported by the internal parser:
- Non-&ffi supported types that aren't defined by a previous `typedef`
- `union` and `typedef union` (these will cause "Parse error: expected ;" and _may_ cause some `typedef struct` to not parse)
- `__attribute__(())` and `__extension__`
- indexed names on type definitions; ex: `typedef cl_char s[4];` (indexes are removed automatically)

## Dependencies
Uiua must be included in PATH.
The C preprocessor should be included in PATH by default on most OSes. If not, include it.
