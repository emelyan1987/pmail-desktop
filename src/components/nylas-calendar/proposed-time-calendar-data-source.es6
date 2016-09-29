import Rx from 'rx-lite'
import CalendarDataSource from './calendar-data-source'
import ProposedTimeCalendarStore from './proposed-time-calendar-store'

export default class ProposedTimeCalendarDataSource extends CalendarDataSource {
  constructor({calendarIds, keyword}) {
    super();
    this.calendarIds = calendarIds;
    this.keyword = keyword;
  }

  buildObservable({startTime, endTime, calendarIds}) {
    calendarIds = this.calendarIds;
    keyword = this.keyword;
    const $events = super.buildObservable({startTime, endTime, calendarIds, keyword});

    const $proposedTimes = Rx.Observable.fromStore(ProposedTimeCalendarStore)
      .map((store) => store.proposalsAsEvents())
    const $obs = Rx.Observable.combineLatest([$events, $proposedTimes])
      .map(([calEvents, proposedTimes]) => {
        return {events: calEvents.concat(proposedTimes)}
      })
    this.observable = $obs;
    return $obs;
  }
}
