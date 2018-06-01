import 
  strutils, 
  sequtils,
  critbits,
  json,
  terminal
import 
  ../packages/nim-sgregex/sgregex,
  parser, 
  value,
  scope,
  interpreter

proc reverse[T](xs: openarray[T]): seq[T] =
  result = newSeq[T](xs.len)
  for i, x in xs:
    result[result.len-i-1] = x 

# Library methods

proc define*(i: In): ref MinScope {.extern:"min_exported_symbol_$1".}=
  var scope = new MinScope
  scope.parent = i.scope
  return scope

proc symbol*(scope: ref MinScope, sym: string, p: MinOperatorProc) {.extern:"min_exported_symbol_$1".}=
  scope.symbols[sym] = MinOperator(prc: p, kind: minProcOp, sealed: true)

proc symbol*(scope: ref MinScope, sym: string, v: MinValue) {.extern:"min_exported_symbol_$1_2".}=
  scope.symbols[sym] = MinOperator(val: v, kind: minValOp, sealed: true)

proc sigil*(scope: ref MinScope, sym: string, p: MinOperatorProc) {.extern:"min_exported_symbol_$1".}=
  scope.sigils[sym] = MinOperator(prc: p, kind: minProcOp, sealed: true)

proc sigil*(scope: ref MinScope, sym: string, v: MinValue) {.extern:"min_exported_symbol_$1_2".}=
  scope.sigils[sym] = MinOperator(val: v, kind: minValOp, sealed: true)

proc finalize*(scope: ref MinScope, name: string = "") {.extern:"min_exported_symbol_$1".}=
  var mdl = newSeq[MinValue](0).newVal(nil)
  mdl.scope = scope
  let op = proc(i: In) {.closure.} =
    i.evaluating = true
    i.push mdl
    i.evaluating = false
  if name != "":
    scope.previous.symbols[name] = MinOperator(kind: minProcOp, prc: op)

# Dictionary Methods

proc dget*(i: In, q: MinValue, s: MinValue): MinValue {.extern:"min_exported_symbol_$1".}=
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  var val = q.dVal[s.getString].val
  return i.call(val)

proc dget*(i: In, q: MinValue, s: string): MinValue {.extern:"min_exported_symbol_$1_2".}=
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  var val = q.dVal[s].val
  return i.call(val)

proc dhas*(q: MinValue, s: MinValue): bool {.extern:"min_exported_symbol_$1".}=
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  return q.dVal.contains(s.getString)

proc dhas*(q: MinValue, s: string): bool {.extern:"min_exported_symbol_$1_2".}=
  if not q.isDictionary:
    raiseInvalid("Value is not a dictionary")
  return q.dVal.contains(s)

proc ddel*(i: In, p: var MinValue, s: MinValue): MinValue {.discardable, extern:"min_exported_symbol_$1".} =
  if not p.isDictionary:
    raiseInvalid("Value is not a dictionary")
  excl(p.scope.symbols, s.getString)
  return p
      
proc ddel*(i: In, p: var MinValue, s: string): MinValue {.discardable, extern:"min_exported_symbol_$1_2".} =
  if not p.isDictionary:
    raiseInvalid("Value is not a dictionary")
  excl(p.scope.symbols, s)
  return p
      
proc dset*(i: In, p: MinValue, s: MinValue, m: MinValue): MinValue {.discardable, extern:"min_exported_symbol_$1".}=
  if not p.isDictionary:
    raiseInvalid("Value is not a dictionary")
  var q = m
  if not q.isQuotation:
    q = @[q].newVal(i.scope)
  p.scope.symbols[s.getString] = MinOperator(kind: minValOp, val: q, sealed: false)
  return p

proc dset*(i: In, p: MinValue, s: string, m: MinValue): MinValue {.discardable, extern:"min_exported_symbol_$1_2".}=
  if not p.isDictionary:
    raiseInvalid("Value is not a dictionary")
  var q = m
  if not q.isQuotation:
    q = @[q].newVal(i.scope)
  p.scope.symbols[s] = MinOperator(kind: minValOp, val: q, sealed: false)
  return p

proc keys*(i: In, q: MinValue): MinValue {.extern:"min_exported_symbol_$1".}=
  # Assumes q is a dictionary
  var r = newSeq[MinValue](0)
  for i in q.dVal.keys:
    r.add newVal(i)
  return r.newVal(i.scope)

proc values*(i: In, q: MinValue): MinValue {.extern:"min_exported_symbol_$1".}=
  # Assumes q is a dictionary
  var r = newSeq[MinValue](0)
  for i in q.dVal.values:
    r.add i.val
  return r.newVal(i.scope)

# JSON interop

proc `%`*(p: MinOperatorProc): JsonNode {.extern:"min_exported_symbol_percent_1".}=
  return %nil

