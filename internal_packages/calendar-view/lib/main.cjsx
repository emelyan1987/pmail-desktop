React = require "react"
{ipcRenderer} = require "electron"
{Actions, ComponentRegistry, WorkspaceStore, ProposedTimeCalendarStore} = require "nylas-exports"
CalendarSidebar = require "./calendar-sidebar"
CalendarDetails = require "./calendar-details"

module.exports =

  activate: ->
    WorkspaceStore.defineSheet 'CalendarSheet', {},
      split: ['CalendarSidebar', 'CalendarDetails']
      list: ['CalendarSidebar', 'CalendarDetails']

    ComponentRegistry.register CalendarSidebar,
      location: WorkspaceStore.Location.CalendarSidebar

    ComponentRegistry.register CalendarDetails,
      location: WorkspaceStore.Location.CalendarDetails

    Actions.selectCalendarSheet.listen(@_openCalendarSheet)
    ipcRenderer.on 'open-calendar-sheet', => @_openCalendarSheet()

    ProposedTimeCalendarStore.activate()

  _openCalendarSheet: ->
    ipcRenderer.send 'command', 'application:show-main-window'
    if WorkspaceStore.topSheet() isnt WorkspaceStore.Sheet.CalendarSheet
      Actions.pushSheet(WorkspaceStore.Sheet.CalendarSheet)

  deactivate: ->
    ComponentRegistry.unregister CalendarSidebar
    ComponentRegistry.unregister CalendarDetails

  serialize: -> @state
