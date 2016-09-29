_ = require 'underscore'
Actions = require '../actions'

State =
  Unstarted: 'unstarted'
  Downloading: 'downloading'
  Finished: 'finished'
  Failed: 'failed'

class Download
  @State: State

  constructor: ({@fileId, @targetPath, @filename, @filesize, @progressCallback}) ->
    if not @filename or @filename.length is 0
      throw new Error("Download.constructor: You must provide a non-empty filename.")
    if not @fileId
      throw new Error("Download.constructor: You must provide a fileID to download.")
    if not @targetPath
      throw new Error("Download.constructor: You must provide a target path to download.")

    @percent = 0
    @promise = null
    @state = State.Unstarted
    @

# We need to pass a plain object so we can have fresh references for the
# React views while maintaining the single object with the running
# request.
  data: -> Object.freeze _.clone
    state: @state
    fileId: @fileId
    percent: @percent
    filename: @filename
    filesize: @filesize
    targetPath: @targetPath

  run: ->


  ensureClosed: ->
    @request?.abort()


  setState: (state) ->
    @state = state

    Actions.downloadStateChanged(@)



module.exports = Download