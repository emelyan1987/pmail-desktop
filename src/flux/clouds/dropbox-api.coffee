_ = require 'underscore'
fs = require 'fs'
path = require 'path'
{remote} = require 'electron'
mkdirp = require 'mkdirp'
Promise.promisifyAll(fs)
mkdirpAsync = Promise.promisify(mkdirp)

nodeRequest = require 'request'
progress = require 'request-progress'

Utils = require '../models/utils'
Actions = require '../actions'
{APIError} = require '../errors'
DatabaseStore = require '../stores/database-store'
PriorityUICoordinator = require '../../priority-ui-coordinator'
async = require 'async'
CloudAPI = require './cloud-api'

# TODO: Dropbox File Upload & Download

class DropboxAPI extends CloudAPI

  constructor: ->
    super({type:'dropbox'})

    @API_ROOT = "https://api.dropboxapi.com/2"
    @CONTENT_API_ROOT = "https://content.dropboxapi.com/2"
    @CLIENT_ID = "rm8nd61ita6scjg"
    @REDIRECT_URI = "https://sync-dev.planckapi.com/static/callback/dropbox.html"
    #@REDIRECT_URI = "http://localhost/planckmail/callback/dropbox.html"
    @AUTH_URL = "https://www.dropbox.com/oauth2/authorize?client_id=#{@CLIENT_ID}&response_type=token&redirect_uri=#{@REDIRECT_URI}"
    @LOGOUT_URL = "https://www.dropbox.com/logout"


  request: (options={}) ->
    return if PlanckEnv.getLoadSettings().isSpec

    if @accessToken == undefined
      @accessToken = @getAccessToken()
      return if @accessToken == undefined

    console.log "Dropbox AccessToken=" + @accessToken

    options.method ?= 'GET'
    options.url ?= "#{@API_ROOT}#{options.path}" if options.path
    options.headers ?= {} unless options.headers
    options.headers.Authorization = "Bearer #{@accessToken}"


    options.body ?= undefined unless options.formData
    options.json ?= true
    options.error ?= @_defaultErrorCallback

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
      method: 'POST'
      path: '/users/get_current_account'
      success: @_onDidLoadUserInfo
    }

  _onDidLoadUserInfo: (info)->
    console.log "DropboxAPI->onDidLoadUserInfo"
    console.log info

    userInfo = {
      accountId: info.account_id
      emailAddress: info.email
      name: info.name.display_name
    }
    PlanckEnv.config.set('cloud.dropbox.userinfo', userInfo)
    PlanckEnv.config.save()

    Actions.didLoadCloudUserInfo({
      cloudType: 'dropbox',
      userInfo: userInfo
    })

  getFiles: (path, callback)->
    console.log "DropboxAPI->getFiles"
    console.log path
    @request
      method: 'POST'
      path: '/files/list_folder'
      body:
        path: path,
        recursive: false,
        include_media_info: false,
        include_deleted: false,
        include_has_explicit_shared_members: false
      success: (body)=>
        console.log "DropboxAPI->getFiles"
        console.log body

        result = []

        result.push {
          provider: 'dropbox'
          id: item.id
          path: item.path_lower
          name: item.name
          size: item.size
          modified: item.server_modified
          isFolder: true if item[".tag"] == "folder"
        } for item in body.entries

        console.log result
        callback null, result
      error: (err)=>
        callback err

  getSharedLink: (id)=>
    new Promise (resolve, reject) =>
      @request
        method: "POST"
        path: "/sharing/list_shared_links"
        body:
          path: id
        success: (body)=>
          console.log "DropboxAPI->getSharedLink"
          console.log body
          if body.error then reject(body) else resolve(body)
        error: (err)=>
          console.log "DropboxAPI->getSharedLink"
          console.log err
          reject(err)

  createSharedLink: (id)=>
    new Promise (resolve, reject) =>
      @request
        method: "POST"
        path: "/sharing/create_shared_link_with_settings"
        body:
          path: id
        success: (body)=>
          console.log "DropboxAPI->createSharedLink"
          console.log body
          if body.error then reject(body) else resolve(body)
        error: (err)=>
          console.log "DropboxAPI->createSharedLink"
          console.log err
          reject(err)

  getSharedLinks: (items, callback)->
    console.log "DropboxAPI->getSharedLinks"

    promises = _.map items, (item)=>
      @getSharedLink(item.id)
      .then (body)=>
        if body.links
          if body.links.length == 0
            @createSharedLink(item.id)
            .then (body) =>
              return body.url
          else
            return body.links[0].url
      .catch (reason)=>
        console.log "DropboxAPI->getSharedLinks Error"
        console.log reason

    Promise.all(promises)
    .then (links)=>
      callback null, links
    .catch (reason)=>
      console.log "DropboxAPI->getSharedLinks All Promises Error"
      console.log reason
      callback reason




module.exports = new DropboxAPI()
