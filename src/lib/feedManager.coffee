request = require 'request'
coreq= require 'co-request'
FeedParser = require 'feedparser'

co = require 'co'
redis= require('redis')
client = redis.createClient()

LastError=require('./lastError')




class FeedManager
  constructor: ()->

  setCachedFeed:(cacheKey,feedText)->
    console.log "caching: #{cacheKey}"
    client.set cacheKey,feedText


  checkFeedUpdates:(lastfeed)->
    promiseGetCachedRawFeed=(lastfeed)->
      new Promise (resolve,reject)->
        feedKey=lastfeed.feedRawKey

        client.get feedKey,(err,reply)->
          if err?
            console.log err
            reject new LastError("redis:error get feedRawKey",feedKey ,err)
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
          reject new LastError("request:error",null,error)

        req.on 'response',(resp)->
          if resp.statusCode isnt 200
            @emit 'error', new LastError("request:bad response status code",resp.statusCode)
          @pipe feedparser

        feedparser.on 'error',(error)->
          reject new LastError("feedparser:error",null,error)

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

    if cachedFeedText is feedText
      feedUpdated=false
    else
      feedUpdated=true
    return {
      feed
      feedUpdated
    }


  completeFeedPosts:(lastfeed)->


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

      postText = lastfeed.parser.parse(resp.body)
      article.description=postText

    return JSON.stringify(lastfeed.feed)

    # console.log @
    # setCachedFeed(lastfeed.feedCacheKey,feedCacheString)
    # fs.writeFileSync "./posttext.html",feedCacheString


module.exports=FeedManager
