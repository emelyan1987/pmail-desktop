React = require "react"
{ipcRenderer} = require "electron"
{Actions, ComponentRegistry, WorkspaceStore} = require "nylas-exports"
ContactSheetSidebar = require "./sidebar"
ContactDetails = require "./contact-details"

module.exports =

  activate: ->
    React = require 'react'

    WorkspaceStore.defineSheet 'Contact', {},
      split: ['ContactSheetSidebar', 'ContactDetails']
      list: ['ContactSheetSidebar', 'ContactDetails']

    ComponentRegistry.register ContactSheetSidebar,
      location: WorkspaceStore.Location.ContactSheetSidebar

    ComponentRegistry.register ContactDetails,
      location: WorkspaceStore.Location.ContactDetails

    Actions.selectContactSheet.listen(@_openContactSheet)
    ipcRenderer.on 'open-contactview', => @_openContactSheet()

  _openContactSheet: ->
    ipcRenderer.send 'command', 'application:show-main-window'
    if WorkspaceStore.topSheet() isnt WorkspaceStore.Sheet.Contact
      Actions.pushSheet(WorkspaceStore.Sheet.Contact)

  deactivate: ->
    ComponentRegistry.unregister ContactSheetSidebar
    ComponentRegistry.unregister ContactContents

  serialize: -> @state
