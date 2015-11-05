redis = require 'redis'
config = require 'config'
cron = require 'node-crontab'
{client, routes, hosts} = {}

reloadData = ->
  client.hgetall "routes", (err, obj) ->
    if err or not obj
      console.log "error loading data from redis: error: #{err}, obj: #{JSON.stringify(obj)} "
    else
      res = []
      for k,v of obj
        try
          json = JSON.parse(v)
          json.route = k
          res.push json
        catch e
          console.log 'error parsing: ' + k
      routes = res


  client.hgetall "hosts", (err, obj) ->
    if err or not obj
      console.log "error loading data from redis: error: #{err}, obj: #{JSON.stringify(obj)} "
    else
      res = {}
      for k,v of obj
        try
          json = JSON.parse(v)
          json.id = k
          if not res[json.name]?
            res[json.name] = []
          res[json.name].push json
        catch e
          console.log 'error parsing: ' + k
      hosts = res

module.exports =
  init: ->
    if not config.has('backend.redis.host') or not config.has('backend.redis.port')
      throw 'redis backend mis-configured'

    client = redis.createClient
      host: config.get 'backend.redis.host'
      port: config.get 'backend.redis.port'

    client.on "error", (err) ->
      console.log "Redis client error: #{err}"

    reloadData()
    cron.scheduleJob '*/30 * * * * *', reloadData

  getRoutes: ->
    Promise.resolve(routes)

  putRoute: (id, route) ->
    new Promise ->
      client.hset "routes", id, route, (err, res) ->
        if(err?)
          Promise.reject new Error("could not put route #{id}: #{err}")
        else
          Promise.resolve

  deleteRoute: (id) ->
    client.hdel "routes", id, (err, res) ->
      if(err?)
        Promise.reject new Error("could not delete route #{id}: #{err}")
      else
        Promise.resolve

  getServices: ->
    Promise.resolve(hosts)

  putHost: (id, host) ->
    client.hset "hosts", id, host, (err, res) ->
      if(err?)
        Promise.reject new Error("could not put host #{id}: #{err}")
      else
        Promise.resolve

  deleteHost: (id) ->
    client.hdel "hosts", id, (err, res) ->
      if(err?)
        Promise.reject new Error("could not delete host #{id}: #{err}")
      else
        Promise.resolve

  reloadData: reloadData