// Generated by CoffeeScript 1.9.1
var cheerio;

cheerio = require('cheerio');

module.exports.parse = function(html) {
  var $, cheerioOptions, post, target;
  cheerioOptions = {
    normalizeWhitespace: false,
    xmlMode: false,
    decodeEntities: false
  };
  $ = cheerio.load(html, cheerioOptions);
  target = $('.post-body');
  target.children().last().remove();
  post = target.html();
  return post;
};

module.exports.id = 'blogspot.com';