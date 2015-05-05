#!/usr/bin/env coffee

{pegex} = require '../lib/Pegex'

test "Pegex.pegex export function works", ->
  tree = pegex('a: /(b)/').parse 'b'
  deepEqual tree, a: 'b'
