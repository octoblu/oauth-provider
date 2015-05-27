express = require 'express'
bodyParser = require 'body-parser'
oauthserver = require 'oauth2-server'
OctobluOauth = require './octoblu-oauth'
meshbluHealthcheck = require 'express-meshblu-healthcheck'

OCTOBLU_BASE_URL = process.env.OCTOBLU_BASE_URL || 'https://app.octoblu.com'
OCTOBLU_OAUTH_PROVIDER_SERVER_PORT = process.env.OCTOBLU_OAUTH_PROVIDER_SERVER_PORT || 9000
MESHBLU_HOST = process.env.MESHBLU_HOST
MESHBLU_PORT = process.env.MESHBLU_PORT

app = express()

app.use bodyParser.urlencoded extended: true
app.use bodyParser.json()
app.use meshbluHealthcheck()

app.oauth = oauthserver
  model: new OctobluOauth {server: MESHBLU_HOST, port: MESHBLU_PORT}
  grants: [ 'authorization_code', 'client_credentials' ]
  debug: true

app.all '/access_token', app.oauth.grant()

app.get '/authorize', (req, res) ->
  res.redirect "#{OCTOBLU_BASE_URL}/oauth/#{req.query.client_id}?redirect=/auth_code&redirect_uri=#{req.query.redirect_uri}&response_type=#{req.query.response_type}"

app.get '/auth_code', app.oauth.authCodeGrant (req, next) =>
  next null, true, req.params.uuid, null

app.use app.oauth.errorHandler()

app.listen OCTOBLU_OAUTH_PROVIDER_SERVER_PORT
