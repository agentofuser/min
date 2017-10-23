import 
  tables,
  math
import 
  ../core/parser, 
  ../core/value, 
  ../core/interpreter, 
  ../core/utils

# Comparison operators

proc floatCompare(n1, n2: MinValue): bool =
  let
    a:float = if n1.kind != minFloat: n1.intVal.float else: n1.floatVal
    b:float = if n2.kind != minFloat: n2.intVal.float else: n2.floatVal
  if a.classify == fcNan and b.classify == fcNan:
    return true
  else:
    const
      FLOAT_MIN_NORMAL = 2e-1022
      FLOAT_MAX_VALUE = (2-2e-52)*2e1023
      epsilon = 0.00001
    let
      absA = abs(a)
      absB = abs(b)
      diff = abs(a - b)

    if a == b:
      return true
    elif a == 0 or b == 0 or diff < FLOAT_MIN_NORMAL:
      return diff < (epsilon * FLOAT_MIN_NORMAL)
    else:
      return diff / min((absA + absB), FLOAT_MAX_VALUE) < epsilon

proc logic_module*(i: In)=
  let def = i.define()
  
  def.symbol(">") do (i: In):
    var n1, n2: MinValue
    i.reqTwoNumbersOrStrings n2, n1
    if n1.isNumber and n2.isNumber:
      if n1.isInt and n2.isInt:
        i.push newVal(n1.intVal > n2.intVal)
      elif n1.isInt and n2.isFloat:
        i.push newVal(n1.intVal.float > n2.floatVal)
      elif n1.isFloat and n2.isFloat:
        i.push newVal(n1.floatVal > n2.floatVal)
      elif n1.isFloat and n2.isInt:
        i.push newVal(n1.floatVal > n2.intVal.float)
    else:
        i.push newVal(n1.strVal > n2.strVal)
  
  def.symbol(">=") do (i: In):
    var n1, n2: MinValue
    i.reqTwoNumbersOrStrings n2, n1
    if n1.isNumber and n2.isNumber:
      if n1.isInt and n2.isInt:
        i.push newVal(n1.intVal >= n2.intVal)
      elif n1.isInt and n2.isFloat:
        i.push newVal(n1.intVal.float > n2.floatVal or floatCompare(n1, n2))
      elif n1.isFloat and n2.isFloat:
        i.push newVal(n1.floatVal > n2.floatVal or floatCompare(n1, n2))
      elif n1.isFloat and n2.isInt:
        i.push newVal(n1.floatVal > n2.intVal.float or floatCompare(n1, n2))
    else:
      i.push newVal(n1.strVal >= n2.strVal)
  
  def.symbol("<") do (i: In):
    var n1, n2: MinValue
    i.reqTwoNumbersOrStrings n1, n2
    if n1.isNumber and n2.isNumber:
      if n1.isInt and n2.isInt:
        i.push newVal(n1.intVal > n2.intVal)
      elif n1.isInt and n2.isFloat:
        i.push newVal(n1.intVal.float > n2.floatVal)
      elif n1.isFloat and n2.isFloat:
        i.push newVal(n1.floatVal > n2.floatVal)
      elif n1.isFloat and n2.isInt:
        i.push newVal(n1.floatVal > n2.intVal.float)
    else:
        i.push newVal(n1.strVal > n2.strVal)
  
  def.symbol("<=") do (i: In):
    var n1, n2: MinValue
    i.reqTwoNumbersOrStrings n1, n2
    if n1.isNumber and n2.isNumber:
      if n1.isInt and n2.isInt:
        i.push newVal(n1.intVal >= n2.intVal)
      elif n1.isInt and n2.isFloat:
        i.push newVal(n1.intVal.float > n2.floatVal or floatCompare(n1, n2))
      elif n1.isFloat and n2.isFloat:
        i.push newVal(n1.floatVal > n2.floatVal or floatCompare(n1, n2))
      elif n1.isFloat and n2.isInt:
        i.push newVal(n1.floatVal > n2.intVal.float or floatCompare(n1, n2))
    else:
        i.push newVal(n1.strVal >= n2.strVal)
  
  def.symbol("==") do (i: In):
    var n1, n2: MinValue
    i.reqTwoSimilarTypesNonSymbol n2, n1
    if n1.kind == minFloat or n2.kind == minFloat:
      i.push newVal(floatCompare(n1, n2))
    else:
      i.push newVal(n1 == n2)
  
  def.symbol("!=") do (i: In):
    var n1, n2: MinValue
    i.reqTwoSimilarTypesNonSymbol n2, n1
    if n1.kind == minFloat or n2.kind == minFloat:
      i.push newVal(not floatCompare(n1, n2))
    i.push newVal(not (n1 == n2))
  
  # Boolean Logic
  
  def.symbol("not") do (i: In):
    let vals = i.expect("bool")
    let b = vals[0]
    i.push newVal(not b.boolVal)
  
  def.symbol("and") do (i: In):
    let vals = i.expect("bool", "bool")
    let a = vals[0]
    let b = vals[1]
    i.push newVal(a.boolVal and b.boolVal)
  
  def.symbol("or") do (i: In):
    let vals = i.expect("bool", "bool")
    let a = vals[0]
    let b = vals[1]
    i.push newVal(a.boolVal or b.boolVal)
  
  def.symbol("xor") do (i: In):
    let vals = i.expect("bool", "bool")
    let a = vals[0]
    let b = vals[1]
    i.push newVal(a.boolVal xor b.boolVal)
  
  def.symbol("string?") do (i: In):
    if i.peek.kind == minString:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.symbol("integer?") do (i: In):
    if i.peek.kind == minInt:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.symbol("float?") do (i: In):
    if i.peek.kind == minFloat:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.symbol("number?") do (i: In):
    if i.peek.kind == minFloat or i.peek.kind == minInt:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.symbol("boolean?") do (i: In):
    if i.peek.kind == minBool:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.symbol("quotation?") do (i: In):
    if i.peek.kind == minQuotation:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.symbol("dictionary?") do (i: In):
    if i.peek.isDictionary:
      i.push true.newVal
    else:
      i.push false.newVal
  
  def.finalize("logic")
