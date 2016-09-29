_ = require 'underscore'
fs = require 'fs'
progress = require 'request-progress'
Download  = require './download'
DropboxAPI  = require '../clouds/dropbox-api'


class DropboxDownload extends Download

  constructor: (options={}) ->
    super(options)


  data: ->
    _.extend super, {provider:'dropbox'}

  run: ->
    console.log "DropboxDownload->run"

    return @promise if @promise

    @promise = new Promise (resolve, reject) =>
      stream = fs.createWriteStream(@targetPath)
      @setState Download.State.Downloading

      console.log "DropboxDownload make Request"
      DropboxAPI.request
        url: "#{DropboxAPI.CONTENT_API_ROOT}/files/download"
        method: "POST"
        headers:
          "Dropbox-API-Arg": "{\"path\": \"#{@fileId}\"}"
        #encoding: null # Tell `request` not to parse the response data
        json: false
        started: (req) =>
          @request = req
          progress(@request, {throtte: 250})
          .on "progress", (progress) =>
            @percent = progress.percent
            console.log @percent
            @progressCallback()

          .on "error", (err) =>
            console.log "DropboxDownload Error"
            console.log err
            @request = null
            @setState Download.State.Failed
            stream.end()
            if fs.existsSync(@targetPath)
              fs.unlinkSync(@targetPath)
            reject(@)

          .on "end", =>
            return if @state is Download.State.Failed
            @request = null
            @setState Download.State.Finished
            @percent = 100
            stream.end()
            resolve(@) # Note: we must resolve with this

          .pipe(stream)
module.exports = DropboxDownload