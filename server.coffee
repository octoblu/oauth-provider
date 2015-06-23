express = require 'express'
bodyParser = require 'body-parser'
oauthserver = require 'oauth2-server'
OctobluOauth = require './octoblu-oauth'
MeshbluConfig = require 'meshblu-config'

meshbluConfig = new MeshbluConfig().toJSON()
meshbluHealthcheck = require 'express-meshblu-healthcheck'

OCTOBLU_BASE_URL = process.env.OCTOBLU_BASE_URL || 'https://app.octoblu.com'
PORT = process.env.PORT || 80

app = express()

app.use bodyParser.urlencoded extended: true
app.use bodyParser.json()
app.use meshbluHealthcheck()

app.oauth = oauthserver
  model: new OctobluOauth meshbluConfig
  grants: [ 'authorization_code', 'client_credentials' ]
  debug: true

app.all '/access_token', app.oauth.grant()

app.get '/authorize', (req, res) ->
  res.redirect "#{OCTOBLU_BASE_URL}/oauth/#{req.query.client_id}?redirect=/auth_code&redirect_uri=#{req.query.redirect_uri}&response_type=#{req.query.response_type}"

app.get '/auth_code', app.oauth.authCodeGrant (req, next) =>
  next null, true, req.params.uuid, null

app.use app.oauth.errorHandler()

app.listen PORT
