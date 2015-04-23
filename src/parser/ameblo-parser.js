// Generated by CoffeeScript 1.9.1
var cheerio;

cheerio = require('cheerio');

module.exports.parse = function(html) {
  var $, cheerioOptions, post;
  cheerioOptions = {
    normalizeWhitespace: false,
    xmlMode: false,
    decodeEntities: false
  };
  $ = cheerio.load(html, cheerioOptions);
  post = $('#main').html();
  return post;
};
