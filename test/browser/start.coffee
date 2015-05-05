$ ->
  $('button').click ->
    alert JSON.stringify global.exports.pegex('a: /(b)/').parse('b')
