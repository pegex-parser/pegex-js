require '../Pegex/Receiver'

class Pegex.Tree extends Pegex.Receiver

  gotrule: (got)->
    if not got?
      ''  #XXX () in Perl
    else if @parser.parent['-wrap']
      result = {}
      result[@parser.rule] = got
      result
    else
      got

  final: (got)->
    if got?
      got
    else
      []
