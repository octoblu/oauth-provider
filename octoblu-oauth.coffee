btoa = require 'btoa'
atob = require 'atob'
_ = require 'lodash'
debug = require('debug')('octoblu-oauth:octoblu-oauth')

class OctobluOauth
  constructor: (@meshbluOptions={}, dependencies={}) ->
    @MeshbluHttp = dependencies.MeshbluHttp ? require 'meshblu-http'

  getClient : (clientId, clientSecret, callback) =>
    options = _.cloneDeep @meshbluOptions
    if clientSecret
      options.uuid = clientId
      options.token = clientSecret

    meshblu = new @MeshbluHttp options
    debug 'getClient: about to get device', clientId, clientSecret
    meshblu.device clientId, (error, device) =>
      return callback error if error?
      debug 'getClient found device', device
      callback null, client_id: clientId, client_secret: clientSecret, redirectUri: device.options?.callbackUrl

  grantTypeAllowed : (clientId, grantType, callback) =>
    callback(null, true)

  saveAccessToken : (accessToken, clientId, expires, userId, callback) =>
    callback()

  getAuthCode: (authCode, callback) =>
    token = atob(authCode).split ':'
    debug 'getAuthCode', token
    callback null, {
      clientId: token[0]
      expires: new Date() + 10000
      userId: token[1]
    }

  generateToken: (type, req, callback) =>
    params = _.extend {}, req.query, req.body
    debug 'generateToken', type, params
    if type == 'authorization_code'
      return callback null, btoa params.client_id + ':' + params.uuid + ':' + params.token

    token = atob(params.code).split ':'
    meshblu = new @MeshbluHttp _.extend({}, uuid: token[1], token: token[2], @meshbluOptions)
    debug 'generateToken', token[1], token[2]
    meshblu.generateAndStoreToken token[1], (error, response) =>
      debug 'generateAndStoreToken response', response
      newToken = response.token
      debug 'generateAndStoreToken', token[1], newToken
      meshblu.revokeToken token[1], token[2]
      callback null, btoa token[1] + ':' + newToken

  saveAuthCode: (authCode, clientId, expires, user, callback) =>
    callback()

module.exports = OctobluOauth
