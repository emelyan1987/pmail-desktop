_ = require 'underscore'
nodeRequest = require 'request'
Utils = require '../models/utils'
Actions = require '../actions'
{APIError} = require '../errors'
DatabaseStore = require '../stores/database-store'
PriorityUICoordinator = require '../../priority-ui-coordinator'
async = require 'async'
CloudAPI = require './cloud-api'

# TODO: Dropbox File Upload & Download
class GoogleDriveAPI extends CloudAPI

  constructor: ->
    super({type:'googledrive'})

    @API_ROOT = "https://www.googleapis.com/drive/v2"
    @CLIENT_ID = "65711481506-e1cbv4cci49vacn58n9ujdp4j4hha9pp.apps.googleusercontent.com"
    @CLIENT_SECRET = "flrAqEGZTdJNn1LRaFVP5Nng"
    @REDIRECT_URI = "https://sync-dev.planckapi.com/static/callback/googledrive.html"
    #@REDIRECT_URI = "http://localhost/planckmail/callback/googledrive.html"
    @AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=#{@CLIENT_ID}&redirect_uri=#{@REDIRECT_URI}&scope=https://www.googleapis.com/auth/drive&access_type=offline&prompt=consent"
    @LOGOUT_URL = "https://accounts.google.com/logout"

  request: (options={}) ->
    return if PlanckEnv.getLoadSettings().isSpec

    credentials = @getCredentials()
    return if credentials == null

    options.error ?= @_defaultErrorCallback
    console.log "GoogleDriveAPI->request"
    console.log credentials
    if credentials.expires_in
      expiresIn = Number(credentials.expires_in)
      now = Math.floor(new Date().getTime()/1000)
      if now-credentials.updated_at >= expiresIn
        console.log "GoogleDriveAPI->request expired"
        expired = true
        if credentials.refresh_token==undefined
          console.log "credentials.refresh_token undefined"
          options.error(new Error({error:"Refresh Token does not exist"}))
          return

        console.log "Requested"

        me = @
        nodeRequest
          method: "POST"
          url: "https://www.googleapis.com/oauth2/v4/token"
          form: {
            client_id: @CLIENT_ID,
            client_secret: @CLIENT_SECRET,
            grant_type: "refresh_token",
            refresh_token: credentials.refresh_token
          }
          json: true
          , (err, response, body)->
            console.log response
            if err? or response.statusCode > 299
              options.error(new APIError({error:err, response:response, body:body}))
            else
              credentials.access_token = body.access_token
              credentials.expires_in = body.expires_in
              me.setCredentials(credentials)

              me._runRequest options


    @_runRequest options unless expired

  _runRequest: (options)->
    @accessToken = @getAccessToken()
    return if @accessToken==undefined

    console.log "GoogleDrive AccessToken=" + @accessToken


    options.method ?= 'GET'
    options.url ?= "#{@API_ROOT}#{options.path}" if options.path

    options.headers ?= {} unless options.headers
    options.headers.Authorization = "Bearer #{@accessToken}"


    options.body ?= undefined unless options.formData
    options.json ?= true


    # This is to provide functional closure for the variable.
    rid = Utils.generateTempId()
    [rid].forEach (requestId) ->
      options.startTime = Date.now()
      Actions.willMakeAPIRequest({
        request: options,
        requestId: requestId
      })
      req = nodeRequest options, (error, response, body) ->
        Actions.didMakeAPIRequest({
          request: options,
          statusCode: response?.statusCode,
          error: error,
          requestId: requestId
        })
        PriorityUICoordinator.settle.then ->
          if error? or response.statusCode > 299
            options.error(new APIError({error:error, response:response, body:body, requestOptions: options}))
          else
            options.success(body, response) if options.success
      options.started?(req)

  loadUserInfo: ->
    @request {
      path: '/about'
      success: @_onDidLoadUserInfo
    }

  _onDidLoadUserInfo: (info)->
    console.log "GoogleDriveAPI->onDidLoadUserInfo"
    console.log info

    userInfo = {
      accountId: info.user.permissionId
      emailAddress: info.user.emailAddress
      name: info.name
    }

    PlanckEnv.config.set('cloud.googledrive.userinfo', userInfo)
    PlanckEnv.config.save()

    Actions.didLoadCloudUserInfo({
      cloudType: 'googledrive',
      userInfo: userInfo
    })

  getFiles: (parentId, callback)->
    parentId = "root" if parentId.length==0

    @request
      path: "/files?q='#{parentId}' in parents&orderBy=folder,modifiedDate desc,title"
      success: (body)=>
        console.log "GoogleAPI->getFiles"
        console.log body

        result = []

        _.each body.items, (item)=>
          unless item.labels.trashed
            result.push
              provider: 'googledrive'
              id: item.id
              name: item.title
              size: item.fileSize
              modified: item.modifiedDate
              isFolder: true if item.mimeType=="application/vnd.google-apps.folder"
              shared: item.shared
              shared_link: item.alternateLink

        console.log result
        callback null, result
      error: (err)=>
        console.log err
        callback err

  createSharedLink: (item)=>
    new Promise (resolve, reject) =>
      @request
        method: "POST"
        path: "/files/#{item.id}/permissions"
        body:
          type: "anyone"
          role: "reader"
        success: (body)=>
          console.log "GoogleAPI->createSharedLink"
          console.log body
          unless body.id then reject(body) else resolve(body)
        error: (err)=>
          console.log "GoogleAPI->createSharedLink"
          console.log err
          reject(err)

  getSharedLinks: (items, callback)->
    console.log "GoogleDriveAPI->getSharedLinks"

    promises = _.map items, (item)=>
      if item.shared
        return Promise.resolve(item.shared_link)

      @createSharedLink(item)
      .then (body) =>
        return item.shared_link
      .catch (reason)=>
        console.log "GoogleDriveAPI->getSharedLinks Error"
        console.log reason

    Promise.all(promises)
    .then (links)=>
      callback null, links
    .catch (reason)=>
      console.log "GoogleDriveAPI->getSharedLinks All Promises Error"
      console.log reason
      callback reason

module.exports = new GoogleDriveAPI
