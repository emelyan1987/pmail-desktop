_ = require 'underscore'
fs = require 'fs'
progress = require 'request-progress'
Download  = require './download'
BoxAPI  = require '../clouds/box-api'


class BoxDownload extends Download

  constructor: (options={}) ->
    super(options)


  data: ->
    _.extend super, {provider:'box'}

  run: ->
    console.log "BoxDownload->run"

    return @promise if @promise

    @promise = new Promise (resolve, reject) =>
      stream = fs.createWriteStream(@targetPath)
      @setState Download.State.Downloading

      console.log "BoxDownload make Request"
      BoxAPI.request
        path: "/files/#{@fileId}/content"
        method: "GET"

        started: (req) =>
          @request = req
          progress(@request, {throtte: 250})
          .on "progress", (progress) =>
            @percent = progress.percent
            console.log @percent
            @progressCallback()

          .on "error", (err) =>
            console.log "BoxDownload Error"
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

module.exports = BoxDownload