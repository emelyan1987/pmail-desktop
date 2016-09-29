var Reflux = require('reflux')

const SchedulerActions = Reflux.createActions([
  'confirmChoices',
  'changeDuration',
  'clearProposals',
  'removeProposedTime',
  'addToProposedTimeBlock',
  'startProposedTimeBlock',
  'endProposedTimeBlock',
])

for (const key in SchedulerActions) {
  if ({}.hasOwnProperty.call(SchedulerActions, key)) {
    SchedulerActions[key].sync = true
  }
}

PlanckEnv.actionBridge.registerGlobalAction({
  scope: "SchedulerActions",
  name: "confirmChoices",
  actionFn: SchedulerActions.confirmChoices,
});

export default SchedulerActions
