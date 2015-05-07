require '../Pegex/Input'
require '../Pegex/Optimizer'

Pegex.Constant ?= {}
Pegex.Constant.Dummy ?= {}

class Pegex.Parser
  constructor: ({@grammar, @receiver, @debug})->
    @grammar? or
      throw "Pegex.Parser object requires a grammar attribute"
    @input = null
    @debug ?=
      process?.env.PEGEX_DEBUG ||
      Pegex.Parser.Debug ? off
    @throw_on_error ?= on

    # @debug=on

  parse: (input, start)->
    start = start.replace(/-/g, '_') if start

    @position = 0
    @farthest = 0

    @input = if input instanceof Pegex.Input \
      then input \
      else new Pegex.Input string: input

    @input.open() \
      unless @input._is_open
    @buffer = @input.read()

    throw "No 'grammar'. Can't parse" \
      unless @grammar

    @grammar.tree ||= @grammar.make_tree()

    start_rule_ref = start ||
      @grammar.tree['+toprule']? && @grammar.tree['+toprule'] ||
      @grammar.tree.TOP && 'TOP' or
        throw "No starting rule for Pegex.Parser.parse"

    throw "No 'receiver'. Can't parse" \
      unless @receiver?

    optimizer = new Pegex.Optimizer
      parser: @
      grammar: @grammar
      receiver: @receiver

    optimizer.optimize_grammar start_rule_ref

    # Add circular ref.
    @receiver.parser = @

    if @receiver.initial?
      @rule = start_rule_ref
      @parent = {}
      @receiver.initial()

    # TODO Make start_method in optimizer?
    if @debug
      match = optimizer.make_trace_wrapper(@match_ref)
        .call @, start_rule_ref, '+asr': off
    else
      match = @match_ref start_rule_ref, {}

    @input.close()

    if not match or @position < @buffer.length
      @throw_error "Parse document failed for some reason"
      return;  # In case @throw_on_error is off

    if @receiver.final
      @rule = start_rule_ref
      @parent = {}
      match = [ @receiver.final(match...) ]

    match[0]

  match_next: (next)->
    # XXX say "match_next #{next}"
    {rule, method, kind} = next
    min = next['+min']
    max = next['+max']
    assertion = next['+asr']

    position = @position
    match = []
    count = 0

    while return_ = method.call @, rule, next
      position = @position unless assertion
      count++
      match.push return_...
      break if max == 1
    if not count and min == 0 and kind == 'all'
      match = [[]]
    if max != 1
      if next['-flat']
        _match = []
        for m in match
          if m instanceof Array
            _match.push m...
          else
            _match.push m
        match = _match
      else
        match = [match]
    result = (count >= min and (not max or count <= max))
    result ^= (assertion == -1)
    if not result or assertion
      @farthest = position \
        if (@position = position) > @farthest

    if result
      if next['-skip']
        return []
      else
        return match
    else
      return 0

  match_rule: (position, match=[])->
    @farthest = position \
      if (@position = position) > @farthest
    match = [ match ] if match.length > 1
    {ref, parent} = @
    rule = @grammar.tree[ref] \
      or throw "No rule defined for '#{ref}'"

    [ rule.action.call(@receiver, match...) ]

  match_ref: (ref, parent)->
    # XXX say "match_ref #{ref}"
    @ref1 = ref
    rule = @grammar.tree[ref] or throw "No rule defined for '#{ref}'"
    match = @match_next(rule)
    return unless match
    return Pegex.Constant.Dummy unless rule.action?
    @rule = ref
    @parent = parent

    # XXX Possible API mismatch.
    # Not sure if we should "splat" the $match.
    [ rule.action.call @receiver, match... ]

  match_rgx: (regexp)->
    # XXX say "match_rgx #{@ref1} #{regexp} '#{@buffer.substr(@position)}'"
    re = new RegExp("^#{regexp}", 'g')
    m = re.exec @buffer.substr(@position)
    return unless m?

    @position += re.lastIndex
    @farthest = @position if @position > @farthest

    captures = []
    for num in [1...(m.length)]
      captures.push(m[num] || '')
    captures = [ captures ] if m.length > 2
    return captures

  match_all: (list)->
    position = @position
    set = []
    len = 0
    for elem in list
      if match = @match_next elem
        if not(elem['+asr'] or elem['-skip'])
          set.push match...
          len++
      else
        @farthest = position \
          if (@position = position) > @farthest
        return
    set = [ set ] if len > 1
    return set

  match_any: (list)->
    for elem in list
      if match = @match_next elem
        return match
    return null

  match_err: (error)->
    @throw_error error

  match_code: (code)->
    method = "match_rule_#{code}"
    method.call @

  trace: (action)->
    indent = action.match /^try_/
    @indent ||= 1
    @indent-- unless indent
    i1 = i2 = ''
    i1 += ' ' for x in [0..@indent]
    i2 += ' ' for x in [1..(30 - action.length)]
    @indent++ if indent
    snippet = @buffer.substr @position
    snippet = snippet.substr 0, 30 if snippet.length > 30
    snippet = snippet.replace /\n/g, '\\n'
    console.warn "#{i1} #{action}#{i2}>#{snippet}<"

  throw_error: (msg)->
    @format_error msg
    return 0 unless @throw_on_error
    throw @error

  format_error: (msg)->
    position = @farthest
    lines = (@buffer.substr 0, position).match /\n/g
    line = if lines? then lines.length + 1 else 1
    column = position - @buffer.lastIndexOf "\n", position
    context = @buffer.substr position, 50
    context = context.replace /\n/g, '\\n'
    @error = """
Error parsing Pegex document:
  msg: #{msg}
  line: #{line}
  column: #{column}
  context: #{context}
  position: #{position}
"""
