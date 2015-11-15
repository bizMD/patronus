loki = require 'lokijs'
{resolve, basename, sep} = require 'path'

database = resolve process.cwd(), 'db', 'loki.json'
db = new loki database
db.loadDatabase()
setInterval ->
	db.loadDatabase()
, 1000

module.exports = (rq, rs, nx) ->
	rs.writeHead 200, {"Content-Type": "text/plain"}
	collection = db.getCollection 'ws-soap'
	set = for data in collection.data
		delete data.meta
		delete data.$loki
		data
	rs.write JSON.stringify set
	#rs.write JSON.stringify data for data in collection.data
	#Better to stream the result... but it's hard to receive
	rs.end()
	nx()