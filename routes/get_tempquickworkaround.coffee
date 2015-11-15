process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

require 'sugar'
soap = require 'soap'
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
	soap.createClient (resolve 'wsdl', 'HPD_IncidentInterface_WS.xml'), (err, client) ->

		console.log "##################"
		console.log "ERROR: #{err}"
		console.log "##################"
		console.log "CLIENT:"
		console.log client.describe()

		throw err if err?

		client.addSoapHeader
			userName: 'dummyusername'
			password: 'dummypassword'
			authentication: ''
			locale: ''
			timeZone: ''

		for i in [1 .. 10]
			args =
				Qualification: "'Impact' < 2 AND 'Status*' < 4"
				startRecord: 1+((i-1)*100)
				maxLimit: i*100

			client.HelpDesk_QueryList_Service_WithOtherFields args, (err, result) ->
				throw err if err?
				rs.write JSON.stringify result
		
		rs.end()