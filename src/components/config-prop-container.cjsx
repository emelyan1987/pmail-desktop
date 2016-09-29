React = require 'react'
_ = require 'underscore'

class ConfigPropContainer extends React.Component
  @displayName: 'ConfigPropContainer'

  constructor: (@props) ->
    @state = @getStateFromStores()

  componentDidMount: =>
    @subscription = PlanckEnv.config.onDidChange null, =>
      @setState(@getStateFromStores())

  componentWillUnmount: =>
    @subscription?.dispose()

  getStateFromStores: =>
    config: @getConfigWithMutators()

  getConfigWithMutators: =>
    _.extend PlanckEnv.config.get(), {
      get: (key) =>
        PlanckEnv.config.get(key)
      set: (key, value) =>
        PlanckEnv.config.set(key, value)
        return
      toggle: (key) =>
        PlanckEnv.config.set(key, !PlanckEnv.config.get(key))
        return
      contains: (key, val) =>
        vals = PlanckEnv.config.get(key)
        return false unless vals and vals instanceof Array
        return val in vals
      toggleContains: (key, val) =>
        vals = PlanckEnv.config.get(key)
        vals = [] unless vals and vals instanceof Array
        if val in vals
          PlanckEnv.config.set(key, _.without(vals, val))
        else
          PlanckEnv.config.set(key, vals.concat([val]))
        return
    }

  render: =>
    React.cloneElement(@props.children, {
      config: @state.config,
      configSchema: PlanckEnv.config.getSchema('core')
    })

module.exports = ConfigPropContainer
