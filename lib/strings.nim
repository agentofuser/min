import tables, strutils
import ../vendor/slre
import 
  ../core/types,
  ../core/parser, 
  ../core/interpreter, 
  ../core/utils

minsym "split", i:
  let sep = i.pop
  let s = i.pop
  if s.isString and sep.isString:
    for e in s.strVal.split(sep.strVal):
      i.push e.newVal
  else:
    i.error errIncorrect, "Two strings are required on the stack"

minsym "match", i:
  let reg = i.pop
  let str = i.pop
  if str.isString and reg.isString:
    var matches = str.strVal.match(reg.strVal)
    var res = newSeq[MinValue](0)
    for s in matches:
      res.add s.newVal
    i.push res.newVal
  else:
    i.error(errIncorrect, "Two strings are required on the stack")

minsym "match?", i:
  let reg = i.pop
  let str = i.pop
  if str.isString and reg.isString:
    var matches = str.strVal.match(reg.strVal)
    if matches.len > 0:
      i.push true.newVal
    else:
      i.push false.newVal
  else:
    i.error(errIncorrect, "Two strings are required on the stack")

minsym "replace", i:
  let s_replace = i.pop
  let reg = i.pop
  let s_find = i.pop
  if reg.isString and s_replace.isString and s_find.isString:
    i.push s_find.strVal.gsub(reg.strVal, s_replace.strVal).newVal
  else:
    i.error(errIncorrect, "Three strings are required on the stack")
