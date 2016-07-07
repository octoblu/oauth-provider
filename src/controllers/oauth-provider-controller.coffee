URL   = require 'url'
debug = require('debug')('oauth-provider:controller')

class OauthProviderController
  constructor: ({@oauthProviderService,@octobluBaseUrl,@octobluOauth}) ->

  authorize: (req, res) =>
    state = req.query.state
    clientId = req.query.client_id
    redirectUri = req.query.redirect_uri
    responseType = req.query.response_type
    @_getRedirectUri {clientId, redirectUri, responseType, state}, (error, uri) =>
      return res.status(error.code ? 500).send error: error.message if error?
      debug 'redirecting to ', { uri }
      res.redirect uri

  alexaAuthorize: (req, res) =>
    state = req.query.state
    clientId = req.query.client_id
    redirectUri = req.query.redirect_uri.replace('.amazon.comapi', '.amazon.com/api')
    responseType = req.query.response_type
    @_getRedirectUri {clientId, redirectUri, responseType, state}, (error, uri) =>
      return res.status(error.code ? 500).send error: error.message if error?
      debug 'redirecting to ', { uri }
      res.redirect uri

  _getRedirectUri: ({ clientId, redirectUri, responseType, state }, callback) =>
    {protocol, hostname, port} = URL.parse @octobluBaseUrl
    @octobluOauth.getClient clientId, null, (error, client) =>
      return callback error if error?
      return callback @_createError 'Missing or undiscoverable client', 404 unless client?
      redirectUri ?= client.redirectUri
      authRedirectUri = '/auth_code'
      authRedirectUri = '/client_token' if responseType == 'token'

      redirect = URL.format {
        protocol: protocol
        hostname: hostname
        port: port
        pathname: "/oauth/#{clientId}"
        query:
          state: state
          redirect: authRedirectUri
          redirect_uri: redirectUri
          response_type: responseType
      }
      callback null, redirect

  _createError: (message, code) =>
    error = new Error(message)
    error.code = code ? 500
    return error

module.exports = OauthProviderController
