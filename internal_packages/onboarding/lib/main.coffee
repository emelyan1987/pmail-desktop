PageRouter = require "./page-router"
{Actions, SystemStartService, WorkspaceStore, ComponentRegistry} = require 'nylas-exports'

url = require('url')
{remote} = require 'electron'
protocol = remote.require('protocol')
qs = require("querystring")

module.exports =
  item: null

  activate: (@state) ->
    # This package does nothing in other windows
    return unless PlanckEnv.getWindowType() is 'onboarding'

    WorkspaceStore.defineSheet 'Main', {root: true},
      list: ['Center']

    ComponentRegistry.register PageRouter,
      location: WorkspaceStore.Location.Center

    if (PlanckEnv.config.get('nylas.accounts')?.length ? 0) is 0
      startService = new SystemStartService()
      startService.checkAvailability().then (available) =>
        return unless available
        startService.doesLaunchOnSystemStart().then (launchesOnStart) =>
          startService.configureToLaunchOnSystemStart() unless launchesOnStart


    # Register Custom URL Scheme for Cloud Storage
    protocol.unregisterProtocol('gmail-auth') # gmail-auth-protocol

    # Now register the new protocol
    protocol.registerStringProtocol 'gmail-auth', (request, callback) =>
      {host:host, query:rawQuery} = url.parse(request.url) # href, protocol, host, auth, hostname, port, pathname, search, path, query, hash
      params = qs.parse(rawQuery)


      switch host
        when "auth_success"
          #alert JSON.stringify(params)
          Actions.googleAuthenticationSucceeded params
