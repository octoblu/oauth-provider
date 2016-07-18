_             = require 'lodash'
OctobluRaven  = require 'octoblu-raven'
MeshbluConfig = require 'meshblu-config'
Server        = require './src/server'

class Command
  constructor: ->
    @serverOptions =
      port:           process.env.PORT || 80
      disableLogging: process.env.DISABLE_LOGGING == 'true'
      octobluBaseUrl: process.env.OCTOBLU_BASE_URL ? 'https://app.octoblu.com'
      meshbluConfig:  new MeshbluConfig().toJSON()
      pepper:         process.env.PEPPER
      octobluRaven:   new OctobluRaven()

  handleErrors: =>
    @serverOptions.octobluRaven.worker().handleErrors()

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    @panic new Error('Missing required environment variable: OCTOBLU_BASE_URL') if _.isEmpty @serverOptions.octobluBaseUrl
    @panic new Error('Missing required environment variable: PEPPER') if _.isEmpty @serverOptions.pepper

    server = new Server @serverOptions
    server.run (error) =>
      return @panic error if error?

      {address,port} = server.address()
      console.log "Server listening on #{address}:#{port}"

command = new Command()
command.handleErrors()
command.run()
