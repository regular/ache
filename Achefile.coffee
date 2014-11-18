Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
debug = require('debug')('Achefile')

{Node, File, Bundle} = require './ache'

npm = require './ache-npm'

modules = npm new File './package.json'

coffee = require('./ache-coffee')(modules)

bundle = coffee new File './test.coffee'
[jsNode, stuff...] = bundle

console.log jsNode.prerequisites

jsNode.getPromise().then(
    (stats) ->
        debug "JS file with #{stats.size} bytes created on #{stats.mtime}"
        return stats
).catch (error) ->
    console.error "ACHE FAILED with error: \n#{error}"
    console.error error.stack




