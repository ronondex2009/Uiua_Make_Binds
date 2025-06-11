DIRECTORY   ← "C:\\Users\\ronan\\OneDrive\\Desktop\\Uiua projects\\PROGRESS\\GenerateBinds"
INPUT       ← $"_\\OpenCL-Headers-main\\headers\\CL\\opencl.h" DIRECTORY
INCLUDEPATH ← $"_\\OpenCL-Headers-main\\headers" DIRECTORY

$ VOID ← "void"
$ CHAR ← "char"
$ SHORT ← "short"
$ INT ← "int"
$ LONG ← "long"
$ FLOAT ← "float"
$ DOUBLE ← "double"
$ UNSIGNED ← "unsigned"
$ SIGNED ← "signed"
$ POINTER ← "*"
DEFAULTBINDS ←

# Bind generation is currently a best-effort conversion
# union types are not supported. Only these things get converted to binds:
# typedefs which make a FULL definition and typedef structs
# These things are ommited (but not limited to:)
#   unions, typedef unions, externs, __attribute__, __extension__,
#   non-&ffi supported types, typedefs that cannot be parsed,
#   typedef structs that cannot be parsed,
#   functions, and CURRENTLY pointers
# Bindings are generated in a literal sense.

&cd DIRECTORY
&runi {"cpp" INPUT "-o" "output.h" "-I" INCLUDEPATH}
&fras "output.h"

# First regex pass
◴⊸⊃(
  ≡⊢regex "typedef .* __attribute__\s*\\(\\(.*\\)\\)" # Remove typedef type __attribute__(())
)
◌⍢(⊃(⋅∘|▽=0⊸⦷⊙⋅∘)°□⊢⊃↙↘ 1|≠0⧻.) # remove all above from file

# Second regex pass
◴⊂₅⊸⊃(
  ≡⊢regex "__attribute__\s*\\(\\(.*\\)\\)"                       # Remove __attribute__(()))
| ≡⊢⬚0regex "# [0-9]+[\s\n\r]*\".*\"(\s[0-9])*"                  # Remove # ... PATH ...
| ≡⊢⬚0regex "__extension__"                                      # Remove __extension__
| ≡⊢⬚0regex "union[\s\n\r]*\\{[a-zA-Z0-9_;\s\n\r]*\\}[\s\n\r]*;" # Remove union types
| ≡⊢⬚0regex "\\[[0-9]*\\]"                                       # Remove indexes
)
◌⍢(⊃(⋅∘|▽=0⊸⦷⊙⋅∘)°□⊢⊃↙↘ 1|≠0⧻.) # remove all above from file

# reformat
⍜⊜∘(≡(⋅" pointer "&p$"REPLACING _".)) ⊸⦷ "*"
⍜⊜∘(≡(⋅"; "&p$"REPLACING _".)) ⊸⦷ " ;"
⍜⊜∘(≡(⋅" , "&p$"REPLACING _".)) ⊸⦷ ","
⍜⊜∘(≡(⋅" { "&p$"REPLACING _".)) ⊸⦷ "{"
⍜⊜∘(≡(⋅" } "&p$"REPLACING _".)) ⊸⦷ "}"
⍜⊜∘(≡(⋅" "&p$"REPLACING _".)) ⊸⦷ " struct "
# ⍜⊜∘(≡(⋅"_ignored_typedef_union"&p$"REPLACING _".)) ⊸⦷ "typedef union" # prevent parser from expecting typedef format on unions (not supported)

&fwa "formatted.h".

# tokenize
⊜(□⊜(□⊜□⊸≠@\n)⊸≠@\r)⊸≠@ 
⍥/◇⊂2

# filter
⊸≡◇(⍤"__attribute__ left in file"=0/+⦷"__attribute__") # mask for tokens to keep
▽⊸≡◇(≠0⧻)                                              # empty tokens are deleted

&p "--GENERATING BINDINGS--"

