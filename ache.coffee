Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
debug = require('debug')('ache')

class Node
    constructor: (@path, @getPromise) ->

class File extends Node
    constructor: (path) ->
        super path, ->
            fs.statAsync path

##
# Example of a tool wrapper
##

coffeeScript = require 'coffee-script'
_ = require 'lodash'
coffee = (source, options = {}) ->
    # source is a Node for a .coffee file
    # (it's promise will resolve to the file's stats)
    targetPath = source.path.replace /\.coffee$/, '.js'
    debug "Adding coffee rule for #{targetPath}"

    # we must return a new Node for the .js file
    # and it's getPromise must resolve to the .hs file's stats
    return new Node targetPath, ->
        source.getPromise().then( ->
            fs.readFileAsync(source.path, 'utf8')
        ).then( (coffeeCode) ->
            debug 'compiling'
            coffeeScript.compile coffeeCode,
                _.defaults options, {
                    filename: source.path
                    header: true
                    sourceMap: true
                }
        ).then( (obj) ->
            fs.writeFileSync targetPath, obj.js, 'utf8'
        ).then( ->
            fs.statAsync targetPath
        )
    
updateIfNeeded = (source, target, build) ->
    # do we have a cached version
    cachedNode = new File target.path

    cachedNode.getPromise().then( (cachedStats) ->
        debug "there is a cached version for #{target.path} from #{cachedStats.mtime}"
        return source.getPromise().then(
            (sourceStats) ->
                # is the cache valid?
                if cachedStats.mtime.getTime() > sourceStats.mtime.getTime()
                    debug 'it is up-to-date.'
                    return cachedStats
                else
                    debug 'it is outdated.'
                    return target.getPromise()
        )
    ).catch( (err) ->
        if err.path is cachedNode.path
            debug "there is NO cached version for #{target.path}"
            return target.getPromise()
        throw err
    )

coffeeNode = new File './test.coffee'
jsNode = updateIfNeeded coffeeNode, coffee coffeeNode

jsNode.then(
    (stats) ->
        debug "JS file with #{stats.size} bytes created on #{stats.mtime}"
        return stats
).catch (error) ->
    console.error "ACHE FAILED with error: \n#{error}"

    


