_ = require 'underscore'
React = require 'react'
ReactDOM = require 'react-dom'
moment = require 'moment'

{
 AccountStore,
 CalendarStore,
 Actions,
 CalendarActions,
 Calendar,
 Contact} = require 'nylas-exports'

{OutlineView,
 ScrollRegion,
 Flexbox,
 RetinaImg,
 MiniMonthView,
 OutlineView} = require 'nylas-component-kit'

SearchBar = require './calendar-search-bar'


class CalendarSidebar extends React.Component
  @displayName: 'CalendarSidebar'

  @containerRequired: false
  @containerStyles:
    minWidth: 300
    maxWidth: 300

  constructor: () ->
    super()
    @state =
        curDay: moment()
    @_setStateFromStores()

    Actions.changePrevWeekView.listen(@_changePrevWeekView)
    Actions.changeNextWeekView.listen(@_changeNextWeekView)
    Actions.changeTodayView.listen(@_changeTodayView)

  componentDidMount: =>
    @unsubscribers = []
    @unsubscribers.push AccountStore.listen @_onAccountDataChange
    @unsubscribers.push CalendarStore.listen @_onCalendarSelectionDataChange

  componentWillUnmount: =>
    unsubscribe() for unsubscribe in @unsubscribers

  _onAccountDataChange: =>
    @_setStateFromStores()
  _onCalendarSelectionDataChange: =>
    @_setStateFromStores()

  _setStateFromStores: =>
    CalendarStore.loadData (data)=>
        @setState data
        Actions.changeCalendarData()

  render: =>
    #console.log "sidebar.state ===> ", @state
    #Actions.sendCalendarList(@state.accounts, @state.calendars, @state.contacts)

    <div className="calendar-sidebar-container">
      {@_renderSearchBarSection()}
      {@_renderSelectCalendarSection()}
      {@_renderAccountListSection()}
    </div>

  _renderSearchBarSection: =>
    return
    <div className="sidebar-toolbar-section">
      <span className="search-bar-wrap">
        <SearchBar />
      </span>
      <span className="settings-button-wrap" onClick={@_onClickSettingsButton}>
        <RetinaImg style={width: 24, height: 24} url="nylas://calendar-view/assets/calendar-settings@2x.png" mode={RetinaImg.Mode.ContentPreserve} />
      </span>
    </div>

  _renderSelectCalendarSection: =>
    <div className="select-calendar-section">
      <div className="calendar-title-region">
        <span className="calendar-title">Calendar</span>
        <span className="calendar-collapse-button-wrap" onClick={@_onClickCalendarCollapseButton}>
          <RetinaImg style={width: 20, height: 20} url="nylas://calendar-view/assets/down-arrow@2x.png" mode={RetinaImg.Mode.ContentPreserve} />
        </span>
      </div>
      <div className="select-calendar-wrap">
        <MiniMonthView
          value={@state.curDay.valueOf()}
          onChange={@_onChangeSelDay}
        />
      </div>
    </div>

  _renderAccountListSection: =>
    <div className="account-list-section">
      <div className="accounts-title-region">
        <span className="accounts-title">Accounts</span>
        <span className="accounts-collapse-button-wrap" onClick={@_onClickAccountsCollapseButton}>
          <RetinaImg style={width: 20, height: 20} url="nylas://calendar-view/assets/down-arrow@2x.png" mode={RetinaImg.Mode.ContentPreserve} />
        </span>
      </div>
      <div className="account-calendars-list-region">
        {@_renderCalendarList(@state.accounts)}
      </div>
    </div>

  _renderCalendarList: (accounts) =>
    #console.log accounts
    return unless accounts
    for account in accounts
      <div className="email-account-item" key={account.accountId}>
        <div className="account-wrapper">
            <div className="icon"><RetinaImg name="ic-provider-#{account.provider}.png" mode={RetinaImg.Mode.ContentPreserve} /></div>
            <div className="name">{account.emailAddress}</div>
        </div>
        {@_renderCalendarListByAccount(account.accountId)}
      </div>

  _renderCalendarListByAccount: (accountId) =>
    return <div></div> unless calendars = @state.calendars

    for calendar in calendars
      if calendar.accountId == accountId
          <div className="email-calendar-item" key={calendar.id}>
            <span className="calendar-item-color">
              <svg height="15" width="15">
                <circle cx="10" cy="10" r="5" stroke="white" stroke-width="1" fill={calendar.color} />
              </svg>
            </span>
            <span className="calendar-item-name">
              {calendar.name}
            </span>
            <input type="checkbox" id="#{calendar.id}" className="calendar-item-checkbox" checked={calendar.selected} onChange={@_onClickCalendarCheckbox.bind(@, calendar)}></input>
          </div>



  _onClickCalendarCheckbox: (calendar) =>
    #console.log "CalendarSidebar->_onClickCalendarCheckbox"
    Actions.changeCalendarSelection(calendar)

  _onClickSettingsButton: =>
    console.log "Calendar Settings !!!"

  _onClickCalendarCollapseButton: =>
    console.log "Calendar Collapse Button"

  _onClickAccountsCollapseButton: =>
    console.log "Accounts Collapse Button"

  _onChangeSelDay: (selDayTimestampMiliSeconds) =>
    #console.log selDayTimestampMiliSeconds
    selDayMoment = moment(selDayTimestampMiliSeconds)
    selDayTimestampSeconds = selDayMoment.unix()
    selDayUTC = selDayMoment.format("YYYY MM DD")
    @setState curDay: selDayMoment
    CalendarActions.changeCurrentMoment(selDayMoment)

  _changePrevWeekView: (changeDay) =>
    @setState curDay: changeDay

  _changeNextWeekView: (changeDay) =>
    @setState curDay: changeDay

  _changeTodayView: (today) =>
    @setState curDay: today

module.exports = CalendarSidebar
