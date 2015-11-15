require 'sugar'
mv = require 'mv'
soap = require 'soap'
loki = require 'lokijs'
domain = require 'domain'
events = require 'events'
broker = new events.EventEmitter()
{resolve, basename, sep} = require 'path'

database = resolve process.cwd(), 'db', 'loki.json'
db = new loki database
#db.addCollection 'ws-soap'
#db.saveDatabase()
db.loadDatabase()
setInterval ->
	db.loadDatabase()
, 1000

commenceTopic = 'file-upload-commence'
moveTopic = 'move-from-temp-to-new-dir-done'
wsdlTopic = 'wsdl-interpreted-and-valid'

wsdlObj =
	name: ''
	set: (@name) =>
	get: => @name

parseWSDL = (ws) ->
	parsed = for i of ws
		if ws[i].input? then i
		else if typeof ws[i] is 'object'
			parseWSDL ws[i]
	parsed.flatten().unique()

searchObj = (child, node) ->
	return node[child] if node[child]?
	return search = searchObj child, node[obj] for obj of node when Object.has node, obj

broker.on wsdlTopic, ({client}) ->
	collection = db.getCollection 'ws-soap'
	for action in parseWSDL client.describe()
		console.log "About to insert #{action}"
		collection.insert
			wsdl: wsdlObj.get()
			action: action
			io: searchObj action, client.describe()
		db.saveDatabase()

broker.on moveTopic, ({fromDir, toDir, client}) ->
	mv fromDir, toDir, {mkdirp: true, clobber: false}, (error) ->
		throw error if error?
		broker.emit wsdlTopic, {client: client}

broker.on commenceTopic, ({fromDir, toDir}) ->
	soap.createClient fromDir, (error, client) ->
		throw error if error?
		broker.emit moveTopic,
			fromDir: fromDir
			toDir: toDir
			client: client

module.exports = (rq, rs, nx) ->
	rs.writeHead 200, {"Content-Type": "text/plain"}
	wsdlObj.set basename rq.files.wsdl.name, '.xml'
	d = domain.create()
	d.on 'error', (error) ->
		console.log error
		rs.write '{"status": "failure"}'
		rs.end()
		return nx()
	broker.on wsdlTopic, ({client}) ->
		allWsObj = for action in parseWSDL client.describe()
			wsObj =
				wsdl: wsdlObj.get()
				action: action
				io: searchObj action, client.describe()
			wsObj
		statusObj = {status: "success"}
		statusObj.ws = allWsObj
		console.log statusObj
		rs.write JSON.stringify statusObj
		console.log 'Successful upload'
		rs.end()
		return nx()
	d.run ->
		broker.emit commenceTopic,
			toDir: resolve process.cwd(), 'wsdl', rq.files.wsdl.name
			fromDir: rq.files.wsdl.path