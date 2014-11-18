
*this is very experimental* if you are looking for something that actually is usable, you should look somewhere else.

## What's aching?

Ache is not a build tool. It is a node module that makes it very easy to create a project-specific program that builds your project in the most efficient way possible. We recommend calling this program `ache` :)

### GOALS

grunt and gulp are popular in the JS community. Both however are more or less simple task runners with varying degrees of caching.

  * The goal hiere is to reach make's level of efficiency: run the actions necessary, not more, not less. Do this as efficient as possible.

  * The reciple (Makefile, Gruntfile, ...) shall be an executable file, a program, so it simply can require() whatever module it needs. The output of this program is a dependecy tree. Each node represents a *promise* for the target associated with that node.

  * The actions shall be functions that take input and produce an output, because that's the most natural fitting abstraction in JavaScript.

  * an output of an action can be multiple physical files (think: source maps, font files, ...)

### tool/action abstraction
- is streaming data
- can have options
- multiple inputs and outputs
- adapter might use temp files to implement streaming
- use locally installed binaries found in `node_modules`

Planned first-wave tool support via npm modules
- ache-fontcustom
- ache-coffee
- ache-ejs
- ache-jade
- ache-stylus
- ache-browserify
- ache-lab
- ache-casper

    npm install ache-casper # installs all necessary binaries

- Q: how can we do this without flooding the npm namespace?
- A: there's a new npm feature, right?
- A: several generic built-in adapter to wrap around typical tool functions, promisify()-style

## it's fractal
- a part consists of parts
- a part is stand-alone
- a project is a part

A node provides a  promise of a part

## removing typlical pain points

Error handling shall take temporary outtakes of external machines/services into account.


## Example Achefile (using CoffeeScript)

    fontcustom = require 'ache-fontcustom'
    jade = require 'ache-jade'
    coffee  = require 'ache-coffee'

    iconFont = (destination) ->
        # create a custom font with two icons
        icon1 = File 'svgs/icon1.svg'
        icon2 = File 'svgs/icon2.svg'

        {ttfFile, otfFile, cssFile} = fontcustom [icon1, icon2]

        {cssFile} = component [
            ttfFile, 
            otfFile, 
            cssFile, 
        ]

        [cssFile, ttfFile, otfFile] = copy [cssFile, ttfFile, otfFile], destination

        return [cssFile, ttfFile, otfFile]

    signup = (destination) ->
        
        templateJS = jade File 'templates/entry.jade', {client: true}
        clientJS = coffee File 'main.cofee', {bare: true}

        {cssFile, jsFile} = component [
            templateJS,
            clientJS
        ], {main: path.basename clientJS.path()}

        serverJS = coffee File 'server.coffee'
        html = jade File 'index.jade'

        return copy [html, serverJS, cssFile, jsFile], destination

    webApp = (destination) -> Promise.all _.flatten [iconFont(destination), singup(destination)]

    buildDir = mkdirp 'build'
    thePromiseOfanApp = webApp(buildDir)

    thePromiseOfanApp.resolve()


		

