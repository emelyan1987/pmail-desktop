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
class OneDriveAPI extends CloudAPI

  constructor: ->
    super({type:'onedrive'})

    @API_ROOT = "https://api.onedrive.com/v1.0"
    @CLIENT_ID = "0000000048187F2D"
    @CLIENT_SECRET = "tbdPwRp6JS7SADbIdvFLQZOIndtku684"
    @REDIRECT_URI = "https://sync-dev.planckapi.com/static/callback/onedrive.html"
    #@REDIRECT_URI = "http://localhost/planckmail/callback/onedrive.html"
    @AUTH_URL = "https://login.live.com/oauth20_authorize.srf?client_id=#{@CLIENT_ID}&scope=wl.basic onedrive.readwrite wl.emails wl.photos wl.phone_numbers wl.postal_addresses wl.offline_access&response_type=code&redirect_uri=#{@REDIRECT_URI}"
    @LOGOUT_URL = "https://login.live.com/oauth20_logout.srf?client_id=#{@CLIENT_ID}&redirect_uri=#{@REDIRECT_URI}"


  request: (options={}) ->
    return if PlanckEnv.getLoadSettings().isSpec

    credentials = @getCredentials()
    return if credentials == null

    options.error ?= @_defaultErrorCallback
    console.log "OneDriveAPI->request"
    console.log credentials
    if credentials.expires_in
      expiresIn = Number(credentials.expires_in)
      now = Math.floor(new Date().getTime()/1000)
      if now-credentials.updated_at >= expiresIn
        console.log "OneDriveAPI->request expired"

        if credentials.refresh_token==undefined
          console.log "credentials.refresh_token undefined"
          options.error(new Error({error:"Refresh Token does not exist"}))
          return

        console.log "Requested"
        me = @
        nodeRequest
          method: "POST"
          url: "https://login.live.com/oauth20_token.srf"
          form:
            client_id: @CLIENT_ID
            grant_type: "refresh_token"
            client_secret: @CLIENT_SECRET
            refresh_token: credentials.refresh_token
            redirect_uri: @REDIRECT_URI
          json: true
        , (err, response, body)->
          if err? or response.statusCode > 299
            options.error(new APIError({error:err, response:response, body:body}))
          else
            credentials.access_token = body.access_token
            credentials.expires_in = body.expires_in
            me.setCredentials(credentials)

            me._runRequest options
        return

    @_runRequest options

  _runRequest: (options)->
    @accessToken = @getAccessToken()
    return if @accessToken==undefined

    console.log "OneDrive AccessToken=" + @accessToken


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
      url: 'https://apis.live.net/v5.0/me'
      success: @_onDidLoadUserInfo
    }

  _onDidLoadUserInfo: (info)->
    console.log "OneDriveAPI->onDidLoadUserInfo"
    console.log info

    userInfo = {
      accountId: info.id
      emailAddress: info.emails.preferred
      name: info.name
    }

    PlanckEnv.config.set('cloud.onedrive.userinfo', userInfo)
    PlanckEnv.config.save()

    Actions.didLoadCloudUserInfo({
      cloudType: 'onedrive',
      userInfo: userInfo
    })

  getFiles: (parentId, callback)->
    parentId = "root" if parentId.length==0

    @request
      path: "/drive/items/#{parentId}/children"
      success: (body)=>
        console.log "OneAPI->getFiles"
        console.log body

        result = []

        result.push {
          provider: 'onedrive'
          id: item.id
          name: item.name
          size: item.size
          modified: item.lastModifiedDateTime
          isFolder: true if item.folder
        } for item in body.value

        console.log result
        callback null, result
      error: (err)=>
        callback err

  createSharedLink: (item)=>
    new Promise (resolve, reject) =>
      @request
        method: "POST"
        path: "/drive/items/#{item.id}/action.createLink"
        body:
          type: "view"
          scope: "anonymous"
        success: (body)=>
          console.log "OneDriveAPI->createSharedLink"
          console.log body
          unless body.link then reject(body) else resolve(body)
        error: (err)=>
          console.log "OneDriveAPI->createSharedLink"
          console.log err
          reject(err)

  getSharedLinks: (items, callback)->
    console.log "OneDriveAPI->getSharedLinks"

    promises = _.map items, (item)=>
      @createSharedLink(item)
      .then (body) =>
        return body.link.webUrl
      .catch (reason)=>
        console.log "OneDriveAPI->getSharedLinks Error"
        console.log reason

    Promise.all(promises)
    .then (links)=>
      callback null, links
    .catch (reason)=>
      console.log "OneDriveAPI->getSharedLinks All Promises Error"
      console.log reason
      callback reason


module.exports = new OneDriveAPI
