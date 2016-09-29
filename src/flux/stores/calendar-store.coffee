_             = require 'underscore'
NylasStore    = require 'nylas-store'
Actions       = require '../actions'
AccountStore  = require './account-store'
DatabaseStore = require './database-store'
Calendar      = require '../models/calendar'

CalendarColors = [
  "rgba(192,57,43,0.35)"
  "rgba(229,126,45,0.35)"
  "rgba(241,196,48,0.35)"
  "rgba(97,205,114,0.35)"
  "rgba(59,129,58,0.35)"
  "rgba(84,188,156,0.35)"
  "rgba(52,152,219,0.35)"
  "rgba(34,109,160,0.35)"
  "rgba(142,68,173,0.35)"
  "rgba(154,89,181,0.35)"
  "rgba(235,79,147,0.35)"
  "rgba(127,140,141,0.35)"
]

class CalendarStore extends NylasStore

  constructor: ->
    @_registerListeners()

    @_calendars = []
    @loadData()

  _registerListeners: ->
    AccountStore.listen @_onAccountStoreChanged
    DatabaseStore.listen @_onDatabaseStoreChanged
    @listenTo Actions.changeCalendarSelection, @_onChangeCalendarSelection
    @listenTo Actions.sendEventSuccess, @trigger

  loadData:(callback)->
    console.log "CalendarStore->loadData"
    @_accounts = AccountStore.accounts()

    DatabaseStore.findAll(Calendar).then (calendars) =>
      _.each calendars, (calendar, index)=>
        color = CalendarColors[index%CalendarColors.length]

        if !_.contains _.pluck(@_calendars,"id"), calendar.id
          @_calendars.push _.extend(calendar, {color:color, selected:true})
          PlanckEnv.config.set "calendar.colors.#{calendar.id}", color


      if callback
        callback
          accounts: @_accounts
          calendars: @_calendars



  accounts:->
    @_accounts

  calendars: (accountId)->
    return @_calendars unless accountId

    calendars = [];
    _.each @_calendars,(calendar)=>
      calendars.push calendar if calendar.accountId == accountId

    return calendars

  calendar: (calendarId)->
    _.findWhere @_calendars, {id:calendarId}

  calendarColorIndex: (calendarId)=>
    return 0 unless calendar=@calendar(calendarId)
    CalendarColors.indexOf(calendar.color)

  calendarColor: (calendarId)=>
    return 0 unless calendar=@calendar(calendarId)

    calendar.color

  selectedCalendars: =>
    calendars = [];
    _.each @_calendars,(calendar)=>
      calendars.push calendar if calendar.selected

    return calendars

  writableCalendars: =>
    calendars = [];
    _.each @_calendars,(calendar)=>
      calendars.push calendar unless calendar.readOnly
    console.log "CalendarStore->writableCalendars", calendars
    return calendars

  _onChangeCalendarSelection:(calendar)->
    @_calendars = _.map @_calendars, (cal)=>
      if calendar.id == cal.id
        cal.selected = not calendar.selected
        #console.log "_onChangeCalendarSelection", JSON.stringify(calendar), JSON.stringify(cal)
      return cal
    @trigger()

  _onAccountStoreChanged:->
    #@trigger()
    #accounts = AccountStore.accounts()
    #if @_accounts.length != accounts.length
    #@trigger()
#    else
#      curAccountIds = _.pluck(@_accounts, "id").sort()
#      newAccountIds = _.pluck(accounts, "id").sort()
#
#      changed = curAccountIds.every (item, index)=>
#        return item != newAccountIds[index]
#
#      @trigger() if changed

  _onDatabaseStoreChanged:->
#    DatabaseStore.findAll(Calendar).then (calendars) =>
#      if @_calendars.length != calendars.length
#        @trigger()
#      else
#        curCalendarIds = _.pluck(@_calendars, "id").sort()
#        newCalendarIds = _.pluck(calendars, "id").sort()
#
#        changed = curCalendarIds.every (item, index)=>
#          return item != newCalendarIds[index]
#
#        @trigger() if changed


module.exports = new CalendarStore()
