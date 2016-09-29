_ = require 'underscore'
Actions = require '../actions'

Type =
  Dropbox: 'dropbox'
  Box: 'box'
  GoogleDrive: 'googledrive'
  OneDrive: 'onedrive'

class CloudAPI
  @Type: Type

  constructor: ({@type}) ->
    if not @type
      throw new Error("CloudAPI.constructor: You must provide a cloud type.")

    @API_ROOT = null
    @CONTENT_API_ROOT = null
    @CLIENT_ID = null
    @CLIENT_SECRET = null
    @REDIRECT_URI = null
    @AUTH_URL = null
    @LOGOUT_URL = null

    @accessToken = @getAccessToken()
    @email = @getEmailAddress()
    @

  setCredentials: (credentials) ->
    credentials.updated_at = Math.floor(new Date().getTime() / 1000) unless credentials==null

    PlanckEnv.config.set("cloud.#{@type}.credentials", credentials)
    PlanckEnv.config.save()
    console.log "CloudAPI-#{@type}->setCredentials"
    console.log credentials
    @accessToken = credentials.access_token if credentials

  getCredentials: ->
    PlanckEnv.config.get("cloud.#{@type}.credentials")

  setUserInfo: (userInfo) ->
    userInfo.updatedAt = Math.floor(new Date().getTime() / 1000) unless userInfo==null

    PlanckEnv.config.set("cloud.#{@type}.userinfo", userInfo)
    PlanckEnv.config.save()

  getUserInfo: ->
    userInfo = PlanckEnv.config.get("cloud.#{@type}.userinfo")
    console.log "CloudAPI-#{@type}->getUserInfo"
    console.log userInfo
    return userInfo

  getAccessToken: ->
    credentials = @getCredentials()
    @accessToken = credentials.access_token unless credentials==undefined
    return @accessToken

  getAccountId: ->
    userInfo = @getUserInfo()
    if userInfo then userInfo.accountId else null

  getEmailAddress: ->
    userInfo = @getUserInfo()
    return if userInfo then userInfo.emailAddress else null

  isLoggedIn: ->
    if @getAccessToken() then true else false

  _defaultErrorCallback: (apiError) ->
    console.error(apiError)

  logout: (callback)->
    console.log "CloudAPI-#{@type}->logout"
    BrowserWindow = remote.require('browser-window')
    win = new BrowserWindow
      show: false
    win.loadURL @LOGOUT_URL

    win.webContents.on 'did-finish-load', () =>
      console.log "CloudAPI-#{@type}->logout: logged out"
      @setCredentials null
      @setUserInfo null
      callback(true)

module.exports = CloudAPI
