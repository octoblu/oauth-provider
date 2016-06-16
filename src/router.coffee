URL                     = require 'url'
OauthProviderController = require './controllers/oauth-provider-controller'

class Router
  constructor: ({@oauthProviderService, @octobluBaseUrl, @octobluOauth}) ->
  route: (app) =>
    oauthProviderController = new OauthProviderController {@oauthProviderService}

    app.all '/access_token', app.oauth.grant()

    app.get '/authorize', (req, res) =>
      {protocol, hostname, port} = URL.parse @octobluBaseUrl
      clientId = req.query.client_id
      redirectUri = req.query.redirect_uri
      @octobluOauth.getClient clientId, null, (error, client)=>
        return res.status(error.code ? 500).send error: error.message if error?
        return res.status(404).send error: 'Missing or undiscoverable client' unless client?
        redirectUri ?= client.redirectUri
        authRedirectUri = '/auth_code'
        if req.query.response_type == 'token'
          authRedirectUri = '/client_token'
        res.redirect URL.format
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

module.exports = Router
