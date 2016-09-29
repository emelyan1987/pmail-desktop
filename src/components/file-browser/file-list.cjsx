_ = require 'underscore'
React = require 'react'
ReactDOM = require 'react-dom'
filesize = require 'filesize'

classNames = require 'classnames'
{Actions, Utils, IconUtils, FileStore} = require 'nylas-exports'
{ScrollRegion,
 Flexbox,
 RetinaImg,
 FluxContainer,
 Spinner} = require 'nylas-component-kit'

FileListContextMenu = require './file-list-context-menu'


class FileList extends React.Component
  @displayName: 'FileList'
  @containerRequired: false
  @containerStyles:
    minWidth: 400
    maxWidth: 500

  constructor:(props) ->
    super(props)
    @state =
        progressing: FileStore.isProgressing()
        msg: FileStore.message()
        list: FileStore.dataSource()
        selections: FileStore.selections()
        selectedProvider: FileStore.selectedProvider()
        locations: FileStore.locations()


  componentDidMount: =>
    @_unlisteners = []
    @_unlisteners.push FileStore.listen @_onDataChange

    if not @props.selector
        ReactDOM.findDOMNode(@).addEventListener('contextmenu', @_onShowContextMenu)

    if @props.provider
        Actions.selectFileProvider(@props.provider)

    if @props.selector
        #Actions.emptySelectFiles()
        FileStore.emptySelection()

  componentWillUnmount: =>
    unlisten() for unlisten in @_unlisteners

    if not @props.selector
        ReactDOM.findDOMNode(@).removeEventListener('contextmenu', @_onShowContextMenu)

  _onDataChange: =>
    @setState
        progressing: FileStore.isProgressing()
        msg: FileStore.message()
        list: FileStore.dataSource()
        selectedProvider: FileStore.selectedProvider()
        locations: FileStore.locations()
        selections: FileStore.selections()


  selections: =>
    FileStore.selections()

  selected: (item) =>
    selected = false
    _.each @state.selections, (sel)=>
        selected = true if item.id==sel.id

    return selected

  render: =>
    console.log "File List Render"

    progressing = @state.progressing
    msg = @state.msg
    list = @state.list
    selectedProvider = @state.selectedProvider
    locations = @state.locations

    if selectedProvider
        <div style={height:'100%',display:'flex',flexDirection:'column'}>
            <div className="file-list-header">
                <div className="location">
                    <button type="button" className="btn" onClick={=>@_onGotoPrevious()}><i className="fa fa-level-up"></i></button>
                </div>
                <div className="account">
                    <div className="icon">
                        <RetinaImg name="ic-provider-#{selectedProvider.provider}.png" mode={RetinaImg.Mode.ContentPreserve} />
                    </div>
                    <div className="email">{selectedProvider.emailAddress}</div>
                    <div className="action">
                        {
                            if selectedProvider.type=='cloud' && @props.selector==undefined
                                <a className="btn" onClick={=>@_onSignOutCloud(selectedProvider)}><i className="fa fa-sign-out"/></a>
                        }
                    </div>
                </div>
            </div>
            {
                if msg
                    <div>
                        <div style={position:'absolute', top:'50%', height:'30%', width:'100%', textAlign:'center'}>
                            {msg}
                        </div>
                    </div>
                else
                    wrapClass = classNames
                       "files-wrap": true
                       "ready": not @state.progressing

                    <div className="file-list-body">
                        <ScrollRegion className={wrapClass}>
                            <div className="item-container">
                            {
                                className = if @props.selector then "item-selector" else "item-normal"
                                list.map (item) =>
                                    selected = @selected(item)
                                    itemClassName = className + (if selected then " selected" else "")
                                    <div className={itemClassName} key={item.id} data-item-id={item.id} onClick={(evt)=>@_onChangeItemSelection(item)}>
                                        <div className="icon"><RetinaImg name={item.name} url={IconUtils.icon(item)} mode={RetinaImg.Mode.ContentPreserve} /></div>
                                        <div className="info">
                                            <div className="name"><a onClick={=>@_onClickItem(item)}>{item.name}</a></div>
                                            <div className="size">{if item.size then filesize(item.size) else "--"}</div>
                                            <div className="timestamp">{if item.modified then Utils.correctTimeString(item.modified) else "--"}</div>
                                        </div>
                                        <div className="action">
                                            <input type="checkbox" checked={selected}/>
                                        </div>
                                    </div>
                            }
                            </div>
                        </ScrollRegion>
                        <Spinner visible={@state.progressing} />
                    </div>
                }
        </div>
    else
        <div>
            <div style={position:'absolute', top:'50%', height:'30%', width:'100%', textAlign:'center'}>
                Please select a file privider
            </div>
        </div>
  _targetItemsForMouseEvent: (event) ->
    el = document.elementFromPoint(event.clientX, event.clientY).closest('[data-item-id]')

    itemId = el.dataset.itemId
    unless itemId
      return null

    if itemId in _.pluck(@state.selections,'id')
        return @state.selections
    else
        return _.where(@state.list, {id:itemId})


  _onShowContextMenu: (event) =>
    items = @_targetItemsForMouseEvent(event)
    console.log "FileList->_onShowContextMenu"
    console.log items
    if not items
      event.preventDefault()
      return
    (new FileListContextMenu(items)).displayMenu()


  _onChangeItemSelection: (item) =>
    selected = @selected item
    if selected
        Actions.deselectFile(item)
    else
        Actions.selectFile(item)
  #################################################

  _filePropsProvider: (item) ->
      props =
        className: classNames
      return props

  _keymapHandlers: =>
    'application:remove-from-view': @_onRemoveFromView

  _onDoubleClick: (file) =>
    console.log "onDoubleClick ==> "
    console.log file

    #unless file.uploadTaskId
    #  Actions.composePopoutDraft(file.clientId)

  # Additional Commands

  _onRemoveFromView: =>
    files = FileStore.dataSource().selection.items()
    console.log files
    #Actions.destroyDraft(file.clientId) for file in files

  _onClickItem: (item) =>
    console.log "Item Click"
    console.log item

    if item.isFolder
        FileStore.getFiles if @state.selectedProvider.provider=='dropbox' then item.path else item.id
        FileStore.pushLocation item


  _onGotoPrevious: =>
    FileStore.getPreviousFiles()

  _onSignOutCloud: (provider) =>
    return if provider.type=='email'
    Actions.removeFileProvider(provider)

module.exports = FileList
