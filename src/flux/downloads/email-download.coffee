_ = require 'underscore'
fs = require 'fs'
progress = require 'request-progress'
Download  = require './download'
NylasAPI  = require '../nylas-api'


class EmailDownload extends Download

  constructor: (options={}) ->
    super(options)

    @accountId = options.accountId
    if not @accountId
      throw new Error("Download.constructor: You must provide a non-empty accountId.")

  data: ->
    _.extend super, {provider:'email'}

  run: ->
    console.log "EmailDownload->run"
# If run has already been called, return the existing promise. Never
# initiate multiple downloads for the same file
    return @promise if @promise

    @promise = new Promise (resolve, reject) =>
      stream = fs.createWriteStream(@targetPath)
      @state = Download.State.Downloading

      console.log "EmailDownload make Request"
      NylasAPI.makeRequest
        json: false
        path: "/files/#{@fileId}/download"
        accountId: @accountId
        encoding: null # Tell `request` not to parse the response data
        started: (req) =>
          @request = req
          progress(@request, {throtte: 250})
          .on "progress", (progress) =>
            @percent = progress.percent
            @progressCallback()

          .on "error", (err) =>
            console.log "EmailDownload Error"
            console.log err
            @request = null
            @state = Download.State.Failed
            stream.end()
            if fs.existsSync(@targetPath)
              fs.unlinkSync(@targetPath)
            reject(@)

          .on "end", =>
            return if @state is Download.State.Failed
            @request = null
            @state = Download.State.Finished
            @percent = 100
            stream.end()
            resolve(@) # Note: we must resolve with this

          .pipe(stream)

module.exports = EmailDownload