url = require 'url'
parsers= require('../parser')

providerIdMatch =(parserId,providerId)->
  providerId.indexOf(parserId, providerId.length - parserId.length) isnt -1

class Lastfeed
  constructor: (@config) ->
    @config.isStop=false

    @providerId = url.parse(@config.url).host
    @feedId= @config.url.replace(/^http:\/\//,'').replace(/[\/|\.]/g,'-')
    @feedCacheKey="feed:cache:#{@feedId}"
    @feedRawKey="feed:raw:#{@feedId}"
    @feedConfigKey="config:#{@feedId}"


    @parser = null
    for parser in parsers
      if providerIdMatch(parser.id,@providerId)
        @parser= parser
        break

    if parser is null
      throw new Error("Cant found parser for #{@providerId}")
    # console.log @parser

  stop:()->
    @config.isStop=true
    console.log "set stop: #{@config.url}"

module.exports=Lastfeed

