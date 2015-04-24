request = require 'request'
Agent= require 'socks5-http-client/lib/Agent'

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
      feedKey=lastfeed.feedRawKey

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

      # options=
      #   url:url
      #   agentClass: Agent
      #   agentOptions:
      #     socksHost: '127.0.0.1'
      #     socksPort: 8787

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



# promiseGetArticle=(url)->
#   new Promise (resolve,reject)->
#     console.log "request article: #{url}"

#     options=
#       url:url
#       agentClass: Agent
#       agentOptions:
#         socksHost: '127.0.0.1'
#         socksPort: 8787

#     request options,(err,resp)->
#       if err?
#         reject err
#       else if resp.statusCode isnt 200
#         reject new Error("error on request: #{resp.statusCode}")
#       else
#         resolve resp





completeFeedPosts=(lastfeed)->

  for article in lastfeed.feed.articles

    postUrl=article.link
    console.log postUrl

    # options=
    #   url:postUrl
    #   agentClass: Agent
    #   agentOptions:
    #     socksHost: '127.0.0.1'
    #     socksPort: 8787

    # console.log "try get article"
    resp=yield coreq(postUrl)

    # resp=yield promiseGetArticle(postUrl)

    # console.log resp

    # parser=getParserByProviderId(lastfeed.providerId)
    # console.log "provider Id: #{lastfeed.providerId}"
    # console.log "parser"
    # console.log parser

    postText = lastfeed.parser.parse(resp.body)
    # fs.writeFileSync "./posttext.html",postText
    article.description=postText

  feedCacheString=JSON.stringify(lastfeed.feed)
  setCachedFeed(lastfeed.feedCacheKey,feedCacheString)
  fs.writeFileSync "./posttext.html",feedCacheString


lastfeedTask=(lastfeed)->

  value = yield checkFeedUpdates(lastfeed)
  lastfeed.feed=value.feed
  lastfeed.feedUpdated=value.feedUpdated


  rawFeedText=JSON.stringify(lastfeed.feed)

  console.log "feed updated: #{lastfeed.feedUpdated}"


  if lastfeed.feedUpdated

    value= yield completeFeedPosts(lastfeed)
    setCachedFeed(lastfeed.feedRawKey,rawFeedText)
    console.log "completeFeedPosts"

  return lastfeed


subTask = (lastfeed)->
  co ()->
    while true

      console.log ""
      console.log "task: #{lastfeed.feedId}"
      console.log "parser: #{lastfeed.parser.id}"

      yield lastfeedTask(lastfeed)

      console.log "sleep #{lastfeed.config.interval}: #{lastfeed.feedId}"
      yield sleep(lastfeed.config.interval)

  .then (c)->
    console.log "sub then"

  .catch (err)->
    console.log err





co ()->
  # main task
  configs = yield loadConfiguation()

  # init configs
  for c in configs
    # console.log configs
    lastfeed= new Lastfeed(c)
    subTask(lastfeed)

.then (c)->
  console.log "main then"

.catch (err)->
  console.log err
