btoa   = require 'btoa'
atob   = require 'atob'
_      = require 'lodash'
debug  = require('debug')('oauth-provider:octoblu-oauth')
crypto = require 'crypto'

class OctobluOauth
  constructor: (options, dependencies={}) ->
    {
      @meshbluConfig
      @pepper
    } = options
    @meshbluConfig ?= {}
    @MeshbluHttp = dependencies.MeshbluHttp ? require 'meshblu-http'

  getClient : (clientId, clientSecret, callback) =>
    options = _.clone @meshbluConfig
    if clientSecret
      options.uuid = clientId
      options.token = clientSecret

    meshblu = new @MeshbluHttp options
    debug 'getClient: about to get device', clientId, clientSecret
    meshblu.device clientId, (error, device) =>
      return callback error if error?
      debug 'getClient found device', device?.uuid
      callback null, client_id: clientId, client_secret: clientSecret, redirectUri: device.options?.callbackUrl

  grantTypeAllowed : (clientId, grantType, callback) =>
    callback(null, true)

  saveAccessToken : (accessToken, clientId, expires, userId, callback) =>
    callback()

  getAuthCode: (authCode, callback) =>
    console.log atob(authCode)
    [client_id, uuid, token] = atob(authCode).split ':'
    debug 'getAuthCode', [client_id, uuid]
    callback null, {
      clientId: client_id
      expires: new Date() + 10000
      userId: uuid
    }

  _generateHash: ({client_id, uuid, token}) =>
    hasher = crypto.createHash 'sha256'
    console.log {client_id, uuid, @pepper}
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
    options = _.extend({}, @meshbluConfig, {uuid, token})
    meshblu = new @MeshbluHttp options
    debug 'generateToken', options
    tag = @_generateHash {client_id, uuid, token}
    tokenOptions = {tag, client_id}
    meshblu.revokeTokenByQuery uuid, {tag}, (error, response) =>
      return callback error if error?
      console.log {response}
      meshblu.generateAndStoreTokenWithOptions uuid, tokenOptions, (error, response) =>
        debug 'generateAndStoreToken error: ', error if error?
        return callback error if error?
        newToken = response.token
        debug 'generateAndStoreToken', uuid, newToken
        meshblu.revokeToken uuid, token, (error) =>
          callback null, btoa uuid + ':' + newToken

  saveAuthCode: (authCode, clientId, expires, user, callback) =>
    callback()

module.exports = OctobluOauth
