btoa = require 'btoa'
atob = require 'atob'

class OctobluOauth
  constructor: (meshbluJSON, dependencies={}) ->
    @Meshblu = dependencies.Meshblu

  generateAuthCode: (uuid, token) =>
    btoa uuid + ':' + token

  exchangeAuthCodeForBearerToken: (authCode)=>
    uuidAndToken = atob(authCode).split ':'
    meshblu = new @Meshblu uuidAndToken[0], uuidAndToken[1]

module.exports = OctobluOauth