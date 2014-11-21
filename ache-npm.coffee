Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
debug = require('debug')('ache-npm')
Path = require 'path'

Npm = require 'npm'
_ = require 'lodash'

{File} = require './ache'

install = (source, options = {}) ->
    # source is a Node for a package.json file
    # (it's promise will resolve to the file's stats)
    if (Path.basename source.path) isnt 'package.json'
        throw Error("source of npm::install must be a file named 'package.json', instead it is: #{source.path}")

    targetPath = source.path.replace /package\.json$/, 'node_modules'
    debug "Adding rule to install modules into #{targetPath}"

    # we must return a new Node for the node_modules directory
    node_modules = new File targetPath, ->
        debug "node_modules.gePromise() was called"
        source.getPromise().then( ->
            debug "reading #{source.path}"
            fs.readFileAsync source.path, 'utf8'
        ).then( (pkg) ->
            pkg = JSON.parse pkg
            debug "installing dependencies of #{pkg.name}"
            return Promise.promisify(Npm.load) options
        ).then( ->
            Npm.on 'log', (msg) -> debug msg
            Promise.promisify(Npm.install)()
        ).then( ->
            now = new Date()
            fs.utimesAsync targetPath, now, now
        ).then( ->
            fs.statAsync targetPath
        ).catch( SyntaxError, (e) ->
            e.message = "Error parsing #{source.path}: " + e.message
            throw e
        ).catch (error)  ->
            debug "npm install failedi #{error}"

    node_modules.addPrerequisite source
    return node_modules

module.exports = install
