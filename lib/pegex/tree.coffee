require '../pegex/receiver'

class Pegex.Tree extends Pegex.Receiver

  gotrule: (got)->
    return if got == undefined

    return "#{@parser.rule}": got \
      if @parser.parent['-wrap']

    return got

  final: (got)->
    return got if got != undefined

    return []
