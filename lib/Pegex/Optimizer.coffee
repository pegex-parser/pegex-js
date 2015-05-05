class Pegex.Optimizer
  constructor: ({@parser, @grammar, @receiver})->
    @parser? or
      throw "Missing attribute 'parser' for Pegex.Optimizer"
    @grammar? or
      throw "Missing attribute 'grammar' for Pegex.Optimizer"
    @receiver? or
      throw "Missing attribute 'receiver' for Pegex.Optimizer"

  optimize_grammar: (start)->
    tree = @grammar.tree
    return if tree['+optimized']
    @set_max_parse if @parser.maxparse?
    @extra = {}
    for name, node of tree
      continue if typeof node is String
      @optimize_node node
    @optimize_node '.ref': start
    extra = delete @extra
    for key, val of extra
      tree[key] = val
    tree['+optimized'] = 1

  optimize_node: (node)->
    min = node['+min']
    max = node['+max']
    node['+min'] ?= if max? then 0 else 1
    node['+max'] ?= if min? then 0 else 1
    node['+asr'] ?= 0

    for kind in ['ref', 'rgx', 'all', 'any', 'err', 'code', 'xxx']
      return if kind == 'xxx'
      if node.rule = node[".#{kind}"]
        delete node[".#{kind}"]
        node.kind = kind
        if kind == 'ref'
          rule = node.rule or throw ""
          if method = @grammar["rule_#{rule}"]?
            console.log node
            node.method = @make_method_wrapper method
          else if not @grammar.tree[rule]?
            if method = @grammar[rule]?
              console.warn """
Warning:

  You have a method called '#{rule}' in your grammar.
  It should probably be called 'rule_#{rule}'.

"""
            throw "No rule '#{rule}' defined in grammar"
        node.method ?= @parser["match_#{kind}"] or throw ""
        break

    if node.kind.match /^(?:all|any)$/
      for n in node.rule
        @optimize_node n
    else if node.kind == 'ref'
      ref = node.rule
      rule = @grammar.tree[ref]
      rule ||= @extra[ref] = {}
      if action = @receiver["got_#{ref}"]
        rule.action = action
      else if gotrule = @receiver.gotrule
        rule.action = gotrule
      if @parser.debug
        node.method = @make_trace_wrapper node.method
    else if node.kind == 'rgx'
      # TODO Add ^ and compile re here
      0
      # xxx node

  make_method_wrapper: (method)->
    return (parser, ref, parent)->
      parser.rule = ref
      parser.parent = parent
      method.call(
        parser.grammar,
        parser,
        parser.buffer,
        parser.position,
      )

  make_trace_wrapper: (method)->
    return (ref, parent)->
      asr = parent['+asr']
      note = \
        if asr == -1 then '(!)' else \
        if asr == 1 then '(=)' else \
        ''
      @trace "try_#{ref}#{note}"
      if result = method.call @, ref, parent
        @trace "got_#{ref}#{note}"
      else
        @trace "not_#{ref}#{note}"
      return result

  set_max_parse: ->
    require '../Pegex/Parser'
    maxparse = @parser.maxparse
    method = Pegex.Parser.match_ref
    counter = 0
    Pegex.Parser.match_ref = (args...)->
      throw "Maximum parsing rules reached (#{maxparse})\n" \
        if counter++ >= maxparse
      method.apply @, args...
