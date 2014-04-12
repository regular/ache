Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
debug = require('debug')('ache')

class Node
    constructor: (@path, @getPromise) ->

class File extends Node
    constructor: (path) ->
        super path, ->
            fs.statAsync path

updateIfNeeded = (source, target) ->
    # do we have a cached version
    cachedNode = new File target.path

    return new Node target.path, ->
        cachedNode.getPromise().then( (cachedStats) ->
            debug "there is a cached version for #{target.path} from #{cachedStats.mtime}"
            
            compareDates = (sourceStats) ->
                # is the cache valid?
                if cachedStats.mtime.getTime() > sourceStats.mtime.getTime()
                    debug "#{target.path} is up-to-date."
                    return cachedStats
                else
                    debug "#{target.path} is outdated."
                    return target.getPromise()

            source.getPromise().then(
                compareDates
            ).error (err) ->
                debug "cache origin #{source.path} not found!"

        ).error (err) ->
            if err.cause.path is cachedNode.path
                debug "there is NO cached version for #{target.path}"
                return target.getPromise()
            throw err

module.exports = {
    Node, File, updateIfNeeded
}
