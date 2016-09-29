import _ from 'underscore'
import _str from 'underscore.string'
import React, {Component, PropTypes} from 'react'
import ReactDOM from 'react-dom'
import {Actions} from 'nylas-exports'
import {Menu, RetinaImg, FilePicker} from 'nylas-component-kit'
import FileProviderPopover from './file-provider-popover'

export default class AttachActionButton extends React.Component {
  static displayName = "AttachActionButton";

  static propTypes = {
    draftClientId: PropTypes.string.isRequired,
  };

  constructor(props) {
    super(props)
    this.state = {

    };
  }

  componentDidMount() {

  }

  componentWillReceiveProps(newProps) {

  }

  componentWillUnmount() {

  }

  render() {
    return <button
        tabIndex={-1}
        className="btn btn-toolbar btn-attach"
        style={{order: 50}}
        title="Attach file"
        onClick={this._onClick}>
      <RetinaImg name="icon-composer-attachment.png" mode={RetinaImg.Mode.ContentIsMask} />
      <span>&nbsp;</span>
      <RetinaImg name="icon-composer-dropdown.png" mode={RetinaImg.Mode.ContentIsMask} />
    </button>
  }

  _onClick = () => {
    //console.log("AttachActionButton->_onClick");
    //console.log(this);
    const buttonRect = ReactDOM.findDOMNode(this).getBoundingClientRect();
    console.log("AttachActionButtonRect", buttonRect);
    Actions.openPopover(
        <FileProviderPopover
            onSelectProvider={this._onSelectProvider}/>,
        {originRect: buttonRect, direction: 'up'}
    )
  }

  _onSelectProvider = (provider) => {
    console.log("AttachActionButton->_onSelectProvider");

    if(provider.provider == 'local')
      Actions.selectAttachment({messageClientId:this.props.draftClientId, provider:provider});
    else {
      Actions.openModal({
        component: (<FilePicker draftClientId={this.props.draftClientId} provider={provider} onSelect={this._onSelectFiles}/>),
        height: 500,
        width: 750
      });
    }
  }

  _onSelectFiles = (files) => {
    console.log("AttachActionButton->_onSelectFiles");
    console.log(files);
  }
}
