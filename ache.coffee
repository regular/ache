Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
debug = require('debug')('ache')

class Node
    constructor: (@path, @getPromise) ->

class File extends Node
    constructor: (path) ->
        super path, ->
            fs.statAsync path

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

module.exports = {
    Node, File, updateIfNeeded
}
