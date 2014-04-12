Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
debug = require('debug')('Achefile')

{Node, File, updateIfNeeded} = require './ache'

coffee = require './ache-coffee'
npm = require './ache-npm'

coffeeNode = new File './test.coffee'
jsNode = updateIfNeeded coffeeNode, coffee coffeeNode

packageJSON = new File './package.json'

modules = updateIfNeeded packageJSON, npm packageJSON

modules.getPromise().then(
    -> jsNode.getPromise()
).then(
    (stats) ->
        debug "JS file with #{stats.size} bytes created on #{stats.mtime}"
        return stats
).catch (error) ->
    console.error "ACHE FAILED with error: \n#{error}"
    console.error error.stack




