// Generated by CoffeeScript 1.9.3
var ConfigManager, Lastfeed, client, configManager, fs, getFeedByFeedId, parse, render, validator, views, wrapper;

parse = require('co-body');

wrapper = require('co-redis');

client = wrapper(require('redis').createClient());

views = require('co-views');

fs = require('mz/fs');

Lastfeed = require('../lib/lastfeed');

ConfigManager = require('../lib/configManager');

configManager = new ConfigManager();

validator = require('validator');

getFeedByFeedId = function*(fid) {
  var e, feed, value;
  fid = "feed:cache:" + fid;
  value = (yield client.get(fid));
  try {
    feed = JSON.parse(value);
    return feed;
  } catch (_error) {
    e = _error;
    throw new Error("failed parse feed");
  }
};

render = views(__dirname + '/../feedTemplate/', {
  "default": 'jade'
});

module.exports.add = function*(next) {
  var config, lf;
  if ('POST' !== this.method) {
    (yield next);
  }
  config = (yield parse.form(this));
  if (!validator.isURL(config.url)) {
    this.response.status = 422;
    this.body = {
      error: "feed url is invalid."
    };
    return (yield next);
  }
  config.interval = 28800 * 1000;
  config.disabled = false;
  lf = new Lastfeed(config);
  client.set(lf.feedConfigKey, JSON.stringify(config));
  console.log("set config done");
  return this.body = lf.feedId;
};

module.exports.get = function*(fid, next) {
  var feed;
  if ('GET' !== this.method) {
    (yield next);
  }
  feed = (yield getFeedByFeedId(fid));
  if (feed === null) {
    this.response.status = 404;
    this.body = {
      error: "feed not found."
    };
    return (yield next);
  }
  this.response.type = 'application/rss+xml';
  return this.body = (yield render('ameblo', feed));
};

module.exports.getAll = function*() {
  var configs, lastfeeds;
  if ('GET' !== this.method) {
    (yield next);
  }
  configs = (yield configManager.getAll());
  lastfeeds = configs.map(function(c) {
    return new Lastfeed(c);
  });
  return this.body = lastfeeds;
};
