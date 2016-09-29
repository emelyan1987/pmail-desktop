_ = require 'underscore'
React = require 'react'
ReactDOM = require 'react-dom'
moment = require 'moment'
require 'moment-range'
Dayz = require "./dayz/dayz"
#Popups = require 'react-popups'

{AccountStore,
 DatabaseStore,
 ContactStore,
 Actions,
 Event,
 CalendarStore,
 EventStore,
 SchedulerActions,
 ProposedTimeCalendarDataSource,
 ProposedTimeCalendarStore} = require 'nylas-exports'

{OutlineView,
 ScrollRegion,
 Flexbox,
 RetinaImg,
 NylasCalendar} = require 'nylas-component-kit'

CalendarEventPopup = require "./event-popup"

EventCalendarDataSource = require './event-calendar-data-source'

class CalendarDetails extends React.Component
  @displayName: 'CalendarDetails'

  @containerRequired: false
  @containerStyles:
    minWidth: 800

  @accounts: []
  @calendars: []
  @contacts: []

  constructor: () ->
    super()
    @state = @_getStateFromStores()



  componentDidMount: =>
    @unsubscribers = []
    @unsubscribers.push AccountStore.listen @_onStoreChange
    @unsubscribers.push CalendarStore.listen @_onStoreChange
    @unsubscribers.push ProposedTimeCalendarStore.listen @_onStoreChange
    @unsubscribers.push Actions.changeCalendarData.listen(@_onStoreChange)

  componentWillUnmount: =>
    unsubscribe() for unsubscribe in @unsubscribers

  _onStoreChange: =>
    @setState @_getStateFromStores()

  _getStateFromStores: =>
    selDate: moment()
    dataSource: new ProposedTimeCalendarDataSource({calendarIds:_.pluck(CalendarStore.selectedCalendars(), "id"), keyword:@state?.keyword})

  render: =>
    <Flexbox className="calender-details-container" direction="column" style={order: 0, flexShrink: 1, flex: 1}>
      {@_renderCalendar()}
    </Flexbox>

  _getEventModel: (id) =>
    _.findWhere @state.selEvents, {id:id}


  _renderCalendar: =>
    <NylasCalendar
        dataSource={@state.dataSource}
        currentMoment={@state.selDate}
        onCalendarMouseDown={@_onCalendarMouseDown}
        onEventClick={@_onEventClick}/>



  _getBounds: =>
    return ReactDOM.findDOMNode(@).getBoundingClientRect()

  _onCalendarMouseUp:({event, time, currentView})=>
    #console.log "onCalendarMouseUp", event, event.currentTarget, event.target.closest(".calendar-event")
    return if currentView != NylasCalendar.WEEK_VIEW

    SchedulerActions.addToProposedTimeBlock time if time

    SchedulerActions.endProposedTimeBlock()
    return


  _onCalendarMouseMove:({time, mouseIsDown, currentView})=>
    console.log "onCalendarMouseMove"
    return if !time || !mouseIsDown || currentView != NylasCalendar.WEEK_VIEW
    SchedulerActions.addToProposedTimeBlock time
    return


  _onCalendarMouseDown:({event, time, currentView})=>
    console.log "onCalendarMouseDown", event.target.closest(".calendar-event"), time

    return if !time || currentView != NylasCalendar.WEEK_VIEW

    return if event.target.closest(".calendar-event")

    SchedulerActions.clearProposals()
    SchedulerActions.startProposedTimeBlock time.clone()
    SchedulerActions.addToProposedTimeBlock time.clone()
    SchedulerActions.endProposedTimeBlock()

    clientRect =
          left: event.clientX
          top: event.clientY-10
          right: event.clientX
          bottom: event.clientY

    @_showEventPopup clientRect, time.clone().floor(30, 'minutes')

    return


  _showEventPopup:(clientRect, time) =>

    Actions.openPopover(
        <CalendarEventPopup
            accounts={AccountStore.accounts()}
            calendars={CalendarStore.writableCalendars()}
            contacts={ContactStore.rankedContacts()}
            startTime={time}
            endTime={time.clone().add(30, 'minutes')}/>,
        {originRect: clientRect, direction: 'up'}
    )


  _onEventClick: (e, event) =>
    console.log "CalendarDetails->_onEventClick", e, event

    clientRect = e.currentTarget.getBoundingClientRect()

    console.log "ClientRect", clientRect

    SchedulerActions.clearProposals()
    Actions.openPopover(
        <CalendarEventPopup
            accounts={AccountStore.accounts()}
            calendars={CalendarStore.calendars()}
            contacts={ContactStore.rankedContacts()},
            event={event}/>,
        {originRect: clientRect, direction: 'up'}
    )


  module.exports = CalendarDetails
