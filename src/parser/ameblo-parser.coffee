cheerio= require 'cheerio'

module.exports.parse=(html)->
  cheerioOptions=
    normalizeWhitespace: false,
    xmlMode: false,
    decodeEntities: false

  $=cheerio.load(html,cheerioOptions)
  post = $('.articleText').html()
  return post

module.exports.id='ameba.jp'
