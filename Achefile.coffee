Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
debug = require('debug')('Achefile')

{Node, File, updateIfNeeded} = require './ache'

coffee = require './ache-coffee'

coffeeNode = new File './test.coffee'
jsNode = updateIfNeeded coffeeNode, coffee coffeeNode

jsNode.then(
    (stats) ->
        debug "JS file with #{stats.size} bytes created on #{stats.mtime}"
        return stats
).catch (error) ->
    console.error "ACHE FAILED with error: \n#{error}"

    


