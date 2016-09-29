import Task from './task';
import Actions from '../actions';
import Event from '../models/event';
import NylasAPI from '../nylas-api';
import {APIError} from '../errors';
import SoundRegistry from '../../sound-registry';
import DatabaseStore from '../stores/database-store';

export default class SaveEventTask extends Task {

  constructor(event, isNotify, isUpdate) {
    super();
    this.event = event;
    this.isNotify = isNotify;
    this.isUpdate = isUpdate;

    console.log("SaveEventTask->constructor", this.event, this.isNotify, this.isUpdate);
  }

  label() {
    if(this.isNotify)
      return "Sending invite...";
    return "Saving event...";
  }

  performRemote() {
    //alert("SaveEventTask->performRemote");
    //alert(JSON.stringify(this.event));
    return this.assertEventValidity()
    .then(this.saveEvent)
    .then((responseJSON) => {
      //alert("SaveEventTask->performRemote response");
      //alert(JSON.stringify(responseJSON));
      event = new Event().fromJSON(responseJSON);
      event.clientId = this.event.clientId

      this.event = event;
      return DatabaseStore.inTransaction((t) =>
          t.persistModel(event)
      );
    })
    .then(this.onSuccess)
    .catch(this.onError);
  }

  assertEventValidity = () => {
    if (!this.event.calendarId) {
      console.log("SaveEventTask->assertEventValidity - you must populate `calendarId` before saving event.");
      return Promise.reject(new Error("SaveEventTask - you must populate `calendarId` before saving event."));
    }

    return Promise.resolve();
  }

  // This function returns a promise that resolves to the draft when the draft has
  // been sent successfully.
  saveEvent = () => {
    console.log("SaveEventTask->saveEvent", this.event, this.isNotify, this.isUpdate);
    return NylasAPI.makeRequest({
      path: "/events"+(this.isUpdate?"/"+this.event.id:"")+(this.isNotify?"?notify_participants=true":""),
      accountId: this.event.accountId,
      method: this.isUpdate?'PUT':'POST',
      body: this.event.toJSON(),
      timeout: 1000 * 60 * 5, // We cannot hang up a send - won't know if it sent
      returnsModel: false,
    })
    .catch((err) => {
      return Promise.reject(err)
    });
  }


  onSuccess = () => {
    Actions.sendEventSuccess({event: this.event, eventClientId: this.event.clientId});

    // Play the sending sound
    if (PlanckEnv.config.get("core.sending.sounds")) {
      //alert("Sounding");
      SoundRegistry.playSound('send');
    }

    return Promise.resolve(Task.Status.Success);
  }

  onError = (err) => {
    //alert("SaveEventTask->onError");
    alert(JSON.stringify(err));
    let message = err.message;

    if (err instanceof APIError) {
      if (!NylasAPI.PermanentErrorCodes.includes(err.statusCode)) {
        return Promise.resolve(Task.Status.Retry);
      }

      message = `Sorry, this message could not be sent. Please try again, and make sure your message is addressed correctly and is not too large.`;
      if (err.statusCode === 402 && err.body.message) {
        if (err.body.message.indexOf('at least one recipient') !== -1) {
          message = `This message could not be delivered to at least one recipient. (Note: other recipients may have received this message - you should check Sent Mail before re-sending this message.)`;
        } else {
          message = `Sorry, this message could not be sent because it was rejected by your mail provider. (${err.body.message})`;
          if (err.body.server_error) {
            message += `\n\n${err.body.server_error}`;
          }
        }
      }
    }

    Actions.eventSendingFailed({
      eventClientId: this.event.clientId,
      errorMessage: message,
    });
    PlanckEnv.reportError(err);

    return Promise.resolve([Task.Status.Failed, err]);
  }
}
