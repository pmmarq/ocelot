url = require 'url'
_ = require 'underscore'
log = require './log'

pickRandomEndpoint = (allEndpoints) ->
    instanceUrlStr = allEndpoints[getRandomInt 0, allEndpoints.length - 1].url
    instanceUrlStr + (if instanceUrlStr.charAt(instanceUrlStr.length - 1) is '/' then '' else '/')

rewriteUrl = (targetHost, incomingPath, route) ->
    capture = new RegExp(route['capture-pattern'])
    rewrittenPath = route['rewrite-pattern']

    if capture.test(incomingPath)
        match = capture.exec(incomingPath)
        rewrittenPath = rewrittenPath.replace('$' + i, match[i]) for i in [1 ... match.length]
        targetHost = targetHost.replace('$' + i, match[i]) for i in [1 ... match.length]

    while rewrittenPath.indexOf('/') == 0
        rewrittenPath = rewrittenPath.substring(1)

    targetHost + rewrittenPath

getAllEndpoints = (route) ->
    _(route.services).chain().map((service) ->
        route.instances[service]
    ).flatten().compact().value()

getRandomInt = (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min

module.exports =
    mapRoute: (incomingPath, route) ->
        allEndpoints = getAllEndpoints route

        if allEndpoints.length
            targetHost = pickRandomEndpoint allEndpoints
            rewritten = rewriteUrl targetHost, incomingPath, route

            try
                url.parse rewritten
            catch err
                log.error "could not parse url: #{rewritten}"
