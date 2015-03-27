btoa = require 'btoa'
atob = require 'atob'
_ = require 'lodash'

class OctobluOauth
  constructor: (@meshbluOptions={}, dependencies={}) ->
    @Meshblu = dependencies.Meshblu ? require './meshblu'


  getClient : (clientId, clientSecret, callback) =>
    meshblu = new @Meshblu _.extend({}, uuid: clientId, token: clientSecret, @meshbluOptions)
    meshblu.device clientId, (error, device) =>
      return callback error if error?
      callback null, client_id: clientId, client_secret: clientSecret, redirectUri: device.options?.callbackUrl

  grantTypeAllowed : (clientId, grantType, callback) =>
    callback(null, true)

  saveAccessToken : (accessToken, clientId, expires, userId, callback) =>
    callback()

  getAuthCode: (authCode, callback) =>
    token = atob(authCode).split ':'
    callback null, {
      clientId: token[0]
      expires: new Date() + 10000
      userId: token[1]
    }

  generateToken: (type, req, callback) =>
    params = _.extend {}, req.query, req.body
    if type == 'authorization_code'
      return callback null, btoa params.client_id + ':' + params.uuid + ':' + params.token

    token = atob(params.code).split ':'
    meshblu = new @Meshblu _.extend({}, uuid: token[1], token: token[2], @meshbluOptions)
    meshblu.generateAndStoreToken token[1], (error, response) =>
      newToken = response.token
      meshblu.revokeToken token[1], token[2]
      callback null, btoa token[1] + ':' + newToken

  saveAuthCode: (authCode, clientId, expires, user, callback) =>
    callback()

module.exports = OctobluOauth