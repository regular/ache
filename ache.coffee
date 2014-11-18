Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
debug = require('debug')('ache')
{_} = require 'lodash'

class OutdatedError extends Error
    constructor: (msg) -> super "OutdatedError #{msg}"

class Node
    constructor: (getPromise) ->
        @prerequisites = []
        @_promise = null
        @_getPromise = getPromise

    getPromise: ->
        @_promise ?= @_getPromise()
        return @_promise

    addPrerequisite: (p) ->
        if p in @prerequisites then return
        @prerequisites.push p
        return @

    ## This returns the mtime of the newest
    ## dependency or throws when at least
    ## one dependency is outdated.
    ## *obviously also throws when one does not 
    ## implement isOutdated, this is by design.
    getPrerequisitesMTime: ->
        reduceToHighest = (highest, node) ->
            node.getMTime().then (timestamp) ->
                if timestamp > highest then timestamp else highest

        Promise.map(@prerequisites, (p) -> p.isOutdated()).then (outdated) =>
            if _.any(outdated) then throw new OutdatedError()
            Promise.reduce(@prerequisites, reduceToHighest, 0)

class PersistentNode extends Node

    getMTime: -> throw new Error('getTime is not implemented')

    isOutdated: ->
        fileNotFoundHandler = (err) =>
            if err.cause.code is 'ENOENT'
                debug "file does not exist: #{err.cause.path}"
                return true
            else
                console.log "fileNotFoundHandler: #{err}"
                throw err

        if @prerequisites.length is 0
            # just make sure, we exist
            return @getMTime().then( =>
                debug "file #{@path} has no prerequisites"
                return false
            ).error fileNotFoundHandler

        ## TODO: if a prerequisite does not implement
        ## getMTime, return true as well
        Promise.join(@getPrerequisitesMTime(), @getMTime()).spread( (ptime, mtime) ->
            return ptime > mtime
        ).error( fileNotFoundHandler
        ).error OutdatedError, (err) ->
            debug "a prerequisite of #{path} is outdated."
            return true

class File extends PersistentNode
    constructor: (@path, getPromise = null) ->
        super getPromise or @getStats

    getStats: -> 
        fs.statAsync @path

    getMTime: ->
        @getStats().then (stats) -> stats.mtime.getTime()

    getPromise: ->
        @isOutdated().then (outdated) =>
            if outdated
                debug "file is outdated: #{@path}"
                return super()
            else
                debug "file is up-to-date: #{@path}"
                return @getStats()

# an immutable array of Nodes that can only
# be built together.
class Bundle extends PersistentNode
    constructor: (nodes, getPromise) ->
        @length = nodes.length
        for i in [0...nodes.length]
            @[i] = nodes[i]
        super getPromise

    ## this returns the mtime of the oldest
    ## file in the bundle
    getMTime: ->
        reduceToLowest = (lowest, node) ->
            node.getTime().then (timestamp) ->
                if timestamp < lowest then timestamp else lowest
        console.log 'HERE'
        Promise.reduce(this, reduceToLowest, Number.MAX_VALUE)

    getPromise: ->
        @isOutdated().then (outdated) =>
            if outdated
                debug "bundle is outdated: #{@path}"
                return super()
            else
                debug "bundle is up-to-date: #{@path}"
                return [node.getStats() for node in this]

module.exports = {
    Node, File, Bundle
}
