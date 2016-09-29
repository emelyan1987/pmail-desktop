Actions = require './onboarding-actions'
NylasStore = require 'nylas-store'

class NylasApiEnvironmentStore extends NylasStore
  constructor: ->
    @listenTo Actions.changeAPIEnvironment, @_setEnvironment
    @_setEnvironment('production') unless PlanckEnv.config.get('env')

  getEnvironment: ->
    PlanckEnv.config.get('env')

  _setEnvironment: (env) ->
    throw new Error("Environment #{env} is not allowed") unless env in ['development', 'experimental', 'staging', 'production']
    PlanckEnv.config.set('env', env)
    @trigger()

module.exports = new NylasApiEnvironmentStore()
