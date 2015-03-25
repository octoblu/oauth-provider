btoa = require 'btoa'
class OctobluOauth
  constructor: ->

  generateAuthCode: (uuid, token) =>
    btoa(uuid+ ':' + token)

module.exports = OctobluOauth