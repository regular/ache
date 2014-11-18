Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
debug = require('debug')('ache-coffee')

# TODO: use user-provided 'coffee-script' module
coffeeScript = require 'coffee-script'
_ = require 'lodash'

{File, Bundle} = require './ache'

coffee = (source, options = {}) ->
    # source is a Node for a .coffee file
    # (it's promise will resolve to the file's stats)
    debug "Adding rule for #{source.path}"

    outExtensions = [
        '.js'
        '.js.map'
    ]

    outputPath = (index) ->
        ext = outExtensions[index]
        source.path.replace /\.[^\.]+$/, ext

    makePromiseToCompile = ->
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
        )

    # we must return a new Node for each output file
    # and it's getPromise must resolve to that file's stats

    # we also must return a Bundle Node. It's promise must
    # resolve to an array of stats objects

    writeFile = (index, data) ->
        path = outputPath(index)
        fs.writeFileAsync(path, data, 'utf8').then(
            -> fs.statAsync path
        )

    makeBundlePromise = ->
        makePromiseToCompile().then ({js, v3SourceMap}) ->
            o =
                0: js
                1: v3SourceMap
            Promise.map _.pairs(o), ([index, data])->
                writeFile index, data


    ## TODO: investigate ways
    ## to use Bundle:getPromise()
    ## of the parent Node instead of using
    ## makeBundlePromise()
    ## This would prevent multiple identical
    ## compiler runs if indiviual files are requested
    ## rather than the bundle.
    ## (the caching lazyer might catch this though)

    makeFileNode = (index) ->
        new File(outputPath(index), ->
            makeBundlePromise().then (result) ->
                result[index]
        ).addPrerequisite source

    new Bundle([
        makeFileNode 0
        makeFileNode 1
    ], makeBundlePromise).addPrerequisite source

module.exports = (modules) ->
    (source, options) ->
        result = coffee source, options
        node.addPrerequisite(modules) for node in result
        result.addPrerequisite modules
        
