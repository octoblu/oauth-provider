OctobluOauth = require '../octoblu-oauth'

describe 'OctobluOauth', ->
  beforeEach ->    
    @sut = new OctobluOauth

  describe 'constructor', ->
    it 'should instantiate a OctobluOauth', ->
      expect(@sut).to.exist