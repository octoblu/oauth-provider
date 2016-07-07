OauthProviderController = require './controllers/oauth-provider-controller'
debug                   = require('debug')('oauth-provider:router')

class Router
  constructor: ({@octobluBaseUrl, @octobluOauth}) ->

  debugExpress: (req, res, next) =>
    debug 'method', req.method
    debug 'body', req.body
    debug 'headers', req.headers
    debug 'query', req.query
    debug 'params', req.params
    next()

  check: (req, next) =>
    next null, true, true

  route: (app) =>
    oauthProviderController = new OauthProviderController {@octobluBaseUrl, @octobluOauth}

    app.all '/access_token', app.oauth.grant()

    app.get '/authorize', oauthProviderController.authorize

    # It sucks but we have to do this (temporarily)
    app.get '/alexa/authorize', oauthProviderController.alexaAuthorize

    app.get '/auth_code', app.oauth.authCodeGrant (req, next) =>
      next null, true, req.params.uuid, null

    app.get '/client_token', app.oauth.clientCredentialsGrant (req, next) =>
      next null, true, req.params.uuid, null

module.exports = Router
