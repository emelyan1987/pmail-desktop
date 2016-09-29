NylasStore = require 'nylas-store'
_ = require 'underscore'
{Actions,
 FileProviderStore,
 FocusedPerspectiveStore} = require 'nylas-exports'

SidebarActions = require './sidebar-actions'



class SidebarStore extends NylasStore

  constructor: ->
    @_registerListeners()
    @_selectedProvider = undefined

  _registerListeners: ->
    @listenTo Actions.didLoadCloudUserInfo, @_onDidLoadCloudUserInfo
    @listenTo Actions.didRemoveFileProvider, @trigger
    @listenTo SidebarActions.selectFileProvider, @_onSelectFileProvider

  selectedProvider:->
    @_selectedProvider

  emailProviders: ->
    FileProviderStore.emailProviders()

  cloudProviders: ->
    FileProviderStore.cloudProviders()

  _onDidLoadCloudUserInfo:(info)=>
    if @_selectedProvider && @_selectedProvider.provider == info.cloudType
      _.each @cloudProviders(), (provider)=>
        if @_selectedProvider.provider == provider.provider
          @_selectedProvider = provider
          Actions.selectFileProvider(@_selectedProvider)


    console.log "SidebarStore->onDidLoadCloudUserInfo"
    console.log info
    @trigger()

  _onSelectFileProvider:(provider)=>
    @_selectedProvider = provider
    Actions.selectFileProvider(@_selectedProvider)

module.exports = new SidebarStore()
