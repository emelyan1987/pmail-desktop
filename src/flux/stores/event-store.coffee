_             = require 'underscore'
NylasStore    = require 'nylas-store'
Actions       = require '../actions'
CalendarStore  = require './calendar-store'
DatabaseStore = require './database-store'
Calendar      = require '../models/calendar'
Event      = require '../models/event'


class EventStore extends NylasStore

  constructor: ->
    @_registerListeners()

    @_events = []

  _registerListeners: ->
    #@listenTo Actions.changeCalendarSelection, @_onChangeCalendarSelection

  loadEvents:(callback)->

    @calendarIds = _.pluck(CalendarStore.selectedCalendars(), "id");
    DatabaseStore.findAll(Event).where([Event.attributes.calendarId.in(@calendarIds)]).then (events) =>
      uniquedEvents = _.uniq events, false, (model) -> model.id
      callback uniquedEvents



module.exports = new EventStore()
