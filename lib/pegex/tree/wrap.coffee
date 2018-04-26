require '../../pegex/receiver'
require '../../pegex/tree'

class Pegex.Tree.Wrap extends Pegex.Receiver

  gotrule: (got)->
    return if got == undefined

    return "#{@parser.rule}": got

  final: (got)->
    return got if got != undefined

    return "#{@parser.rule}": []
