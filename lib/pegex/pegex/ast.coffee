require '../../pegex/tree'
require '../../pegex/grammar/atoms'

class Pegex.Pegex.AST extends Pegex.Tree
  constructor: ->
    @atoms = (new Pegex.Grammar.Atoms).atoms
    @extra_rules = {}

  got_grammar: (got)->
    [meta_section, rule_section] = got
    grammar = merge
      '+toprule': @toprule,
      @extra_rules,
      meta_section
    for rule in rule_section
      for key, value of rule
        grammar[key] = value
    return grammar

  got_meta_section: (got)->
    meta = {}
    for next in got
      [key, val] = next
      key = "+#{key}"
      old = meta[key]
      if old?
        if typeof old is 'object'
          old.push val
        else
          meta[key] = [ old, val ]
      else
        meta[key] = val
    return meta

  got_rule_definition: (got)->
    [name, value] = got
    name = name.replace /-/g, '_'
    @toprule = name if name == 'TOP'
    @toprule ||= name

    ret = {}
    ret[name] = value
    return ret

  got_bracketed_group: (got)->
    [prefix, group, suffix] = got
    set_modifier group, prefix
    set_quantity group, suffix
    return group

  got_all_group: (got)->
    list = @get_group got
    throw 0 unless list.length
    if list.length == 1
      return list[0]
    return '.all': list

  got_any_group: (got)->
    list = @get_group got
    throw 0 unless list.length
    return list[0] if list.length == 1
    return '.any': list

  get_group: (group)->
    get = (it)->
      return unless typeof it is 'object'
      if it instanceof Array
        a = []
        for x in it
          a.push (get x)...
        return a
      else
        return [it]
    return [ (get group)... ]

  got_rule_part: (got)->
    [rule, sep] = got
    rule = set_separator rule, sep... if sep.length
    return rule

  got_rule_reference: (got)->
    [prefix, ref1, ref2, suffix] = got
    ref = ref1 || ref2
    ref = ref.replace /-/g, '_'
    node = '.ref': ref
    if regex = @atoms[ref]
      @extra_rules[ref] = '.rgx': regex
    set_modifier node, prefix
    set_quantity node, suffix
    return node

  got_quoted_regex: (got)->
    got = got.replace /([^\w\`\%\:\<\/\,\=\;])/g, '$1'
    return '.rgx': got

  got_regex_rule_reference: (got)->
    ref = got[0] || got[1]
    return '.ref': ref

  got_whitespace_maybe: ->
    return '.rgx': '<_>'

  got_whitespace_must: ->
    return '.rgx': '<__>'

  got_whitespace_start: (got)->
    rule = if got eq '+' then '__' else '_'
    return '.rgx': "<#{rule}"

  got_regular_expression: (got)->
    if got.length == 2
      part = got.shift()
      got[0].unshift part

    set = []
    for e in got[0]
      if typeof e isnt 'string'
        if (part = e['.rgx'])?
          set.push part
        else if (part = e['.ref'])?
          set.push "<#{part}>"
        else
          throw e
      else
        set.push e
    regex = set.join ''
    regex = regex.replace /\(([ism]?\:|\=|\!)/g, '(?$1'
    return '.rgx': regex

  got_whitespace_token: (got)->
    if got.match /^\~{1,2}$/
      token = '.ref': Array(got.length).join '_'
    else if got.match /^\-{1,2}$/
      token = '.ref': Array(got.length).join '_'
    else if got == '+'
      token = '.ref': '__'
    else
      throw 0
    return token

  got_error_message: (got)->
    return '.err': got

set_modifier = (object, modifier)->
  return unless modifier
  if modifier == '='
    object['+asr'] = 1
  else if modifier == '!'
    object['+asr'] = -1
  else if modifier == '.'
    object['-skip'] = 1
  else if modifier == '+'
    object['-wrap'] = 1
  else if modifier == '-'
    object['-flat'] = 1
  else
    throw "Invalid modifier: '#{modifier}"

set_quantity = (object, quantity)->
  return unless quantity
  if quantity == '?'
    object['+max'] = 1
  else if quantity == '*'
    object['+min'] = 0
  else if quantity == '+'
    object['+min'] = 1
  else if quantity.match /^(\d+)$/
    object['+min'] = Number RegExp.$1
    object['+max'] = Number RegExp.$1
  else if quantity.match /^(\d+)\-(\d+)$/
    object['+min'] = Number RegExp.$1
    object['+max'] = Number RegExp.$2
  else if quantity.match /^(\d+)\+$/
    object['+min'] = Number RegExp.$1
  else
    throw "Invalid quantifier: '#{quantity}'"

set_separator = (rule, op, sep)->
  extra = op == '%%'
  if not rule['+max']? and not rule['+min']?
    rule = '.all': [ rule, merge clone(sep), '+max': 1 ] if extra
    return rule
  else if rule['+max']? and rule['+min']?
    [min, max] = rule
    delete rule.min
    delete rule.max
    min-- if min > 0
    max-- if max > 0
    rule =
      '.all': [
        rule,
          '+min': min,
          '+max': max,
          '-flat': 1,
          '.all': [
            sep,
            clone rule,
          ],
      ]
  else if not rule['+max']
    copy = clone rule
    min = copy['+min']
    delete copy['+min']
    new_ =
      '.all': [
        copy,
          '+min': 0,
          '-flat': 1,
          '.all': [
            sep,
            clone copy,
          ],
      ]
    if rule['+min'] == 0
      rule = new_
      rule['+max'] = 1
    else if rule['+min'] == 1
      rule = new_
    else
      rule = new_
      min-- if min > 0
      last = rule['.all'].length - 1
      rule['.all'][last]['+min'] = min
  else
    if rule['+max'] == 1
      delete rule['+min']
      rule = clone rule
      rule['+max'] = 1
      if extra
        s = clone sep
        s['+max'] = 1
        rule = '.all': [rule, s]
      return rule
    else
      xxx 'FAIL', rule, op, sep
  if extra
    s = clone sep
    s['+max'] = 1
    push rule['.all'].push s
  return rule

clone = (o)->
  return o unless o or typeof o is 'object'
  c = new o.constructor()
  c[k] = clone v for k, v of o
  c

merge = (object, rest...)->
  for hash in rest
    for k, v of hash
      object[k] = v
  object

