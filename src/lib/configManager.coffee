co = require 'co'
redis= require('redis')
client = redis.createClient()
monitor = redis.createClient()


class ConfigManager
  constructor: (@onKeyAdded,@onKeyRemoved)->

  getAllKeys:()->
    new Promise (resolve,reject)->
      client.keys 'config:*',(err,replies)->
        if err?
          reject new LastError("redis:error get config:*",null,err)
        else
          resolve replies

  getByKey:(key)->
    new Promise (resolve,reject)->
      client.get key,(err,reply)->
        if err?
          reject err
        else
          try
            config=JSON.parse(reply)
            resolve config
          catch e
            reject new LastError("JSON.parse():failed parsing #{key}",reply,e)


  getAll:()->
    keys=yield @getAllKeys()

    configs=[]
    for k in keys
      configs.push yield @getByKey(k)

    return configs

  monitor:()->

    # monitor
    monitor.psubscribe '*:config:*'
    monitor.on 'pmessage', (pattern, channel, message) =>

      if message not in ['del','set']
        return

      matchs=channel.match(/\:(\S+)/)
      if matchs.length isnt 2
        console.log "error on match"
        return

      key=matchs[1]
      if message is 'del'
        if @onKeyRemoved?
          @onKeyRemoved(key)


      else if message is 'set'
        console.log "sdt"

        co ()=>
          config=yield @getByKey(key)
          if @onKeyAdded?
            @onKeyAdded(config)

module.exports=ConfigManager
