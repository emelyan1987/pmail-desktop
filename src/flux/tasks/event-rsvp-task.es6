import Task from './task';
import Actions from '../actions';
import Event from '../models/event';
import {APIError} from '../errors';
import Utils from '../models/utils';
import DatabaseStore from '../stores/database-store';
import NylasAPI from '../nylas-api';

export default class EventRSVPTask extends Task {
  constructor(event, RSVPEmail, RSVPResponse) {
    super();
    this.event = event;
    this.RSVPEmail = RSVPEmail;
    this.RSVPResponse = RSVPResponse;
  }

  performLocal() {
    return DatabaseStore.inTransaction((t) => {
      return t.find(Event, this.event.id).then((updated) => {
        this.event = updated || this.event;
        this._previousParticipantsState = Utils.deepClone(this.event.participants);

        for (const p of this.event.participants) {
          if (p.email === this.RSVPEmail) {
            p.status = this.RSVPResponse;
          }
        }

        return t.persistModel(this.event);
      })
    });
  }

  performRemote() {
    const {accountId, id} = this.event;

    return NylasAPI.makeRequest({
      accountId,
      path: "/send-rsvp",
      method: "POST",
      body: {
        event_id: id,
        status: this.RSVPResponse,
      },
      returnsModel: true,
    })
    .then(this.onSuccess)
    .catch(APIError, (err) => {
      this.event.participants = this._previousParticipantsState;
      return DatabaseStore.inTransaction((t) =>
        t.persistModel(this.event)
      ).thenReturn(Task.Status.Failed, err);
    });
  }

  onSuccess = () => {
    //alert("EventRSVPTask->onSuccess");


    Actions.sendEventSuccess({event: this.event, eventClientId: this.event.clientId});

    // Play the sending sound
    if (PlanckEnv.config.get("core.sending.sounds")) {
      //alert("Sounding");
      SoundRegistry.playSound('send');
    }

    return Promise.resolve(Task.Status.Success);
  }
  onOtherError() {
    return Promise.resolve();
  }

  onTimeoutError() {
    return Promise.resolve();
  }
}
