_ = require 'underscore'
_str = require 'underscore.string'
React = require 'react'

{Actions,
 ComponentRegistry,
 WorkspaceStore} = require "nylas-exports"

Sheet = require './sheet'
Flexbox = require './components/flexbox'
RetinaImg = require './components/retina-img'
Utils = require './flux/models/utils'

menuList = [
  {
    id: "menu-mail"
    title: "Mail"
  }
  {
    id: "menu-file"
    title: "File"
  }
  {
    id: "menu-conferences"
    title: "Conferences"
  }
  {
    id: "menu-tracking"
    title: "Email Tracking"
  }
  {
    id: "menu-leads"
    title: "Leads"
  }
  {
    id: "menu-opportunity"
    title: "Opportunity"
  }
]

class Menubar extends React.Component
  @displayName: 'Menubar'

  constructor: (@props) ->
    @state = {
      prevSelItem: ""
      curSelItem: "mail"
    }

  componentDidMount: () ->
    console.log "component Did Mount() " + JSON.stringify(@state)

  componentDidUpdate: (newProps, newState) ->
    console.log "component Did Update() " + JSON.stringify(newState)

  render: =>
    <Flexbox className="menu-item-container" direction="row">
      <span className="menu-item" onClick={@_onSelectMenuMail}>
        <RetinaImg id="mail-item-img" name="ic-menu-mail-select.png" mode={RetinaImg.Mode.ContentPreserve} />
        <div id="mail-item-title" className="menu-item-title-mail">Mail</div>
      </span>
      <span className="menu-item" onClick={@_onSelectMenuCalendar}>
        <RetinaImg id="calendar-item-img" name="ic-menu-calendar-normal.png" mode={RetinaImg.Mode.ContentPreserve} />
        <div id="calendar-item-title" className="menu-item-title">Calendar</div>
      </span>
      <span className="menu-item" onClick={@_onSelectMenuFile}>
        <RetinaImg id="file-item-img" name="ic-menu-file-normal.png" mode={RetinaImg.Mode.ContentPreserve} />
        <div id="file-item-title" className="menu-item-title">File</div>
      </span>
    </Flexbox>

  _selectViewItem: (itemName) =>
    document.getElementById("#{itemName}-item-img").src = "../static/images/sheets/ic-menu-#{itemName}-select@2x.png"
    document.getElementById("#{itemName}-item-title").style.color = "turquoise"

  _deselectViewItem: (itemName) =>
    document.getElementById("#{itemName}-item-img").src = "../static/images/sheets/ic-menu-#{itemName}-normal@2x.png"
    document.getElementById("#{itemName}-item-title").style.color = "black"

  _onSelectMenuMail: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "mail"
    return unless @state.prevSelItem isnt @state.curSelItem

    console.log "Mail View click"
    @_deselectViewItem(@state.prevSelItem)
    @_selectViewItem(@state.curSelItem)

    # Display "Mail" View
    Actions.selectRootSheet(WorkspaceStore.Sheet.Threads)

  _onSelectMenuCalendar: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "calendar"
    return unless @state.prevSelItem isnt @state.curSelItem

    @_deselectViewItem(@state.prevSelItem)
    @_selectViewItem(@state.curSelItem)

    # Display "Calendar" View
    Actions.selectCalendarSheet()

  _onSelectMenuPeople: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "contact"
    return unless @state.prevSelItem isnt @state.curSelItem

    console.log "People View click"
    @_deselectViewItem(@state.prevSelItem)
    @_selectViewItem(@state.curSelItem)

    Actions.selectContactSheet()
    alert "Now Working Feature!"

  _onSelectMenuFile: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "file"
    return unless @state.prevSelItem isnt @state.curSelItem

    console.log "File View click"
    @_deselectViewItem(@state.prevSelItem)
    @_selectViewItem(@state.curSelItem)

    Actions.selectRootSheet(WorkspaceStore.Sheet.Files)

  _onSelectMenuConference: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "conference"
    return unless @state.prevSelItem isnt @state.curSelItem

    console.log "Conferences click"
    @_deselectViewItem(@state.prevSelItem)
    @_selectViewItem(@state.curSelItem)

    #alert "Now no working !"

  _onSelectMenuTracking: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "tracking"
    return unless @state.prevSelItem isnt @state.curSelItem

    console.log "tracking click"
    @_deselectViewItem(@state.prevSelItem)
    @_selectViewItem(@state.curSelItem)

    #alert "Now no working !"

  _onSelectMenuLeads: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "unsubscribe"
    return unless @state.prevSelItem isnt @state.curSelItem

    console.log "Leads click"
    @_deselectViewItem(@state.prevSelItem)
    @_selectViewItem(@state.curSelItem)

    #alert "Now no working !"

  _onSelectMenuOpportunity: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "settings"
    return unless @state.prevSelItem isnt @state.curSelItem

    console.log "Opportunity click"
    @_deselectViewItem(@state.prevSelItem)
    @_selectViewItem(@state.curSelItem)

    #alert "Now no working !"

  _onSelectView: (item) =>
    alert item + "selected."

    switch item
      when "menu-mail" then console.log "mail"
      when "menu-calendar" then console.log "Calendar"
      when "menu-people" then console.log "People"
      when "menu-file" then console.log "file"
      when "menu-conferences" then console.log "Conferences"
      when "menu-tracking" then console.log "tracking"
      when "menu-leads" then console.log "Leads"
      when "menu-opportunity" then console.log "Opportunity"

module.exports = Menubar
