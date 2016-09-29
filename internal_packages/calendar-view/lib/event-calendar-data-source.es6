import {CalendarDataSource} from 'nylas-exports'

const BUFFER_DAYS = 7; // in each direction
const DAYS_IN_VIEW = 7;

export default class EventCalendarDataSource extends CalendarDataSource {

  constructor(calendarIds) {
    super();
    this.calendarIds = calendarIds;
  }

  
  buildObservable({startTime, endTime, calendarIds}) {
      calendarIds = this.calendarIds;
      const events = super.buildObservable({startTime, endTime, calendarIds});
      const obs = events.map((calEvents) => {
          return {events: calEvents}
      })
      this.observable = obs;
      return obs;
  }
}
