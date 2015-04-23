cheerio= require 'cheerio'

module.exports.parse=(html)->
  cheerioOptions=
    normalizeWhitespace: false,
    xmlMode: false,
    decodeEntities: false

  $=cheerio.load(html,cheerioOptions)
  post = $('#main').html()
  return post
