_ = require 'underscore'
React = require 'react'
{Actions} = require 'nylas-exports'
{OutlineView,
 ScrollRegion,
 Flexbox,
 RetinaImg,
 FluxContainer,
 MultiselectList} = require 'nylas-component-kit'
#FileListStore = require './file-list-store'
#FileListColumns = require './file-list-columns'
#FocusContainer = require './focus-container'
#EmptyListState = require './empty-state'


class ContactDetails extends React.Component
  @displayName: 'ContactDetails'
  @containerRequired: false
  @containerStyles:
    minWidth: 800
    maxWidth: 1800

  render: =>
    <div>Contact Details</div>
    ###
    files = FileListStore.dataSource()
    console.log "FileListStore DataSource => "
    console.log files
    <FluxContainer
      stores=[FileListStore]
      getStateFromStores={ -> dataSource: FileListStore.dataSource() }>
      <FocusContainer collection="file">
        <MultiselectList
          columns={FileListColumns.Wide}
          onDoubleClick={@_onDoubleClick}
          emptyComponent={EmptyListState}
          keymapHandlers={@_keymapHandlers()}
          itemPropsProvider={@_itemPropsProvider}
          itemHeight={39}
          className="file-list" />
      </FocusContainer>
    </FluxContainer>


    files = FileListStore.dataSource()
    console.log files
    <div></div>

    <div className = "filelist">
      <div className = "filelist-title">
        <span className="title-file-name">Name</span>
        <span className="title-file-type">Type</span>
        <span className="title-file-size">Size</span>
      </div>
      {files.map((file, i) =>
        <li>{file.filename}</li>
      )}
    </div>
    ###
  _renderFiles: (files) =>
    files.forEach(file) =>
      <div className = "filelist-row">
        <span className="data-file-name">{file.filename}</span>
        <span className="data-file-type">{file.contentType}</span>
        <span className="data-file-size">{file.size}</span>
      </div>

  #################################################

  _itemPropsProvider: (file) ->
    console.log "itemPropsPorvieder ==> "
    console.log file

    props = {}
    props.className = 'sending' if file.id
    props

  _keymapHandlers: =>
    'application:remove-from-view': @_onRemoveFromView

  _onDoubleClick: (file) =>
    console.log "onDoubleClick ==> "
    console.log file

    #unless file.uploadTaskId
    #  Actions.composePopoutDraft(file.clientId)

  # Additional Commands

  _onRemoveFromView: =>
    files = FileListStore.dataSource().selection.items()
    console.log files
    #Actions.destroyDraft(file.clientId) for file in files

module.exports = ContactDetails
