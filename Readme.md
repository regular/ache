
tools abstraction
- streaming
- options
- multiple inputs and outputs
- adapter might use temp files to implement streaming

tool support via npm modules
	ache-fontcustom
	ache-coffee
	ache-jade
	ache-stylus
	ache-component
	ache-mocha
	ache-casper

	npm install ache-casper installs all necessary banaries

A fractal build tool
	a part consists of parts
	a part is stand-alone
	a project is a part

The promise of a part

Error handling takes temporary outtakes of external machiner into account.

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


		