proc `%`*(a: MinValue): JsonNode {.extern:"min_exported_symbol_percent_2".}=
  case a.kind:
    of minBool:
      return %a.boolVal
    of minSymbol:
      return %(";sym:$1" % [a.getstring])
    of minString:
      return %a.strVal
    of minInt:
      return %a.intVal
    of minFloat:
      return %a.floatVal
    of minQuotation:
      result = newJArray()
      for i in a.qVal:
        result.add %i
    of minDictionary:
      result = newJObject()
      for i in a.dVal.pairs: 
        result[$i.key] = %i.val

proc fromJson*(i: In, json: JsonNode): MinValue {.extern:"min_exported_symbol_$1".}= 
  case json.kind:
    of JNull:
      result = newSeq[MinValue](0).newVal(i.scope)
    of JBool: 
      result = json.getBool.newVal
    of JInt:
      result = json.getBiggestInt.newVal
    of JFloat:
      result = json.getFloat.newVal
    of JString:
      let s = json.getStr
      if s.match("^;sym:"):
        result = sgregex.replace(s, "^;sym:", "").newSym
      else:
        result = json.getStr.newVal
    of JObject:
      var res = newSeq[MinValue](0)
      for key, value in json.pairs:
        #TODO
        res.add @[key.newVal, i.fromJson(value)].newVal(i.scope)
      return res.newVal(i.scope)
    of JArray:
      var res = newSeq[MinValue](0)
      for value in json.items:
        res.add i.fromJson(value)
      return res.newVal(i.scope)

# Validators

proc expect*(i: var MinInterpreter, elements: varargs[string]): seq[MinValue] {.extern:"min_exported_symbol_$1".}=
  let stack = elements.reverse.join(" ")
  let sym = i.currSym.getString
  var valid = newSeq[string](0)
  result = newSeq[MinValue](0)
  let message = proc(invalid: string): string =
    result = "Symbol: $1 - Incorrect values found on the stack:\n" % sym
    result &= "- expected: " & stack & " $1\n" % sym
    var other = ""
    if valid.len > 0:
      other = valid.reverse.join(" ") & " "
    result &= "- got:      " & invalid & " " & other & sym
  for element in elements:
    let value = i.pop
    result.add value
    case element:
      of "bool":
        if not value.isBool:
          raiseInvalid(message(value.typeName))
      of "int":
        if not value.isInt:
          raiseInvalid(message(value.typeName))
      of "num":
        if not value.isNumber:
          raiseInvalid(message(value.typeName))
      of "quot":
        if not value.isQuotation:
          raiseInvalid(message(value.typeName))
      of "dict":
        if not value.isDictionary:
          raiseInvalid(message(value.typeName))
      of "'sym":
        if not value.isStringLike:
          raiseInvalid(message(value.typeName))
      of "sym":
        if not value.isSymbol:
          raiseInvalid(message(value.typeName))
      of "float":
        if not value.isFloat:
          raiseInvalid(message(value.typeName))
      of "string":
        if not value.isString:
          raiseInvalid(message(value.typeName))
      of "a":
        discard # any type
      else:
        var split = element.split(":")
        if split[0] == "dict":
          if not value.isTypedDictionary(split[1]):
            raiseInvalid(message(value.typeName))
        else:
          raiseInvalid("Invalid type description: " & element)
    valid.add element

proc reqQuotationOfQuotations*(i: var MinInterpreter, a: var MinValue) {.extern:"min_exported_symbol_$1".}=
  a = i.pop
  if not a.isQuotation:
    raiseInvalid("A quotation is required on the stack")
  for s in a.qVal:
    if not s.isQuotation:
      raiseInvalid("A quotation of quotations is required on the stack")

proc reqQuotationOfNumbers*(i: var MinInterpreter, a: var MinValue) {.extern:"min_exported_symbol_$1".}=
  a = i.pop
  if not a.isQuotation:
    raiseInvalid("A quotation is required on the stack")
  for s in a.qVal:
    if not s.isNumber:
      raiseInvalid("A quotation of numbers is required on the stack")

proc reqQuotationOfSymbols*(i: var MinInterpreter, a: var MinValue) {.extern:"min_exported_symbol_$1".}=
  a = i.pop
  if not a.isQuotation:
    raiseInvalid("A quotation is required on the stack")
  for s in a.qVal:
    if not s.isSymbol:
      raiseInvalid("A quotation of symbols is required on the stack")

proc reqTwoNumbersOrStrings*(i: var MinInterpreter, a, b: var MinValue) {.extern:"min_exported_symbol_$1".}=
  a = i.pop
  b = i.pop
  if not (a.isString and b.isString or a.isNumber and b.isNumber):
    raiseInvalid("Two numbers or two strings are required on the stack")

proc reqStringOrQuotation*(i: var MinInterpreter, a: var MinValue) {.extern:"min_exported_symbol_$1".}=
  a = i.pop
  if not a.isQuotation and not a.isString:
    raiseInvalid("A quotation or a string is required on the stack")

proc reqTwoQuotationsOrStrings*(i: var MinInterpreter, a, b: var MinValue) {.extern:"min_exported_symbol_$1".}=
  a = i.pop
  b = i.pop
  if not (a.isQuotation and b.isQuotation or a.isString and b.isString):
    raiseInvalid("Two quotations or two strings are required on the stack")
