require '../../Pegex/Receiver'
require '../../Pegex/Tree'

class Pegex.Tree.Wrap extends Pegex.Receiver

  gotrule: (got)->
    if not got?
      return Pegex.Constant.Dummy
    else
      result = {}
      result[@parser.rule] = got
      result

  final: (got)->
    if got?
      got
    else
      result = {}
      result[@parser.rule] = []
      result
