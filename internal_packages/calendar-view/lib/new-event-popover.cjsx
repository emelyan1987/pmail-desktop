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
 DatabaseStore} = require 'nylas-exports'

{RetinaImg,
 ScrollRegion,
 DatePicker,
 TimePicker,
 ParticipantsTextField,
 ButtonDropdown,
 Menu} = require 'nylas-component-kit'

CalendarPickerPopover = require './calendar-picker-popover'

class NewEventPopover extends React.Component
  @displayName: 'EventInputPopover'

  @propTypes:
    event: React.PropTypes.object.isRequired
    date: React.PropTypes.object
    accounts: React.PropTypes.array
    calendars: React.PropTypes.array
    contacts: React.PropTypes.array

  constructor: (props) ->
    super(props)
    @state = @getStateFromStore()

  componentDidMount: =>
    @_mounted = true
    @renderCanvas

  componentWillUnmount: =>
    @_mounted = false;

  onHover: (event) =>
    console.log event

  onMouseOut: () =>
    console.log "Emoji Picker"

  onChange: (event) =>
    console.log "onChange for event popover"

  getStateFromStore: () =>
    console.log "getStateFromStore"
    #selContacts = ContactStore.searchContacts("*")
    #console.log "selContacts=====> ", selContacts

  _renderEventTitleRow: =>
    <div className="title-wrap">
      <input type="text" className="title-input" placeholder="Enter event title..."/>
    </div>

  _renderDurationRow: =>
    startVal = @props.date.valueOf()
    endVal = @props.date.add(30, 'minutes').valueOf()

    <div className="duration-wrap">
      <div className="all-day-wrap">
        <input type="checkbox" className="all-day-checkbox"/><br/>
        All Day
      </div>
      <div className="start-time-wrap">
        Start:&nbsp;
        <DatePicker value={startVal} onChange={@_onChangeStartDay} />&nbsp;
        <TimePicker value={startVal} onChange={@_onChangeStartTime} />
      </div>
      <div className="end-time-wrap">
        End:&nbsp;&nbsp;
        <DatePicker value={endVal} onChange={@_onChangeEndDay} />&nbsp;
        <TimePicker value={endVal} onChange={@_onChangeEndTime} />
      </div>
    </div>

  _renderLocationRow: =>
    <div className="location-wrap">
      <div>
        <input type="text" className="location-input" placeholder="Type an address or a place name"/>
      </div>
      <div className="timezone-wrap">
        {moment().tz(Utils.timeZone).format("z")}
      </div>
      <br/>
    </div>

  _renderPeopleRow: =>
    options = @props.contacts.map (contact) -> {key: contact.id, label: contact.name, value: contact.email}
    #console.log options

    <div className="participants-wrap">
      <MultiSelect
        className = "react-selectize"
        placeholder = "Type participants' name or email"
        options = {options}
        onValuesChange = {(values)->console.log values}>
      </MultiSelect>
    </div>

  _renderCalendarsRow: =>
    #console.log "calendars ======> ", @props.calendars
    options = @props.calendars.map (calendar) -> {key: calendar.id, label: calendar.name, value: calendar.name}

    <div className="calendars-wrap">
      <SimpleSelect options = {options} placeholder = "Select calendar" className="SimpleSelect">
      </SimpleSelect>
    </div>

  _dropdownMenu: (items) ->
    itemContent = (item) ->
      <span>
        {item.name}
      </span>

    <Menu items={items}
          itemKey={ (item) -> item.name }
          itemContent={itemContent}
          onSelect={ (item) => @_onClickCalendarItem(item) }
          />

  _onClickCalendarItem: (item) =>
    console.log item

  _temp: =>
      <button className="calendar-popover-button" onClick={@_onOpenCalendarsPopover} ref="button">
        <RetinaImg
          className="calendars-popover-image"
          url="nylas://calendar-view/assets/arrow-down-button@2x.png"
          style={width: 10, height: 20}
          mode={RetinaImg.Mode.ContentPreserve} />
      </button>

  _onOpenCalendarsPopover: =>
    buttonRect = ReactDOM.findDOMNode(@refs.button).getBoundingClientRect()
    newRect =
      left: buttonRect.left + 290
      top: buttonRect.top - 30
      right: buttonRect.right + 290
      bottom: buttonRect.bottom - 30
      width: buttonRect.width
      height: buttonRect.height

    #console.log "======> ", newRect

    #console.log buttonRect, @props.accounts, @props.calendars

    Actions.openPopover(
      <CalendarPickerPopover
        accounts={@props.accounts}
        calendars={@props.calendars} />,
      {originRect: newRect, direction: 'up'}
    )

  _renderSaveButton: =>
    <div className="buttons">
      <button className="confirm-button" onClick={@_onClickSaveButton}>Save</button>
    </div>

  render: =>
    <div className="event-input-popover">
      {@_renderEventTitleRow()}
      {@_renderDurationRow()}
      {@_renderLocationRow()}
      {@_renderPeopleRow()}
      {@_renderCalendarsRow()}
      {@_renderSaveButton()}
    </div>

  _onClickSaveButton: =>
    alert "save"

module.exports = NewEventPopover