# parse
┌─╴Parser
  ~ {
    Head ← ¯1
    Tokens
    Alias ← ""
    Name ← ""
    Symbols ← {}
    Typedefs ← {} # 'symbols' but for every typedef in struct
  }
  NextToken     ← |1 °□⊡⊃(+₁Head|Tokens)
  CurrToken     ← |1 °□⊡⊃(Head|Tokens)
  Accept        ↚ |2.2 ⟜⍥(⍜Head+₁)⊸(≠0⧻regex⊙NextToken)
  Expect        ↚ |2.2 ⊸⍤$"Expected _"⟜Accept
  Throw         ↚ ⊸⍤$"Parse error: expected _"
  Cleanup       ↚ °⊸Head ⊃(Head|Parser Tokens)
  SetNam        ↚ ⍜Name(⋅∘)⟜CurrToken
  SetAls        ↚ ⍥(°⊸Alias""⍜Name(⋅∘)⟜Alias)≠0⧻⊸Name ⍜Alias(⋅↘₋₁)⟜CurrToken
  AddSym        ↚ ⍜Symbols(˜⊂⊙□)⟜CurrToken
  NestSyms      ↚ °⊸Symbols{} ˜⍜Typedefs(˜⊂⊙□) ⊸Symbols # move cur symbols into Typedefs
  Camel         ↚ ⌵▽¬⊸⦷@_
  FormatStr     ↚ /$"_; _"≡⍚(/$"_ _"≡₀(⋅"_")) # creates format string
  TypeFormat    ↚ $"$\"_\" _"⊃(FormatStr¤□Symbols|Camel/◇$"_ _"⇌Symbols)
  StructFormat  ↚ $"$\"{_}\" _"⊃(FormatStr Typedefs|Camel◇/$"_ _"≡⍚/$"_ _"Typedefs)
  GenBindTyp    ↚ $"_ ← _\n" ⊃(Camel Alias|TypeFormat)
  GenBindStruct ↚ $"_ ← _\n" ⊃(Camel Name|StructFormat)
  GenBindAlias  ↚ ⨬(""|$"  _ ← _\n" ∩Camel⊃(Alias|Name)) ⊸(≠0⧻Alias)
  GenerateBind  ← ⨬(GenBindTyp|$"__"⊃(GenBindStruct|GenBindAlias))≠0⧻⊸Name
  ┌─╴Grammar
    ε           ↚ 1                                      # ε
    Symbol      ↚ ⟜⍥(AddSym) Accept "^[a-zA-Z0-9_]+$"    # sym
    Name        ↚ ⟜⍥(SetNam) Accept "^[a-zA-Z0-9_]+$"    # sym (struct)
    Alias       ↚ ⟜⍥(SetAls) Accept "^[a-zA-Z0-9_]+;$"   # alias
    StructAlias ↚ ⟜⍥(SetAls) Accept "^[a-zA-Z0-9_]*;$"   # structalias
    SymbolsP    ↚ |1.2 ⨬(ε∘|SymbolsP) Symbol             # syms'
    Symbols     ↚ ⨬(0|SymbolsP)Symbol                    # syms
    Typedef     ↚ ⨬(0|Throw";"Alias) Symbols             # typedef
    TypedefStr  ↚ ⟜⍥(NestSyms)⨬(0|Throw";"Alias) Symbols # typedef (struct)
    List        ↚ |1.2 ⨬(0|1◌List) TypedefStr            # list
    StructdefP  ↚ Throw";"StructAlias⍤1Expect"\\}"⍤1List
    Structdef   ↚ ⨬(0∘|StructdefP)⊸◌Name
    DefinitionP ↚ ⨬(Typedef|Structdef) Accept "\\{"
    # Recursive descent parser entry point.
    # IsValid PopulatedParser ? CleanParser
    Definition ← ⨬(0⍜Head+₁|DefinitionP) Accept "typedef"
  └─╴
  # Parses list of strings as tokens into a Uiua bind.
  # Returns "" if could not parse.
  # Can parse typedef and typedef structs.
  # Parsing follows this grammar:
  Parse ← (
    Parser
    ⍢(⍣(Cleanup⤙⨬(□""|□GenerateBind) Grammar~Definition|:□""⍜Head+₁⊙&s)
    | <⊃(-₁⧻Tokens|Head))
    /◇$"__"
  )
└─╴

Parser~Parse
{"128" "64" "32" "16" "9" "8" "7" "6" "5" "4" "3" "2" "1" "0"}
{"ONETWENTYEIGHT" "SIXTYFOUR" "THIRTYTWO" "SIXTEEN" "NINE" "EIGHT" "SEVEN" "SIX" "FIVE" "FOUR" "THREE" "TWO" "ONE" "ZERO"}
∧(⍜⊜∘≡⌟(⋅∘)◇⊃(⋅⦷|⋅⋅∘|∘)) # replace numbers with words
/◇⊂
$"_\n_" DEFAULTBINDS

# remove broken binds
⍥(
  &p "passing and commenting out broken binds"
  ⊸&fwa "parsed.ua"
  ⋅⊙◌&runc {"uiua" "run" ".\\parsed.ua"}
  ≡(-₁⋕◇⊣)regex "([0-9]+) \\| "
  ⍜⊜□(
    ⍜⊏≡⍚(
      $"# _"
    ):
  ) ⊸≠@\n:
) ∞
&p "all broken binds commented out"
