// Generated by CoffeeScript 1.9.3
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
  post = $('.post-content').html();
  return post;
};

module.exports.id = '2chcn.com';
