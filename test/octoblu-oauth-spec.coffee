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

  describe '->generateAuthCode', ->
    it 'should exist', ->
      expect(@sut.generateAuthCode).to.exist

    describe 'when called with a uuid and token', ->
      beforeEach ->
        @result = @sut.generateAuthCode 'cyborg', 'rebellion'
      it 'should return a base64 encoded token containing the uuid, a colon, and the token', ->
        expect(@result).to.equal "Y3lib3JnOnJlYmVsbGlvbg=="

  describe '->exchangeAuthCodeForBearerToken', ->
    it 'should exist', ->
      expect(@sut.exchangeAuthCodeForBearerToken).to.exist

    describe 'when called with an auth code', ->
      beforeEach ->
        @sut.exchangeAuthCodeForBearerToken 'c2Vhc2hlbGxzOnN0b3JteQ=='

      it 'make a new meshblu with that access token', ->
        expect(@Meshblu).to.have.been.calledWith 'seashells', 'stormy'

      it 'should make a new meshblu with the uuid and token', ->

