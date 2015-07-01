cheerio= require 'cheerio'

module.exports.parse=(html)->
  cheerioOptions=
    normalizeWhitespace: false,
    xmlMode: false,
    decodeEntities: false

  $=cheerio.load(html,cheerioOptions)
  post = $('.post-content').html()
  return post

module.exports.id='2chcn.com'
