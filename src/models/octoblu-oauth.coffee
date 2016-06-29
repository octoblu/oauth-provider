_          = require 'lodash'
btoa       = require 'btoa'
atob       = require 'atob'
moment     = require 'moment'
crypto     = require 'crypto'
oauthError = require 'oauth2-server/lib/error'
debug      = require('debug')('oauth-provider:octoblu-oauth')

class OctobluOauth
  constructor: (options, dependencies={}) ->
    {
      @meshbluConfig
      @pepper
    } = options
    @meshbluConfig ?= {}
    @MeshbluHttp = dependencies.MeshbluHttp ? require 'meshblu-http'

  getClient : (clientId, clientSecret, callback) =>
    return callback oauthError('invalid_client', 'Missing clientId') unless clientId?
    options = _.clone @meshbluConfig
    if clientSecret
      debug 'using client creds'
      options.uuid = clientId
      options.token = clientSecret
    else
      debug 'using oauth-provider creds'

    meshblu = new @MeshbluHttp options
    debug 'getClient: about to get device', clientId, clientSecret
    meshblu.device clientId, (error, device) =>
      return callback oauthError('invalid_client', 'Unable to get Client') if error?
      return callback oauthError('invalid_client', 'Client Not Found') unless device?
      debug 'getClient found device', device?.uuid
      callback null, {
        clientId,
        client_id: clientId,
        client_secret: clientSecret,
        redirectUri: device.options?.callbackUrl
      }

  grantTypeAllowed : (clientId, grantType, callback) =>
    allowed = grantType in [ 'refresh_token', 'authorization_code', 'client_credentials' ]
    callback null, allowed

  saveAccessToken : (accessToken, clientId, expires, userId, callback) =>
    callback()

  getAccessToken: (bearerToken, callback) =>
    [userId, token] = atob(bearerToken).split ':'
    debug 'getAccessToken', {userId}
    callback null, {
      expires: null
      userId
    }

  getAuthCode: (authCode, callback) =>
    [clientId, userId, token] = atob(authCode).split ':'
    debug 'getAuthCode', {clientId, userId}
    callback null, {
      clientId,
      expires: moment().add(1, 'year').valueOf()
      userId
    }

  _generateHash: ({client_id, uuid, token }) =>
    hasher = crypto.createHash 'sha256'
    hasher.update @meshbluConfig.uuid
    hasher.update uuid
    hasher.update @pepper
    hasher.digest 'base64'

  generateToken: (type, req, callback) =>
    params = _.extend {}, req.query, req.body
    debug 'generateToken check type', type, params

    if type == 'authorization_code'
      responseToken = btoa [params.client_id, params.uuid, params.token].join ':'
      debug 'sending authorization_code', responseToken
      return callback null, responseToken

    unless params.code?
      params.code = btoa "#{params.client_id}:#{params.uuid}:#{params.token}"

    [client_id, uuid, token] = atob(params.code).split ':'
    return callback null, btoa uuid + ':' + token if type == 'refreshToken'
    debug {client_id, uuid, token}
    options = _.extend({}, @meshbluConfig, {uuid, token})
    meshblu = new @MeshbluHttp options
    tag = @_generateHash {client_id, uuid, token}
    tokenOptions = {tag, client_id}
    meshblu.revokeTokenByQuery uuid, {tag}, (error, response) =>
      return callback oauthError 'server_error', error if error?
      meshblu.generateAndStoreTokenWithOptions uuid, tokenOptions, (error, response) =>
        debug 'generateAndStoreToken error: ', error if error?
        return callback oauthError 'server_error', error if error?
        newToken = response.token
        debug 'generateAndStoreToken', uuid, newToken
        meshblu.revokeToken uuid, token, (error) =>
          return callback oauthError 'server_error', error if error?
          callback null, btoa uuid + ':' + newToken

  saveAuthCode: (authCode, clientId, expires, user, callback) =>
    callback()

  saveRefreshToken: (refreshToken, clientId, expires, user, callback) =>
    callback()

  getRefreshToken: (refreshToken, callback) =>
    [clientId, userId, token] = atob(refreshToken).split ':'
    debug 'getRefreshToken', {clientId, userId}
    callback null, {
      clientId,
      expires: null
      userId
    }

  revokeRefreshToken: (refreshToken, callback) =>
    callback()

module.exports = OctobluOauth
