_ = require 'underscore'
React = require 'react'
ReactDOM = require 'react-dom'
moment = require 'moment'

{DatabaseStore,
 AccountStore,
 Actions,
 CalendarActions,
 Calendar} = require 'nylas-exports'

{OutlineView,
 ScrollRegion,
 Flexbox,
 RetinaImg,
 MiniMonthView,
 OutlineView} = require 'nylas-component-kit'

class CalendarPickerPopover extends React.Component
  @displayName: 'CalendarSidebar'

  @containerRequired: true
  @containerStyles:
    minWidth: 300
    maxWidth: 300

  @propTypes:
    accounts: React.PropTypes.array.isRequired
    calendars: React.PropTypes.array.isRequired

  constructor: () ->
    super()

  componentDidMount: =>
    @unsubscribers = []

  componentWillUnmount: =>
    unsubscribe() for unsubscribe in @unsubscribers

  render: =>
    #console.log "calendar picker popover props ===> ", @props

    <div className="calendar-picker-container">
      {@_renderAccountListSection()}
    </div>

  _renderAccountListSection: =>
    <div className="account-list-section">
      <div className="account-calendars-list-region">
        {@_renderCalendarList(@props.accounts)}
      </div>
    </div>

  _renderCalendarList: (accounts) =>
    #console.log accounts
    for account in accounts
      <div className="email-account-item" key={account.accountId}>
        {account.emailAddress}
        {@_renderCalendarListByAccount(account.accountId)}
      </div>

  _renderCalendarListByAccount: (accountID) =>
    return <div></div> unless calendars = @props.calendars

    selCalendars = []
    for cal in calendars
      if cal.accountId == accountID
        selCalendars.push cal
    #console.log selCalendars

    for calendar in selCalendars
      <div className="email-calendar-item" key={calendar.id}>
        {@_renderCalendarCheckbox(calendar.id)}
        <span className="calendar-item-name">
          {calendar.name}
        </span>
      </div>

  _renderCalendarCheckbox: (calendarId) =>
    <span className="calendar-item-color">
      <input type="radio"/>
    </span>

  _onClickCalendarCheckbox: (id) =>
    #console.log "onClickCalendarCheckbox() ==> "
    #console.log id
    # get index of object array
    checkbox_stats = @state.checkbox_stats
    elementPos = checkbox_stats.map((x) -> x.id).indexOf(id)
    chk_stat = checkbox_stats[elementPos].checked
    # set reverse checked state
    if chk_stat == true
      checkbox_stats[elementPos].checked = false
      selected = false
    else
      checkbox_stats[elementPos].checked = true
      selected = true
    #console.log "changed ==> "
    #console.log checkbox_stats

    @setState({checkbox_stats: checkbox_stats})

    Actions.changeCalendarData(id, selected)

module.exports = CalendarPickerPopover
