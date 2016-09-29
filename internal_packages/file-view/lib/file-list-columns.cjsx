_ = require 'underscore'
React = require 'react'
classNames = require 'classnames'
{Actions} = require 'nylas-exports'
{InjectedComponentSet, ListTabular, RetinaImg} = require 'nylas-component-kit'


mainCol = new ListTabular.Column
  name: "FileItem"
  flex: 1
  resolver: (thread) =>
    <div style={display: 'flex', alignItems: 'flex-start'}>
      <div className="file-icon-column">
        <RetinaImg name="file icon1" url={"nylas://file-view/assets/ic-email-outlook@2x.png"} mode={RetinaImg.Mode.ContentPreserve} /
      </div>
      <div className="file-info-column">
        <div className="name">File Name</div>
        <div className="time">Updated at 10/02/16 12:30:00</div>
      </div>
    </div>

module.exports =
    Main:   [mainCol]