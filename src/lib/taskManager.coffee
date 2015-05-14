co = require 'co'
sleep= require 'co-sleep'

Lastfeed= require('./lastfeed')

ConfigManager=require('./configManager')

FeedManager=require('./feedManager')
feedManager=new FeedManager()

taskPool={}
class TaskManager

  constructor: () ->

    configManager = new ConfigManager(@addTask,@removeTask)

    co ()=>
      configs = yield configManager.getAll()
      for c in configs
        @addTask(c)

    .then (c)->
      console.log "main then"

    .catch (err)->
      console.log "main catch"
      console.log err

    configManager.monitor()

  lastfeedTask:(lastfeed)->

    value = yield feedManager.checkFeedUpdates(lastfeed)
    lastfeed.feed=value.feed
    lastfeed.feedUpdated=value.feedUpdated

    rawFeedText=JSON.stringify(lastfeed.feed)
    console.log "feed updated: #{lastfeed.feedUpdated}"

    if lastfeed.feedUpdated

      value= yield feedManager.completeFeedPosts(lastfeed)
      feedManager.setCachedFeed(lastfeed.feedCacheKey,value)
      feedManager.setCachedFeed(lastfeed.feedRawKey,rawFeedText)
      console.log "completeFeedPosts"

    return lastfeed

  # should private
  doTask:(lastfeed)->

    co ()=>
      until lastfeed.config.isStop

        yield @lastfeedTask(lastfeed)
        console.log "sleep #{lastfeed.config.interval}: #{lastfeed.feedId}"
        yield sleep(lastfeed.config.interval)

      console.log "task stopped: #{lastfeed.config.url}"
      return "redis: user canceled task"

    .then (c)->
      console.log "sub then"
      console.log c

    .catch (err)->
      console.log "sub err"
      console.log err

  addTask:(taskConfig)=>
    console.log "addTask"
    # console.log taskConfig
    # console.log "sdf "
    # console.log taskPool
    lastfeed= new Lastfeed(taskConfig)

    taskPool[lastfeed.feedConfigKey]=lastfeed
    # console.log taskPool
    @doTask(lastfeed)

  removeTask:(key)->

    if taskPool[key]?
      taskPool[key].stop()
      taskPool[key]=null

module.exports=TaskManager
