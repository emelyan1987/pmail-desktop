var Reflux = require('reflux')

const CalendarActions = Reflux.createActions([
  'changeCurrentMoment',
  'changeDataSource'
])

for (const key in CalendarActions) {
  if ({}.hasOwnProperty.call(CalendarActions, key)) {
    CalendarActions[key].sync = true
  }
}

PlanckEnv.actionBridge.registerGlobalAction({
  scope: "CalendarActions",
  name: "changeCurrentMoment",
  actionFn: CalendarActions.changeCurrentMoment,
});

PlanckEnv.actionBridge.registerGlobalAction({
  scope: "CalendarActions",
  name: "changeDataSource",
  actionFn: CalendarActions.changeDataSource,
});

export default CalendarActions
