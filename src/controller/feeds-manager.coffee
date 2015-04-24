parse = require 'co-body'

wrapper= require 'co-redis'
client = wrapper(require('redis').createClient())

views = require 'co-views'
fs= require 'mz/fs'

Lastfeed= require('../lib/lastfeed')

validator = require 'validator'


# getFeedByProviderId=(pid)->
#   new Promise (resolve,reject)->
#     pid = "feed:cache:#{pid}"
#     client.get pid,(err,reply)->
#       if err?
#         reject err
#       else
#         if reply?
#           try
#             feed = JSON.parse(reply)
#             resolve feed
#           catch e
#             reject e
#         else
#           reject new Error("Unexpected pid: #{pid}")

getFeedByFeedId=(fid)->
  fid="feed:cache:#{fid}"
  value=yield client.get(fid)

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
  config.disabled=false

  lf=new Lastfeed(config)

  # console.log lf.getProviderId

  client.set lf.feedConfigKey,JSON.stringify(config)

  console.log "set config done"
  @body=lf.feedId


module.exports.get = (fid,next)->
  yield next if 'GET' isnt @method

  # console.log "provider id:#{fid}"

  feed = yield getFeedByFeedId(fid)

  if feed is null
    @response.status = 404
    @body = {error:"feed not found."}
    return yield next

  # console.log "render feed"
  # console.log feed

  @response.type='application/rss+xml'
  @body = yield render('ameblo',feed)







