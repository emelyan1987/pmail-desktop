os = require 'os'
fs = require 'fs'
path = require 'path'
{remote, shell} = require 'electron'
mkdirp = require 'mkdirp'
Utils = require '../models/utils'
File = require '../models/file'
Reflux = require 'reflux'
_ = require 'underscore'
Actions = require '../actions'
RegExpUtils = require '../../regexp-utils'

Download = require '../downloads/download'
EmailDownload = require '../downloads/email-download'
DropboxDownload = require '../downloads/dropbox-download'
BoxDownload = require '../downloads/box-download'
GoogleDriveDownload = require '../downloads/googledrive-download'
OneDriveDownload = require '../downloads/onedrive-download'

Promise.promisifyAll(fs)
mkdirpAsync = Promise.promisify(mkdirp)



module.exports =
FileDownloadStore = Reflux.createStore
  init: ->
    @listenTo Actions.fetchFile, @_fetch
    @listenTo Actions.fetchAndOpenFile, @_fetchAndOpen
    @listenTo Actions.fetchAndSaveFile, @_fetchAndSave
    @listenTo Actions.fetchAndSaveAllFiles, @_fetchAndSaveAll
    @listenTo Actions.abortFetchFile, @_abortFetchFile
    @listenTo Actions.didPassivelyReceiveNewModels, @_newMailReceived

    @_downloads = {}
    @_downloadDirectory = path.join(PlanckEnv.getConfigDirPath(), 'downloads')
    mkdirp(@_downloadDirectory)

  ######### PUBLIC #######################################################

  # Returns a path on disk for saving the file. Note that we must account
  # for files that don't have a name and avoid returning <downloads/dir/"">
  # which causes operations to happen on the directory (badness!)
  #
  pathForFile: (file) ->
    return undefined unless file
    provider = file.provider
    provider ?= 'email'

    filename = if file instanceof File then file.safeDisplayName() else Utils.fileSafeDisplayName(file.name)
    path.join(@_downloadDirectory, provider, file.id, filename)

  downloadDataForFile: (fileId) ->
    @_downloads[fileId]?.data()

  # Returns a hash of download objects keyed by fileId
  #
  downloadDataForFiles: (fileIds=[]) ->
    downloadData = {}
    fileIds.forEach (fileId) =>
      downloadData[fileId] = @downloadDataForFile(fileId)
    return downloadData

  ########### PRIVATE ####################################################

  _newMailReceived: (incoming) ->
    if PlanckEnv.config.get('core.attachments.downloadPolicy') is 'on-receive'
      return unless incoming['message']
      for message in incoming['message']
        for file in message.files
          @_fetch(file)

  # Returns a promise with a Download object, allowing other actions to be
  # daisy-chained to the end of the download operation.
  _runDownload: (file) ->
    try
      provider = file.provider
      provider ?= 'email'
      targetPath = @pathForFile(file)

      # is there an existing download for this file? If so,
      # return that promise so users can chain to the end of it.
      download = @_downloads[file.id]
      return download.run() if download

      # create a new download for this file

      console.log "FileDownloadStore->_runDownload"
      console.log file
      options =
        fileId: file.id
        filesize: file.size
        filename: file.name ? file.filename
        targetPath: targetPath
        progressCallback: => @trigger()

      switch provider
        when 'email'
          FileDownload = EmailDownload
          options.accountId = file.accountId
        when 'dropbox'
          FileDownload = DropboxDownload
        when 'box'
          FileDownload = BoxDownload
        when 'googledrive'
          FileDownload = GoogleDriveDownload
        when 'onedrive'
          FileDownload = OneDriveDownload

      download = new FileDownload options


      # Do we actually need to queue and run the download? Queuing a download
      # for an already-downloaded file has side-effects, like making the UI
      # flicker briefly.
      @_prepareFolder(file).then =>
        @_checkForDownloadedFile(file).then (alreadyHaveFile) =>
          console.log "FileDownloadStore->_checkForDownloadedFile"
          console.log alreadyHaveFile
          if alreadyHaveFile
            # If we have the file, just resolve with a resolved download representing the file.
            download.promise = Promise.resolve()
            download.setState Download.State.Finished
            @_downloads[file.id] = download
            @trigger()
            return Promise.resolve(download)
          else
            @_downloads[file.id] = download
            @trigger()
            return download.run().finally =>
              download.ensureClosed()
              if download.state is Download.State.Failed
                delete @_downloads[file.id]
              @trigger()

    catch err
      console.error "FileDownloadError", err
      return Promise.reject(err)

  # Returns a promise that resolves with true or false. True if the file has
  # been downloaded, false if it should be downloaded.
  #
  _checkForDownloadedFile: (file) ->
    fs.statAsync(@pathForFile(file)).catch (err) =>
      return Promise.resolve(false)
    .then (stats) =>
      return Promise.resolve(stats.size >= file.size)

  # Checks that the folder for the download is ready. Returns a promise that
  # resolves when the download directory for the file has been created.
  #
  _prepareFolder: (file) ->
    provider = file.provider
    provider ?= 'email'
    targetFolder = path.join(@_downloadDirectory, provider, file.id)
    fs.statAsync(targetFolder).catch =>
      mkdirpAsync(targetFolder)

  _fetch: (file) ->
    @_runDownload(file)
    .catch(@_catchFSErrors)
    .catch (error) =>
      console.error "FileDownloadStore->_fetch failed"
      console.error error
      # Passively ignore

  _fetchAndOpen: (file) ->
    @_runDownload(file).then (download) ->
      shell.openItem(download.targetPath)
    .catch(@_catchFSErrors)
    .catch (error) =>
      console.error "FileDownloadStore->_fetchAndOpen failed"
      console.error error
      @_presentError(file)

  _saveDownload: (download, savePath) =>
    return new Promise (resolve, reject) =>
      stream = fs.createReadStream(download.targetPath)
      stream.pipe(fs.createWriteStream(savePath))
      stream.on 'error', (err) -> reject(err)
      stream.on 'end', -> resolve()

  _fetchAndSave: (file) ->
    console.log "FileDownloadStore->_fetchAndSave"
    console.log file
    defaultPath = @_defaultSavePath(file)
    defaultExtension = path.extname(defaultPath)

    PlanckEnv.showSaveDialog {defaultPath}, (savePath) =>
      return unless savePath
      PlanckEnv.savedState.lastDownloadDirectory = path.dirname(savePath)

      saveExtension = path.extname(savePath)
      didLoseExtension = defaultExtension isnt '' and saveExtension is ''
      if didLoseExtension
        savePath = savePath + defaultExtension

      @_runDownload(file)
      .then (download) => @_saveDownload(download, savePath)
      .then => shell.showItemInFolder(savePath)
      .catch(@_catchFSErrors)
      .catch =>
        @_presentError(file)

  _fetchAndSaveAll: (files) ->
    defaultPath = @_defaultSaveDir()
    options = {
      defaultPath,
      properties: ['openDirectory'],
    }

    PlanckEnv.showOpenDialog options, (selected) =>
      return unless selected
      dirPath = selected[0]
      return unless dirPath
      PlanckEnv.savedState.lastDownloadDirectory = dirPath

      lastSavePath = null
      savePromises = files.map (file) =>
        filename = if file instanceof File then file.safeDisplayName() else Utils.fileSafeDisplayName(file.name)
        savePath = path.join(dirPath, filename)
        @_runDownload(file)
        .then (download) => @_saveDownload(download, savePath)
        .then ->
          lastSavePath = savePath

      Promise.all(savePromises)
      .then =>
        shell.showItemInFolder(lastSavePath) if lastSavePath
      .catch(@_catchFSErrors)
      .catch =>
        #@_presentError(file)

  _abortFetchFile: (file) ->
    download = @_downloads[file.id]
    return unless download
    download.ensureClosed()
    @trigger()

    downloadPath = @pathForFile(file)
    fs.exists downloadPath, (exists) ->
      fs.unlink(downloadPath) if exists

  _defaultSaveDir: ->
    if process.platform is 'win32'
      home = process.env.USERPROFILE
    else
      home = process.env.HOME

    downloadDir = path.join(home, 'Downloads')
    if not fs.existsSync(downloadDir)
      downloadDir = os.tmpdir()

    if PlanckEnv.savedState.lastDownloadDirectory
      if fs.existsSync(PlanckEnv.savedState.lastDownloadDirectory)
        downloadDir = PlanckEnv.savedState.lastDownloadDirectory

    return downloadDir

  _defaultSavePath: (file) ->
    downloadDir = @_defaultSaveDir()
    filename = if file instanceof File then file.safeDisplayName() else Utils.fileSafeDisplayName(file.name)
    path.join(downloadDir, filename)

  _presentError: (file) ->
    remote.dialog.showMessageBox
      type: 'warning'
      message: "Download Failed"
      detail: "Unable to download #{file.name}.
               Check your network connection and try again."
      buttons: ["OK"]

  _catchFSErrors: (error) ->
    message = null
    if error.code in ['EPERM', 'EMFILE', 'EACCES']
      message = "N1 could not save an attachment. Check that permissions are set correctly and try restarting N1 if the issue persists."
    if error.code in ['ENOSPC']
      message = "N1 could not save an attachment because you have run out of disk space."

    if message
      remote.dialog.showMessageBox
        type: 'warning'
        message: "Download Failed"
        detail: "#{message}\n\n#{error.message}"
        buttons: ["OK"]
      return Promise.resolve()
    else
      return Promise.reject(error)

# Expose the Download class for our tests, and possibly for other things someday
FileDownloadStore.Download = Download
