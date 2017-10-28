import
  critbits
import
  parser,
  scope

proc typeName*(v: MinValue): string {.extern:"min_exported_symbol_$1".}=
  case v.kind:
    of minInt:
      return "int"
    of minFloat:
      return "float"
    of minQuotation:
      return "quot"
    of minString:
      return "string"
    of minSymbol:
      return "sym"
    of minBool:
      return "bool"

# Predicates

proc isSymbol*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  return s.kind == minSymbol

proc isQuotation*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}= 
  return s.kind == minQuotation

proc isString*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}= 
  return s.kind == minString

proc isFloat*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  return s.kind == minFloat

proc isInt*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  return s.kind == minInt

proc isNumber*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  return s.kind == minInt or s.kind == minFloat

proc isBool*(s: MinValue): bool =
  return s.kind == minBool

proc isStringLike*(s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  return s.isSymbol or s.isString or (s.isQuotation and s.qVal.len == 1 and s.qVal[0].isSymbol)

proc isDictionary*(q: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  if not q.isQuotation:
    return false
  if q.qVal.len == 0:
    return true
  for val in q.qVal:
    if not val.isQuotation or val.qVal.len != 2 or not val.qVal[0].isString:
      return false
  return true

# Constructors

proc newVal*(s: string): MinValue {.extern:"min_exported_symbol_$1".}=
  return MinValue(kind: minString, strVal: s)

proc newVal*(s: cstring): MinValue {.extern:"min_exported_symbol_$1_2".}=
  return MinValue(kind: minString, strVal: $s)

proc newVal*(q: seq[MinValue], parentScope: ref MinScope): MinValue {.extern:"min_exported_symbol_$1_3".}=
  return MinValue(kind: minQuotation, qVal: q, scope: newScopeRef(parentScope))

proc newVal*(i: BiggestInt): MinValue {.extern:"min_exported_symbol_$1_4".}=
  return MinValue(kind: minInt, intVal: i)

proc newVal*(f: BiggestFloat): MinValue {.extern:"min_exported_symbol_$1_5".}=
  return MinValue(kind: minFloat, floatVal: f)

proc newVal*(s: bool): MinValue {.extern:"min_exported_symbol_$1_6".}=
  return MinValue(kind: minBool, boolVal: s)

proc newSym*(s: string): MinValue {.extern:"min_exported_symbol_$1".}=
  return MinValue(kind: minSymbol, symVal: s)

# Get string value from string or quoted symbol

proc getFloat*(v: MinValue): float {.extern:"min_exported_symbol_$1".}=
  if v.isInt:
    return v.intVal.float
  elif v.isFloat:
    return v.floatVal
  else:
    raiseInvalid("Value is not a number")

proc getString*(v: MinValue): string {.extern:"min_exported_symbol_$1".}=
  if v.isSymbol:
    return v.symVal
  elif v.isString:
    return v.strVal
  elif v.isQuotation:
    if v.qVal.len != 1:
      raiseInvalid("Quotation is not a quoted symbol")
    let sym = v.qVal[0]
    if sym.isSymbol:
      return sym.symVal
    else:
      raiseInvalid("Quotation is not a quoted symbol")
