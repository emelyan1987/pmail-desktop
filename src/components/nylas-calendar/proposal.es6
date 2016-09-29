import Utils from '../../flux/models/utils'

export default class Proposal {
  constructor(args = {}) {
    this.id = Utils.generateFakeServerId();
    Object.assign(this, args);

    // This field is used by edgehill-server to lookup the proposals.
    this.proposalId = this.id;
  }
}
