
class Lastfeed
  constructor: (@config) ->


  getConfigKey:()->

    "config:#{@config.id}"

  getFeedCacheKey:()->

    "feed:cache:#{@config.id}"


  getFeedRawKey:()->

    # "feed:raw:#{@config.id}"
    # console.log "1212sss"
    # console.log "feed:raw:#{@config.id}"
    "feed:raw:#{@config.id}"

  # task:null

  # startTask:()->


  # updateConfig:(@config)->



module.exports=Lastfeed

