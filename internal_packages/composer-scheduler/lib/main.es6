import ProposedTimeEvent from '../../../src/components/nylas-calendar/proposed-time-event'
import ProposedTimePicker from './calendar/proposed-time-picker'
import NewEventCardContainer from './composer/new-event-card-container'
import SchedulerComposerButton from './composer/scheduler-composer-button'
import ProposedTimeMainWindowStore from './proposed-time-main-window-store'
import SchedulerComposerExtension from './composer/scheduler-composer-extension';

import {
  WorkspaceStore,
  ComponentRegistry,
  ExtensionRegistry,
  ProposedTimeCalendarStore,
} from 'nylas-exports'

export function activate() {
  if (PlanckEnv.getWindowType() === 'calendar') {
    ProposedTimeCalendarStore.activate()

    PlanckEnv.getCurrentWindow().setMinimumSize(480, 250)
    WorkspaceStore.defineSheet('Main', {root: true},
      {popout: ['Center']})


    ComponentRegistry.register(ProposedTimePicker,
      {location: WorkspaceStore.Location.Center})
  } else {
    if (PlanckEnv.isMainWindow()) {
      ProposedTimeMainWindowStore.activate()
    }
    ComponentRegistry.register(NewEventCardContainer,
      {role: 'Composer:Footer'});

    ComponentRegistry.register(SchedulerComposerButton,
      {role: 'Composer:ActionButton'});

    ExtensionRegistry.Composer.register(SchedulerComposerExtension)
  }
}

export function serialize() {
}

export function deactivate() {
  if (PlanckEnv.getWindowType() === 'calendar') {
    ProposedTimeCalendarStore.deactivate()
    ProposedTimeMainWindowStore.deactivate()
    ComponentRegistry.unregister(ProposedTimePicker);
  } else {
    ComponentRegistry.unregister(NewEventCardContainer);
    ComponentRegistry.unregister(SchedulerComposerButton);
    ExtensionRegistry.Composer.unregister(SchedulerComposerExtension);
  }
}
