request = require 'request'
FeedParser = require 'feedparser'
co = require 'co'

fs=require 'mz/fs'
coreq=require 'co-request'

cheerio= require 'cheerio'


redis= require('redis')
client = redis.createClient()
monitor = redis.createClient()

Lastfeed= require('./lib/lastfeed')

parser= require('./parser')



# global variable
configs=null


# monitor
monitor.psubscribe '*config:*'
monitor.on 'pmessage', (pattern, channel, message) ->
  if message not in ['del','set']
    return

  console.log message
  console.log channel
  console.log configs








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
  console.log "caching..."

  console.log cacheKey

  client.set cacheKey,feedText

checkFeedUpdates=(lastfeed)->



  promiseGetCachedRawFeed=(lastfeed)->
    new Promise (resolve,reject)->
      console.log "111"
      console.log lastfeed
      feedKey=lastfeed.getFeedRawKey()
      console.log feedKey

      client.get feedKey,(err,reply)->
        if err?
          console.log err
          reject err
        else
          resolve reply

  promiseGetFeed=(lastfeed)->
    new Promise (resolve,reject)->
      console.log "1"
      url=lastfeed.config.url
      req=request(url)
      feedparser=new FeedParser()

      console.log "2"
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

      console.log "3"


  feed=yield promiseGetFeed(lastfeed)
  console.log 5

  feedText=JSON.stringify(feed)
  console.log "12"
  cachedFeedText=yield promiseGetCachedRawFeed(lastfeed)

  console.log 6
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

  console.log "cache feed"
  feedCacheString=JSON.stringify(lastfeed.feed)
  # console.log feedCacheString
  setCachedFeed(lastfeed.getFeedCacheKey(),feedCacheString)


  console.log "cached"


lastfeedTask=(lastfeed)->

  value = yield checkFeedUpdates(lastfeed)
  # console.log value
  lastfeed.feed=value.feed
  lastfeed.rawfeed=value.feed
  lastfeed.feedUpdated=value.feedUpdated



  # console.log lastfeed.feed

  if lastfeed.feedUpdated
    console.log "try cache to file"
    value= yield completeFeedPosts(lastfeed)

    console.log "set raw cache"
    feedText=JSON.stringify(lastfeed.rawfeed)
    setCachedFeed(lastfeed.getFeedRawKey(),feedText)

    console.log "completeFeedPosts: #{value}"

  return lastfeed



co ()->
  # init

  configs = yield loadConfiguation()

  # lastfeeds=[]
  # for c in configs
  #   lastfeeds.push new Lastfeed(c)

  lastfeed=new Lastfeed(configs[0])

  lastfeed = yield lastfeedTask(lastfeed)

  return lastfeed

.then (lastfeed)->
  # parse feed
  console.log "fin"
  console.log "feedUpdated: #{lastfeed}"
  client.end()


,(error)->
  console.log error
  console.log "error on parse fedd"
