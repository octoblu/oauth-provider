MeshbluHttp = require 'meshblu-http'
When        = require 'when'

class OAuth
  constructor: ({meshbluConfig}) ->
    @meshbluHttp = new MeshbluHttp meshbluConfig

  getAccessToken: =>
    try
      throw new Error JSON.stringify arguments...
    catch error
      console.log error.stack

  getClient: (clientId) =>
    When.promise (reject, resolve) =>
      @meshbluHttp.device clientId, (error, device) =>
        return reject error if error?
        resolve
          clientId: clientId
          redirectUris: [device.options?.callbackUrl]
          grants: ['authorization_code']

  getUserFromClient: =>
    try
      throw new Error JSON.stringify arguments...
    catch error
      console.log error.stack

  saveToken: =>
    try
      throw new Error JSON.stringify arguments...
    catch error
      console.log error.stack

  validateScope: =>
    try
      throw new Error JSON.stringify arguments...
    catch error
      console.log error.stack

  saveAuthorizationCode: =>
    try
      throw new Error JSON.stringify arguments...
    catch error
      console.log error.stack

module.exports = OAuth
