http = require 'http'
facade = require './backend/facade.coffee'
uri = require 'url'
_ = require 'underscore'

findRoute = (key) ->
    _(facade.getRoutes()).find (route) -> route.route is key

findRouteByPath = (url, pathDepth = 4) ->
    if pathDepth == 0
        null
    else
        key = url.split('/', pathDepth).join '/'
        findRoute(key) or findRouteByPath(key, pathDepth - 1)

module.exports =
    resolveRoute: (url, host) ->
        closestRoute = findRouteByPath("#{host}#{url}")
        services = facade.getHosts()
        closestRoute?.instances = _(closestRoute.services).chain().map((service) ->
            [service, services[service]]
        ).object().value()
        closestRoute