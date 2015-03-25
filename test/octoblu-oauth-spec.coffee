OctobluOauth = require '../octoblu-oauth'
btoa = require 'btoa'

describe 'OctobluOauth', ->
  beforeEach ->    
    @sut = new OctobluOauth

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
