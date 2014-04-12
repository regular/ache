Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
debug = require('debug')('Achefile')

{Node, File, updateIfNeeded} = require './ache'

npm = require './ache-npm'
packageJSON = new File './package.json'
modules = updateIfNeeded packageJSON, npm packageJSON

coffee = require('./ache-coffee')(modules)

coffeeNode = new File './test.coffee'
jsNode = updateIfNeeded coffeeNode, coffee coffeeNode

modules.getPromise().then(
    -> jsNode.getPromise()
).then(
    (stats) ->
        debug "JS file with #{stats.size} bytes created on #{stats.mtime}"
        return stats
).catch (error) ->
    console.error "ACHE FAILED with error: \n#{error}"
    console.error error.stack




