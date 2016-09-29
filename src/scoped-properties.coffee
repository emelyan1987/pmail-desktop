CSON = require 'season'
{CompositeDisposable} = require 'event-kit'

module.exports =
class ScopedProperties
  @load: (scopedPropertiesPath, callback) ->
    CSON.readFile scopedPropertiesPath, (error, scopedProperties={}) ->
      if error?
        callback(error)
      else
        callback(null, new ScopedProperties(scopedPropertiesPath, scopedProperties))

  constructor: (@path, @scopedProperties) ->

  activate: ->
    for selector, properties of @scopedProperties
      PlanckEnv.config.set(null, properties, scopeSelector: selector, source: @path)
    return

  deactivate: ->
    for selector of @scopedProperties
      PlanckEnv.config.unset(null, scopeSelector: selector, source: @path)
    return
