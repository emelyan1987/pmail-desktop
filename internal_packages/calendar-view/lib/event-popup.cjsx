_ = require 'underscore'
{remote} = require 'electron'
React = require 'react'
ReactDOM = require 'react-dom'
{findDOMNode} = require 'react-dom'
ReactSelectize = require "react-selectize"
SimpleSelect = ReactSelectize.SimpleSelect
MultiSelect = ReactSelectize.MultiSelect
moment = require 'moment'

{Actions,
 Utils,
 Contact,
 ContactStore,
 Event,
 DatabaseStore,
 SaveEventTask,
 EventRSVPTask,
 SchedulerActions} = require 'nylas-exports'

{RetinaImg,
 ScrollRegion,
 TabGroupRegion,
 DatePicker,
 TimePicker,
 ParticipantsTextField,
 ButtonDropdown,
 Menu} = require 'nylas-component-kit'

CalendarPickerPopover = require './calendar-picker-popover'

class CalendarEventPopup extends React.Component
  @displayName: 'CalendarEventPopup'

  @propTypes:
    dismiss: React.PropTypes.func
    event: React.PropTypes.object
    accounts: React.PropTypes.array
    calendars: React.PropTypes.array
    contacts: React.PropTypes.array
    startTime: React.PropTypes.object
    endTime: React.PropTypes.object


  constructor: (props) ->
    super(props)
    @state =
        fields: @_getFields()
        participants: props.contacts.map (contact) -> {label: contact.displayName(), value: contact.email}
        calendars: @_getWritableCalendars()
        accounts: props.accounts.map (account) -> {groupId: account.id, title: account.emailAddress}


    console.log "EventPopover->constructor", @state, @props

  _getWritableCalendars: =>
    calendars = []
    @props.calendars.forEach (calendar) =>
        unless calendar.readOnly
            calendars.push {groupId: calendar.accountId, id: calendar.id, value: calendar.name, label: calendar.name}
    return calendars

  _getFields: =>
    if @props.event
        @event = @props.event

        calendar = _.findWhere @props.calendars, {id:@event.calendarId}
        console.log "EventPopup->event", @event

        allDay = @event.when.object=='date' || @event.when.object=='datespan'

        title: @event.title
        allDay: allDay
        startTime: moment(@event.start*1000)
        endTime: moment(@event.end*1000)
        location: @event.location
        participants: @event.participants
        calendar: {groupId: calendar.accountId, id: calendar.id, value: calendar.name, label: calendar.name}
    else
        title: ''
        allDay: false
        startTime: if @props.startTime then @props.startTime else moment()
        endTime: if @props.endTime then @props.endTime else moment()
        location: ''
        participants: []
        calendar: null


  _getWhen: =>
    fields = @state.fields
    startTime = fields.startTime
    endTime = fields.endTime

    if fields.allDay
        startDateStr = startTime.format('YYYY-MM-DD')
        endDateStr = endTime.format('YYYY-MM-DD')

        interval = moment(endDateStr,'YYYY-MM-DD').diff moment(startDateStr, 'YYYY-MM-DD'), "days"
        console.log "EventPopup->_getWhen", endDateStr, startDateStr, interval
        if interval > 0
            start_date: startDateStr
            end_date: endDateStr
        else
            date: startDateStr

    else
        interval = endTime.diff startTime, "seconds"
        if interval > 0
            start_time: startTime.unix()
            end_time: endTime.unix()
        else
            time: startTime.unix()


  _getParticipants: =>
    @state.fields.participants.map (contact)->
        name: contact.name
        email: contact.email
        status: "noreply"


  _validateFields: =>
    unless @state.fields.calendar
        remote.dialog.showMessageBox
            type: 'warning'
            message: 'Calendar field required'
            buttons: ["OK"]
        return false
    return true


  render: =>
    #console.log "EventPopover->render", @state

    <div className="event-popup-wrap">
        <div className="event-popup-body">
            <div className="cover" style={display:if @event && @event.readOnly then 'block' else 'none'}/>
            {@_renderEventTitleRow()}
            {@_renderDurationRow()}
            {@_renderLocationRow()}
            {@_renderPeopleRow()}
            {@_renderCalendarsRow()}
        </div>
        <div className="event-popup-footer">
            {@_renderButtons()}
        </div>
    </div>

  _renderEventTitleRow: =>
    <div className="title-wrap">
      <input type="text" className="title-input" placeholder="Enter event title..." value={@state.fields.title} onChange={@_onTitleChanged}/>
    </div>

  _renderDurationRow: =>
    startVal = @state.fields.startTime.valueOf()
    endVal = @state.fields.endTime.valueOf()

    <TabGroupRegion>
        <div className="duration-wrap">
          <div className="all-day-wrap">
            <input type="checkbox" className="all-day-checkbox" checked={@state.fields.allDay} onChange={@_onAllDayChanged}/>
            <div className="all-day-label">All Day</div>
          </div>
          <div className="time-wrap">
            <DatePicker value={startVal} onChange={@_onStartTimeChanged} disabled/>&nbsp;
            <TimePicker value={startVal} onChange={@_onStartTimeChanged} />
          </div>
          <div className="arrow-wrap">
            <div className="top-arrow"></div>
            <div className="bottom-arrow"></div>
          </div>
          <div className="time-wrap">
            <DatePicker value={endVal} onChange={@_onEndTimeChanged} />&nbsp;
            <TimePicker value={endVal} onChange={@_onEndTimeChanged} relativeTo={startVal} />
          </div>
        </div>
    </TabGroupRegion>

  _renderLocationRow: =>
    <div className="location-wrap">
      <div>
        <span>Location</span>
        <input type="text" className="location-input" placeholder="Type an address or a place name" value={@state.fields.location} onChange={@_onLocationChanged} data-field="location"/>
      </div>
      <div>
        <span>Time zone</span>
        <div>{moment().tz(Utils.timeZone).format("z")}</div>
      </div>
    </div>

  _renderPeopleRow: =>
    <div className="participants-wrap">
        <ParticipantsTextField
              field = "to"
              className = "participant-field"
              change={@_onParticipantsChanged}
              participants={to:@state.fields.participants} />
    </div>

  _renderCalendarsRow: =>
    <div className="calendars-wrap">
      <span>Calendars</span>
      <SimpleSelect
        dropdownDirection=-1
        className="react-selectize"
        placeholder = "Select calendar"
        groups={@state.accounts}
        options = {@state.calendars}
        value={@state.fields.calendar}
        onValueChange = {@_onCalendarChanged}>
      </SimpleSelect>
    </div>

  _renderButtons: =>
    <div className="buttons-wrap">
      {
        if @event && @event.readOnly
            me = @event.participantForMe()

            unless me
                <div></div>
            else
                actions = [["yes", "Accept"], ["maybe", "Maybe"], ["no", "Decline"]]

                actions.map ([status, label]) =>
                    classes = "btn btn-rsvp "
                    classes += status if me.status is status
                    <button key={status} className={classes} onClick={=> @_rsvp(status)}>
                      {label}
                    </button>
        else
            <button className="btn btn-emphasis" onClick={@_onClickSaveButton}>Save</button>
      }

    </div>

  _rsvp: (status) =>
    me = @event.participantForMe()
    Actions.queueTask(new EventRSVPTask(@event, me.email, status))
    Actions.closePopover()

  _onTitleChanged: (event) =>
    #console.log "EventPopup->_onTitleChanged", event
    fields = @state.fields
    fields.title = event.target.value
    #console.log "EventPopup->Changed fields", fields
    @setState({fields})

  _onLocationChanged: (event) =>
    #console.log "EventPopup->_onLocationChanged", event
    fields = @state.fields
    fields.location = event.target.value
    #console.log "EventPopup->Changed fields", fields
    @setState({fields})

  _onAllDayChanged: (event) =>
    #console.log "EventPopup->_onAllDayChanged", event
    fields = @state.fields
    fields.allDay = event.target.checked
    #console.log "EventPopup->Changed fields", fields
    @setState({fields})

  _onStartTimeChanged: (newTimestamp) =>
    #console.log "EventPopup->_onStartTimeChanged", newTimestamp
    newTime = moment(newTimestamp)
    fields = @state.fields
    if newTimestamp<=fields.endTime.valueOf()
        fields.startTime = newTime
        #console.log "EventPopup->Changed fields", fields
        @setState({fields})

  _onEndTimeChanged: (newTimestamp) =>
    #console.log "EventPopup->_onEndTimeChanged", newTimestamp
    newTime = moment(newTimestamp)
    fields = @state.fields

    if newTimestamp>=fields.startTime.valueOf()
        fields.endTime = newTime
        #console.log "EventPopup->Changed fields", fields
        @setState({fields})

  _onParticipantsChanged:(values) =>
     console.log("--------------");
     console.log(values);
     fields = @state.fields
     fields.participants = values.to
     @setState({fields})


  _onCalendarChanged:(value)=>
    #console.log "Selected calendar", value
    fields = @state.fields
    fields.calendar = value
    @setState({fields})

  _onClickSaveButton: =>
    return unless @_validateFields()

    fields = @state.fields

    isUpdate = false
    unless @event
        @event = new Event().fromJSON
          account_id: fields.calendar.groupId
          title: fields.title
          calendar_id: fields.calendar.id
          when: @_getWhen()
          location: fields.location
          participants: @_getParticipants()

    else
        @event.title = fields.title
        @event.calendar_id = fields.calendar.id
        @event.when = @_getWhen()
        @event.location = fields.location
        @event.participants = @_getParticipants()

        isUpdate = true

    isNotify = false
    if fields.participants && fields.participants.length
        choice = remote.dialog.showMessageBox
          type: 'question'
          buttons: ['Send', 'Don\'t Send']
          title: 'Confirm'
          message: 'Would you like to send the invitation to guests?'

        isNotify = choice==0

    console.log "EventPopup->_onClickSaveButton", @event.toJSON()
    Actions.queueTask(new SaveEventTask(@event, isNotify, isUpdate))
    Actions.closePopover()
    SchedulerActions.clearProposals()

module.exports = CalendarEventPopup
