import os

var HOME*: string
if defined(windows):
  HOME = getenv("USERPROFILE")
if not defined(windows):
  HOME = getenv("HOME")

let MINRC* = HOME / ".minrc"
let MINSYMBOLS* = HOME / ".min_symbols"
let MINHISTORY* = HOME / ".min_history"
let MINFULLHISTORY* = HOME / ".min_full_history"
let MINLIBS* = HOME / ".minlibs"
