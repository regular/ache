Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
debug = require('debug')('ache')
{_} = require 'lodash'

class Node
    constructor: (@path, getPromise) ->
        @prerequisits = []
        @_promise = null
        @_getPromise = getPromise

    getPromise: ->
        @_promise ?= @_getPromise()
        return @_promise

    addPrerequisite: (p) ->
        if p in @prerequisits then return
        @prerequisits.push p
        return @

class File extends Node
    constructor: (path) ->
        super path, ->
            fs.statAsync path

updateIfNeeded = (source, target) ->
    # do we have a cached version
    cachedNode = new File target.path
    cachedNode.prerequisits = _.clone(target.prerequisits)

    return new Node target.path, ->
        cachedNode.getPromise().then( (cachedStats) ->
            debug "there is a cached version for #{target.path} from #{cachedStats.mtime}"
            cache = 
                node: cachedNode
                timestamp: cachedStats.mtime.getTime()

            ## can we find a more recent timestamp
            ## among the dependencies (source + prerequisits)?
            dependencies = [source].concat target.prerequisits
            reduce = (highest, node) ->
                node.getPromise().then (stats) ->
                    timestamp = stats.mtime.getTime()
                    highest = {node, timestamp} if timestamp > highest.timestamp
                    return highest

            Promise.reduce(dependencies, reduce, cache).then( (mostRecent) ->
                if mostRecent.node is cachedNode
                   debug "#{target.path} is up-to-date."
                   return cachedStats
                else
                    # one of the dependencies was modified after the cached
                    # target file.
                    debug "#{target.path} is outdated."
                    debug "(#{mostRecent.node.path} is newer)"
                    return target.getPromise()

            ).error (err) ->
                debug "cache dependency not found! #{err.cause.path}"
                throw err

        ).error (err) ->
            if err.cause.path is cachedNode.path
                debug "there is NO cached version for #{target.path}"
                return target.getPromise()
            throw err

module.exports = {
    Node, File, updateIfNeeded
}
