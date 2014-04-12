Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
debug = require('debug')('ache-coffee')

coffeeScript = require 'coffee-script'
_ = require 'lodash'

{Node} = require './ache'

coffee = (source, options = {}) ->
    # source is a Node for a .coffee file
    # (it's promise will resolve to the file's stats)
    targetPath = source.path.replace /\.coffee$/, '.js'
    debug "Adding rule for #{targetPath}"

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

module.exports = (modules) ->
    (source, options) ->
        result = coffee source, options
        result.addPrerequisite modules