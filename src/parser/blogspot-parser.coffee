cheerio= require 'cheerio'

module.exports.parse=(html)->
  cheerioOptions=
    normalizeWhitespace: false,
    xmlMode: false,
    decodeEntities: false

  $=cheerio.load(html,cheerioOptions)
  target = $('.post-body')
  target.children().last().remove()

  post=target.html()
  return post

module.exports.id='blogspot.com'
