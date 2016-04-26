cors                 = require 'cors'
morgan               = require 'morgan'
express              = require 'express'
bodyParser           = require 'body-parser'
errorHandler         = require 'errorhandler'
meshbluHealthcheck   = require 'express-meshblu-healthcheck'
MeshbluConfig        = require 'meshblu-config'
debug                = require('debug')('oauth-provider:server')
OauthProviderService = require './services/oauth-provider-service'
OAuthModel           = require './models/oauth'
OAuthServer          = require 'express-oauth-server'

class Server
  constructor: ({@disableLogging, @port, @octobluBaseUrl, @meshbluConfig})->
    @meshbluConfig ?= new MeshbluConfig().toJSON()

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use cors()
    app.use errorHandler()
    app.use meshbluHealthcheck()
    app.use bodyParser.urlencoded limit: '1mb', extended : true
    app.use bodyParser.json limit : '1mb'

    app.options '*', cors()

    model = new OAuthModel {@meshbluConfig}
    oauth = new OAuthServer {model}
    app.use oauth.authorize()

    oauthProviderService = new OauthProviderService
    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = Server
