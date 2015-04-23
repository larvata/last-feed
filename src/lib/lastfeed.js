// Generated by CoffeeScript 1.9.1
var Lastfeed;

Lastfeed = (function() {
  function Lastfeed(config) {
    this.config = config;
  }

  Lastfeed.prototype.getConfigKey = function() {
    return "config:" + this.config.id;
  };

  Lastfeed.prototype.getFeedCacheKey = function() {
    return "feed:cache:" + this.config.id;
  };

  Lastfeed.prototype.getFeedRawKey = function() {
    return "feed:raw:" + this.config.id;
  };

  return Lastfeed;

})();

module.exports = Lastfeed;