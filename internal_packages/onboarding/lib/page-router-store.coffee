Reflux = require 'reflux'
OnboardingActions = require './onboarding-actions'
TokenAuthAPI = require './token-auth-api'
{AccountStore, Actions} = require 'nylas-exports'
{ipcRenderer} = require 'electron'
NylasStore = require 'nylas-store'
url = require 'url'

return unless PlanckEnv.getWindowType() is "onboarding"

class PageRouterStore extends NylasStore
  constructor: ->
    PlanckEnv.onWindowPropsReceived @_onWindowPropsChanged

    @_page = PlanckEnv.getWindowProps().page ? ''
    @_pageData = PlanckEnv.getWindowProps().pageData ? {}
    @_pageStack = [{page: @_page, pageData: @_pageData}]

    @_checkTokenAuthStatus()
    @listenTo OnboardingActions.moveToPreviousPage, @_onMoveToPreviousPage
    @listenTo OnboardingActions.moveToPage, @_onMoveToPage
    @listenTo OnboardingActions.closeWindow, @_onCloseWindow
    @listenTo OnboardingActions.accountJSONReceived, @_onAccountJSONReceived
    @listenTo OnboardingActions.retryCheckTokenAuthStatus, @_checkTokenAuthStatus

  _onAccountJSONReceived: (json) =>
    console.log "PageRouterStore->_onAccountJSONReceived", json
    isFirstAccount = AccountStore.accounts().length is 0
    AccountStore.addAccountFromJSON(json)
    ipcRenderer.send('new-account-added')
    PlanckEnv.displayWindow()
    if isFirstAccount
      @_onMoveToPage('initial-preferences', {account: json})
      Actions.recordUserEvent('First Account Linked')
    else
      # When account JSON is received, we want to notify external services
      # that it succeeded. Unfortunately in this case we're likely to
      # close the window before those requests can be made. We add a short
      # delay here to ensure that any pending requests have a chance to
      # clear before the window closes.
      setTimeout ->
        ipcRenderer.send('account-setup-successful')
      , 100

  _onWindowPropsChanged: ({page, pageData}={}) =>
    console.log "PageRouterStore->_onWindowPropsChanged"
    console.log page
    @_onMoveToPage(page, pageData)

  page: -> @_page

  pageData: -> @_pageData

  tokenAuthEnabled: -> @_tokenAuthEnabled

  tokenAuthEnabledError: -> @_tokenAuthEnabledError

  connectType: ->
    @_connectType

  _onMoveToPreviousPage: ->
    current = @_pageStack.pop()
    prev = @_pageStack.pop()
    @_onMoveToPage(prev.page, prev.pageData)

  _onMoveToPage: (page, pageData={}) ->
    console.log "PageRouterStore->_onMoveToPage"
    console.log page
    @_pageStack.push({page, pageData})
    @_page = page
    @_pageData = pageData
    @trigger()

  _onCloseWindow: ->
    isFirstAccount = AccountStore.accounts().length is 0
    if isFirstAccount
      PlanckEnv.quit()
    else
      PlanckEnv.close()

  _checkTokenAuthStatus: ->
    @_tokenAuthEnabled = "unknown"
    @_tokenAuthEnabledError = null
    @trigger()

    TokenAuthAPI.request
      path: "/status/"
      returnsModel: false
      timeout: 10000
      success: (json) =>
        if json.restricted
          @_tokenAuthEnabled = "yes"
        else
          @_tokenAuthEnabled = "no"

        if @_tokenAuthEnabled is "no" and @_page is 'token-auth'
          @_onMoveToPage("account-choose")
        else
          @trigger()

      error: (err) =>
        if err.statusCode is 404
          err.message = "Sorry, we could not reach the Nylas API. Please try again."
        @_tokenAuthEnabledError = err.message
        @trigger()

module.exports = new PageRouterStore()
