// Generated by CoffeeScript 1.9.1
var ConfigManager, FeedManager, Lastfeed, TaskManager, co, feedManager, sleep, taskPool,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

co = require('co');

sleep = require('co-sleep');

Lastfeed = require('./lastfeed');

ConfigManager = require('./configManager');

FeedManager = require('./FeedManager');

feedManager = new FeedManager();

taskPool = {};

TaskManager = (function() {
  function TaskManager() {
    this.addTask = bind(this.addTask, this);
    var configManager;
    configManager = new ConfigManager(this.addTask, this.removeTask);
    co((function(_this) {
      return function*() {
        var c, configs, i, len, results;
        configs = (yield configManager.getAll());
        results = [];
        for (i = 0, len = configs.length; i < len; i++) {
          c = configs[i];
          results.push(_this.addTask(c));
        }
        return results;
      };
    })(this)).then(function(c) {
      return console.log("main then");
    })["catch"](function(err) {
      console.log("main catch");
      return console.log(err);
    });
    configManager.monitor();
  }

  TaskManager.prototype.lastfeedTask = function*(lastfeed) {
    var rawFeedText, value;
    value = (yield feedManager.checkFeedUpdates(lastfeed));
    lastfeed.feed = value.feed;
    lastfeed.feedUpdated = value.feedUpdated;
    rawFeedText = JSON.stringify(lastfeed.feed);
    console.log("feed updated: " + lastfeed.feedUpdated);
    if (lastfeed.feedUpdated) {
      value = (yield feedManager.completeFeedPosts(lastfeed));
      feedManager.setCachedFeed(lastfeed.feedCacheKey, value);
      feedManager.setCachedFeed(lastfeed.feedRawKey, rawFeedText);
      console.log("completeFeedPosts");
    }
    return lastfeed;
  };

  TaskManager.prototype.doTask = function(lastfeed) {
    return co((function(_this) {
      return function*() {
        while (!lastfeed.config.isStop) {
          (yield _this.lastfeedTask(lastfeed));
          console.log("sleep " + lastfeed.config.interval + ": " + lastfeed.feedId);
          (yield sleep(lastfeed.config.interval));
        }
        console.log("task stopped: " + lastfeed.config.url);
        return "redis: user canceled task";
      };
    })(this)).then(function(c) {
      console.log("sub then");
      return console.log(c);
    })["catch"](function(err) {
      console.log("sub err");
      return console.log(err);
    });
  };

  TaskManager.prototype.addTask = function(taskConfig) {
    var lastfeed;
    console.log("addTask");
    lastfeed = new Lastfeed(taskConfig);
    taskPool[lastfeed.feedConfigKey] = lastfeed;
    return this.doTask(lastfeed);
  };

  TaskManager.prototype.removeTask = function(key) {
    if (taskPool[key] != null) {
      taskPool[key].stop();
      return taskPool[key] = null;
    }
  };

  return TaskManager;

})();

module.exports = TaskManager;
