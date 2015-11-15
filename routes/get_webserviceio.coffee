loki = require 'lokijs'
{resolve, basename, sep} = require 'path'

database = resolve process.cwd(), 'db', 'loki.json'
db = new loki database
db.loadDatabase()
setInterval ->
	db.loadDatabase()
, 1000

module.exports = (rq, rs, nx) ->
	{ws, act} = rq.params
	rs.writeHead 200, {"Content-Type": "text/plain"}
	collection = db.getCollection 'ws-soap'
	documents = collection.find
		'$and': [
			{wsdl: ws}
			{action: act}
		]
	console.log documents
	rs.write JSON.stringify document for document in documents
	rs.end()
	nx()