NylasStore = require 'nylas-store'
Rx = require 'rx-lite'
_ = require 'underscore'
Request = require 'request'
progress = require 'request-progress'
{remote} = require 'electron'

Actions = require '../actions'

NylasAPI = require '../nylas-api'
DropboxAPI = require '../clouds/dropbox-api'
BoxAPI = require '../clouds/box-api'
GoogleDriveAPI = require '../clouds/googledrive-api'
OneDriveAPI = require '../clouds/onedrive-api'


class FileStore extends NylasStore
  constructor: ->
    @listenTo Actions.selectFileProvider, @_onSelectFileProvider
    @listenTo Actions.removeFileProvider, @_onRemoveFileProvider
    @listenTo Actions.didFetchAllFiles, @trigger
    @listenTo Actions.attachFileLinks, @_onAttachFileLinks
    @listenTo Actions.attachFileDownloads, @_onAttachFileDownloads
    @listenTo Actions.selectFile, @_onSelectFile
    @listenTo Actions.deselectFile, @_onDeselectFile
    @listenTo Actions.emptySelectFiles, @emptySelection

    @_dataSourceUnlisten?()

    @_dataSource = []
    @_selections = []
    @_locations = ["/"]
    @_progressing = false
    @_msg = null

  dataSource: =>
    @_dataSource

  selectedProvider: =>
    @_selectedProvider

  locations: =>
    @_locations

  pushLocation: (item) =>
    @_locations.push(item)

  isProgressing:=>
    @_progressing

  message:=>
    @_msg

  selections: =>
    @_selections

  emptySelection: =>
    @_selections = []
    @trigger()

  _onSelectFileProvider: (provider) =>
    @_locations = ["/"]
    @_selectedProvider = provider
    @trigger()

    if provider.type == "cloud"
      unless provider.accountId then @_showCloudAuthWindow(provider.provider) else @getFiles("")
    else if provider.type == 'email'
      @getFiles(provider.accountId)


  _showCloudAuthWindow: (cloudType) ->
    switch cloudType
      when 'dropbox'
        title = "Dropbox Login"
        url = DropboxAPI.AUTH_URL
      when 'box'
        title = "Box Login"
        url = BoxAPI.AUTH_URL
      when 'googledrive'
        title = "GoogleDrive Login"
        url = GoogleDriveAPI.AUTH_URL
      when 'onedrive'
        title = "OneDrive Login"
        url = OneDriveAPI.AUTH_URL

    BrowserWindow = remote.require('browser-window')
    w = new BrowserWindow
      title: title
      nodeIntegration: false
      webPreferences:
        webSecurity:false
      width: 800
      height: 650

    console.log "Auth URL"
    console.log url
    w.loadURL url

  _onAttachFileLinks: (files)=>
    return unless @_selectedProvider || @_selectedProvider.type=='email'

    API = @getApiByProvider @_selectedProvider

    API.getSharedLinks files, (err, links)=>
      console.log "FileListStore->_onAttachFileLink"
      console.log links

      Actions.composeNewDraftWithFileLinks links unless err

  _onAttachFileDownloads: (files)=>
    return unless @_selectedProvider

    #Actions.fetchFile(file, @_selectedProvider.provider)
    Actions.composeNewDraftWithFileDownloads files

  _onSelectFile: (file) =>
    @_selections.push file unless _.contains @_selections, file
    console.log @_selections
    @trigger()

  _onDeselectFile: (file) =>
    @_selections.splice @_selections.indexOf(file), 1 if _.contains @_selections, file
    console.log @_selections
    @trigger()

  getShareLinks: (files, provider, callback) =>
    #return if not (files && files.length && provider)
    console.log "FileStore->getShareLinks"
    console.log files
    console.log provider

    API = @getApiByProvider provider

    API.getSharedLinks files, (err, links)=>
      console.log "FileListStore->_onAttachFileLink"
      console.log links
      callback links

  getApiByProvider:(provider)=>
    if provider.type=='email'
      api = NylasAPI
    else
      switch provider.provider
        when 'dropbox'
          api = DropboxAPI
        when 'box'
          api = BoxAPI
        when 'googledrive'
          api = GoogleDriveAPI
        when 'onedrive'
          api = OneDriveAPI

  getFiles: (path) =>
    return unless @_selectedProvider


    @_progressing = true
    @_msg = null
    @emptySelection()
    @trigger()

    API = @getApiByProvider(@_selectedProvider)

    store = this

    observableList = Rx.Observable.create (observer) =>

      return Rx.Disposable.create(API.getFiles path, (err, result)=>
        console.log "FileListStore->getFiles"
        @_progressing = false
        if err then observer.onError(err) else observer.onNext(result)
      )
    observableList.subscribe (files)=>
      store._onSuccessLoadFiles files
    ,(err)=>
      store._onErrorLoadFiles err

  getPreviousFiles: =>
    if @_locations.length>1
      @_locations.pop()
      prevItem = @_locations[@_locations.length-1]


      if prevItem == "/"
        path = ""
      else
        path = if @_selectedProvider.provider=='dropbox' then prevItem.path else prevItem.id
      @getFiles path

  _onSuccessLoadFiles: (files) =>
    @_dataSource = files
    console.log "FileListStore->getFiles Subscription"
    console.log files
    #@CloudActions.fetchAllFiles(files, true) if @CloudActions

    @_msg = if files.length == 0 then "Folder empty!" else null
    @trigger()

  _onErrorLoadFiles: (err)=>
    @_msg = "Network Connection Failure"
    @trigger()


  _onRemoveFileProvider: (provider)=>
    return if provider.type=='email'

    API = @getApiByProvider provider

    @_progressing = true
    @trigger()
    store = @
    API.logout (result)->
      if result
        store._selectedProvider = null
        store._dataSource = []
        store._progressing = false
        store.trigger()
        Actions.didRemoveFileProvider provider


module.exports = new FileStore()
