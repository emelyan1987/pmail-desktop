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
class BoxAPI extends CloudAPI

  constructor: ->
    super({type:'box'})

    @API_ROOT = "https://api.box.com/2.0"
    @CLIENT_ID = "fhqta6ms59vhzi5d0r7x2oepjfrj0rrv"
    @CLIENT_SECRET = "QeZSXQwfyN6glwOH07siOSTN5H8LhL5L"
    @REDIRECT_URI = "https://sync-dev.planckapi.com/static/callback/box.html"
    #@REDIRECT_URI = "http://localhost/planckmail/callback/box.html"
    @AUTH_URL = "https://app.box.com/api/oauth2/authorize?response_type=code&client_id=#{@CLIENT_ID}&redirect_uri=#{@REDIRECT_URI}"
    @LOGOUT_URL = "https://www.box.com/logout"

  request: (options={}) ->
    return if PlanckEnv.getLoadSettings().isSpec

    credentials = @getCredentials()
    return if credentials == null

    options.error ?= @_defaultErrorCallback
    if credentials.expires_in
      expiresIn = Number(credentials.expires_in)
      now = Math.floor(new Date().getTime()/1000)
      if now-credentials.updated_at >= expiresIn
        if credentials.refresh_token==undefined
          options.error(new Error({error:"Refresh Token does not exist"}))
          return

        console.log "Box access token expired"
        console.log credentials

        me = @
        nodeRequest
          method: "POST"
          url: "https://api.box.com/oauth2/token"
          form:
            client_id: @CLIENT_ID
            client_secret: @CLIENT_SECRET
            grant_type: "refresh_token"
            refresh_token: credentials.refresh_token
          json: true
        , (err, response, body)->
          console.log "BoxAPI refresh token result"
          console.log body
          if err? or response.statusCode > 299
            options.error(new APIError({error:err, response:response, body:body}))
          else
            credentials.access_token = body.access_token
            credentials.refresh_token = body.refresh_token
            credentials.expires_in = body.expires_in
            me.setCredentials(credentials)

            me._runRequest options
        return

    @_runRequest options

  _runRequest: (options)->
    @accessToken = @getAccessToken()
    return if @accessToken==undefined

    console.log "Box AccessToken=" + @accessToken


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

      console.log "BoxAPI->_runRequest"
      console.log options
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
      path: '/users/me'
      success: @_onDidLoadUserInfo
    }

  _onDidLoadUserInfo: (info)->
    console.log "BoxAPI->onDidLoadUserInfo"
    console.log info

    userInfo = {
      accountId: info.id
      emailAddress: info.login
      name: info.name
    }

    PlanckEnv.config.set('cloud.box.userinfo', userInfo)
    PlanckEnv.config.save()

    Actions.didLoadCloudUserInfo({
      cloudType: 'box',
      userInfo: userInfo
    })

  getFiles: (folderId, callback)->
    folderId = 0 if folderId.length==0

    @request
      path: "/folders/#{folderId}/items?fields=name,modified_at,size,shared_link"
      success: (body)=>
        console.log "Box->getFiles"
        console.log body

        result = []

        result.push {
          provider: 'box'
          id: item.id
          name: item.name
          size: item.size
          modified: item.modified_at
          isFolder: true if item.type=="folder",
          shared_link: item.shared_link.url if item.shared_link
        } for item in body.entries

        console.log result
        callback null, result
      error: (err)=>
        callback err

  createSharedLink: (item)=>
    path = if item.isFolder then "/folders/#{item.id}" else "/files/#{item.id}"
    new Promise (resolve, reject) =>
      @request
        method: "PUT"
        path: path
        body:
          shared_link:
            access: "open"
        success: (body)=>
          console.log "BoxAPI->createSharedLink"
          console.log body
          unless body.shared_link then reject(body) else resolve(body)
        error: (err)=>
          console.log "BoxAPI->createSharedLink"
          console.log err
          reject(err)

  getSharedLinks: (items, callback)->
    console.log "BoxAPI->getSharedLinks"

    promises = _.map items, (item)=>
      if item.shared_link
        return Promise.resolve(item.shared_link)

      @createSharedLink(item)
      .then (body) =>
        return body.shared_link.url
      .catch (reason)=>
        console.log "BoxAPI->getSharedLinks Error"
        console.log reason

    Promise.all(promises)
    .then (links)=>
      callback null, links
    .catch (reason)=>
      console.log "BoxAPI->getSharedLinks All Promises Error"
      console.log reason
      callback reason


module.exports = new BoxAPI
