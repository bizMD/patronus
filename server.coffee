# Require the dependencies
require 'sugar'
fs = require 'fs'
mv = require 'mv'
vow = require 'vow'
soap = require 'soap'
loki = require 'lokijs'
restify = require 'restify'
{resolve, sep} = require 'path'

# Require the routes directory
requireDir = require 'require-dir'
require('coffee-script/register')
routes = requireDir 'routes'

# Create the web server and use middleware
server = restify.createServer {name: 'Patronus'}
server.use restify.bodyParser()
server.pre restify.pre.sanitizePath()
server.use restify.CORS()
server.use restify.fullResponse()

server.post '/resource/1/webserviceactions', routes.post_webserviceactions
server.get '/resource/1/webserviceactions', routes.get_webserviceactions
server.get '/resource/1/webserviceio/:ws/:act', routes.get_webserviceio
server.get '/resource/1/tempquickworkaround', routes.get_tempquickworkaround

server.on 'after', ->
	console.log 'after fired'


server.listen 80, -> console.log "#{server.name}[#{process.pid}] online :: #{server.url}"
console.log "#{server.name} is starting up..."