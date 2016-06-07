OctobluOauth = require '../src/models/octoblu-oauth'
btoa = require 'btoa'

describe 'OctobluOauth', ->
  beforeEach ->
    @meshblu = generateAccessToken: sinon.stub()
    @MeshbluHttp = sinon.stub().returns @meshblu
    @pepper = 'im-a-pepper'

    @meshbluConfig =
      uuid: 'head'
      token: 'earth'
      server: 'https://meshblu.octoblu.com'
      port: 443

    @dependencies = MeshbluHttp: @MeshbluHttp
    @sut = new OctobluOauth {@meshbluConfig, @pepper}, @dependencies

  describe 'constructor', ->
    it 'should instantiate a OctobluOauth', ->
      expect(@sut).to.exist
