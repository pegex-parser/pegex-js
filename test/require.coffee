modules = [
  'Pegex'
  'Pegex/Compiler'
  'Pegex/Grammar'
  'Pegex/Input'
  'Pegex/Module'
  'Pegex/Optimizer'
  'Pegex/Parser'
  'Pegex/Receiver'
  'Pegex/Tree'
  'Pegex/Tree/Wrap'
  'Pegex/Grammar/Atoms'
  'Pegex/Parser/Indent'
  'Pegex/Pegex/AST'
  'Pegex/Pegex/Grammar'
]

for module in modules
  test "Can require #{module}", ->
    ok require "../lib/#{module}"
