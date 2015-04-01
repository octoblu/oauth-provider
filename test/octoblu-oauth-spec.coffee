OctobluOauth = require '../octoblu-oauth'
btoa = require 'btoa'

describe 'OctobluOauth', ->
  beforeEach ->
    @meshblu = generateAccessToken: sinon.stub()
    @Meshblu = sinon.stub().returns @meshblu

    @meshbluJSON =
      uuid: 'head'
      token: 'earth'
      server: 'https://meshblu.octoblu.com'
      port: 443

    @dependencies = Meshblu: @Meshblu
    @sut = new OctobluOauth @meshbluJSON, @dependencies

  describe 'constructor', ->
    it 'should instantiate a OctobluOauth', ->
      expect(@sut).to.exist

