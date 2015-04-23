parse = require 'co-body'
client = require('redis').createClient()

views = require 'co-views'
fs= require 'mz/fs'

Lastfeed= require('../lib/lastfeed')


getFeedByProviderId=(pid)->
  new Promise (resolve,reject)->
    pid = "feed:cache:#{pid}"
    client.get pid,(err,reply)->
      if err?
        reject err
      else
        if reply?
          try
            feed = JSON.parse(reply)
            resolve feed
          catch e
            reject e
        else
          reject new Error("Unexpected pid: #{pid}")


render= views(__dirname+'/../feedTemplate/',{
  default: 'jade'
})


module.exports.add = (next)->
  yield next if 'POST' isnt @method

  config = yield parse.form(@)
  config.id=config.url.replace(/^http:\/\//,'').replace(/[\/|\.]/g,'-')

  lf=new Lastfeed(config)

  client.set lf.getConfigKey(),JSON.stringify(config)

  console.log "set config done"
  @body=lf.getConfigKey()


module.exports.get = (pid,next)->
  yield next if 'GET' isnt @method

  console.log "provider id:#{pid}"

  feed = yield getFeedByProviderId(pid)

  @response.type='application/rss+xml'
  @body = yield render('ameblo',feed)







