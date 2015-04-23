request = require 'request'
FeedParser = require 'feedparser'
co = require 'co'

fs=require 'mz/fs'
coreq=require 'co-request'

cheerio= require 'cheerio'

sleep= require 'co-sleep'
redis= require('redis')
client = redis.createClient()
monitor = redis.createClient()

Lastfeed= require('./lib/lastfeed')

parser= require('./parser')



# global variable
# configs=null


# monitor
# monitor.psubscribe '*config:*'
# monitor.on 'pmessage', (pattern, channel, message) ->
#   if message not in ['del','set']
#     return

#   console.log message
#   console.log channel
#   console.log configs








loadConfiguation=()->

  getAllConfigKeys=()->
      new Promise (resolve,reject)->
        client.keys 'config:*',(err,replies)->
          if err?
            reject err
          else
            resolve replies

  getConfigByKey=(key)->
    new Promise (resolve,reject)->
      client.get key,(err,reply)->
        if err?
          reject err
        else
          try
            config=JSON.parse(reply)
            resolve config
          catch e
            reject e

  keys=yield getAllConfigKeys()

  configs=[]
  for k in keys
    configs.push yield getConfigByKey(k)

  return configs

setCachedFeed=(cacheKey,feedText)->
  console.log "caching: #{cacheKey}"
  client.set cacheKey,feedText

checkFeedUpdates=(lastfeed)->



  promiseGetCachedRawFeed=(lastfeed)->
    new Promise (resolve,reject)->
      feedKey=lastfeed.getFeedRawKey()

      client.get feedKey,(err,reply)->
        if err?
          console.log err
          reject err
        else
          resolve reply

  promiseGetFeed=(lastfeed)->
    new Promise (resolve,reject)->

      url=lastfeed.config.url

      console.log "request feed: #{url}"
      req=request(url)
      feedparser=new FeedParser()

      feed={}
      feed.meta=null
      feed.articles=[]

      req.on 'error',(error)->
        reject error

      req.on 'response',(resp)->
        if resp.statusCode isnt 200
          @emit 'error', new Error('Bad status code')
        @pipe feedparser

      feedparser.on 'error',(error)->
        reject error

      feedparser.on 'readable',()->
        while post=@read()
          feed.articles.push post


      feedparser.on 'meta',(meta)->
        feed.meta=meta

      feedparser.on 'end',()->
        resolve feed


  feed=yield promiseGetFeed(lastfeed)

  feedText=JSON.stringify(feed)
  cachedFeedText=yield promiseGetCachedRawFeed(lastfeed)


  fs.writeFileSync './cached.json',cachedFeedText

  fs.writeFileSync './response.json',feedText
  if cachedFeedText is feedText
    feedUpdated=false
  else
    feedUpdated=true
  return {
    feed
    feedUpdated
  }


completeFeedPosts=(lastfeed)->
  for article in lastfeed.feed.articles

    postUrl=article.link
    console.log postUrl

    resp=yield coreq(postUrl)

    postText = parser.ameblo.parse(resp.body)
    article.description=postText

  feedCacheString=JSON.stringify(lastfeed.feed)
  setCachedFeed(lastfeed.getFeedCacheKey(),feedCacheString)


lastfeedTask=(lastfeed)->

  value = yield checkFeedUpdates(lastfeed)
  lastfeed.feed=value.feed
  lastfeed.feedUpdated=value.feedUpdated


  rawFeedText=JSON.stringify(lastfeed.feed)

  console.log "feed updated: #{lastfeed.feedUpdated}"


  if lastfeed.feedUpdated

    value= yield completeFeedPosts(lastfeed)
    setCachedFeed(lastfeed.getFeedRawKey(),rawFeedText)
    console.log "completeFeedPosts"

  return lastfeed


subTask = (lastfeed)->
  co ()->
    while true

      console.log "task: #{lastfeed.config.id}"
      yield lastfeedTask(lastfeed)

      console.log "sleep 5s"
      yield sleep(5000)

  .then (c)->
    console.log "then"





co ()->
  # main task
  configs = yield loadConfiguation()

  # init configs
  for c in configs
    # console.log configs
    lastfeed= new Lastfeed(c)
    subTask(lastfeed)
