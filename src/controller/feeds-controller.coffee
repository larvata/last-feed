parse = require 'co-body'

wrapper= require 'co-redis'
client = wrapper(require('redis').createClient())

views = require 'co-views'
fs= require 'mz/fs'

Lastfeed= require('../lib/lastfeed')

ConfigManager= require('../lib/configManager')
configManager=new ConfigManager()

validator = require 'validator'

getFeedByFeedId=(fid)->
  fid="feed:cache:#{fid}"
  value=yield client.get(fid)
  # console.log fid
  # console.log value

  try
    feed= JSON.parse(value)
    return feed
  catch e
    throw new Error("failed parse feed")


render= views(__dirname+'/../feedTemplate/',{
  default: 'jade'
})


module.exports.add = (next)->
  yield next if 'POST' isnt @method

  config = yield parse.form(@)
  # config.id=config.url.replace(/^http:\/\//,'').replace(/[\/|\.]/g,'-')

  if not validator.isURL(config.url)
    # Unprocessable Entity
    @response.status=422
    @body = {error:"feed url is invalid."}
    return yield next

  # init config
  config.interval=28800*1000
  config.interval=60000
  config.disabled=false

  lf=new Lastfeed(config)

  client.set lf.feedConfigKey,JSON.stringify(config)

  console.log "set config done"
  @body=lf.feedId


module.exports.get = (fid,next)->
  yield next if 'GET' isnt @method

  feed = yield getFeedByFeedId(fid)

  if feed is null
    @response.status = 404
    @body = {error:"feed not found."}
    return yield next

  @response.type='application/rss+xml'
  @body = yield render('ameblo',feed)


module.exports.getAll = ()->
  yield next if 'GET' isnt @method

  configs = yield configManager.getAll()

  lastfeeds= configs.map (c)->
    return new Lastfeed(c)

  @body=lastfeeds


