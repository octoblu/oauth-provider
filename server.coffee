cors          = require 'cors'
morgan        = require 'morgan'
express       = require 'express'
url           = require 'url'
bodyParser    = require 'body-parser'
OAuth2Server  = require 'oauth2-server'
OctobluOauth  = require './octoblu-oauth'
MeshbluConfig = require 'meshblu-config'
AuthCodeGrant = require './authCodeGrant'
ClientCredentialsGrant = require './clientCredentialsGrant'

meshbluConfig = new MeshbluConfig().toJSON()
meshbluHealthcheck = require 'express-meshblu-healthcheck'

OCTOBLU_BASE_URL = process.env.OCTOBLU_BASE_URL ? 'https://app.octoblu.com'
PORT = process.env.PORT ? 80

OAuth2Server.prototype.authCodeGrant = (check) ->
  that = @
  (req, res, next) =>
    new AuthCodeGrant that, req, res, next, check

OAuth2Server.prototype.clientCredentialsGrant = (check) ->
  that = @
  (req, res, next) =>
    new ClientCredentialsGrant that, req, res, next, check

app = express()
app.use meshbluHealthcheck()
app.use cors()
app.use morgan 'dev'
app.use bodyParser.urlencoded extended: true
app.use bodyParser.json()

octobluOauth = new OctobluOauth meshbluConfig
app.oauth = OAuth2Server
  model: octobluOauth
  grants: [ 'authorization_code', 'client_credentials' ]
  debug: true

app.all '/access_token', app.oauth.grant()

app.get '/authorize', (req, res) ->
  {protocol, hostname, port} = url.parse OCTOBLU_BASE_URL
  clientId = req.query.client_id
  redirectUri = req.query.redirect_uri
  octobluOauth.getClient clientId, null, (error, client)=>
    return res.status(500).send error: error if error?
    return res.status(404).send error: 'Missing or undiscoverable client' unless client?
    redirectUri ?= client.redirectUri
    authRedirectUri = '/auth_code'
    if req.query.response_type == 'token'
      authRedirectUri = '/client_token'
    res.redirect url.format
      protocol: protocol
      hostname: hostname
      port: port
      pathname: "/oauth/#{clientId}"
      query:
        state: req.query.state
        redirect: authRedirectUri
        redirect_uri: redirectUri
        response_type: req.query.response_type

app.get '/auth_code', app.oauth.authCodeGrant (req, next) =>
  next null, true, req.params.uuid, null

app.get '/client_token', app.oauth.clientCredentialsGrant (req, next) =>
  next null, true, req.params.uuid, null

app.use app.oauth.errorHandler()

app.listen PORT, () =>
  console.log 'Listening on port', PORT

process.on 'SIGTERM', =>
  console.log 'SIGTERM caught, exiting'
  process.exit 0
