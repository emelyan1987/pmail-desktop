React = require 'react'
_ = require 'underscore'
{RetinaImg} = require 'nylas-component-kit'
{Utils, Actions} = require 'nylas-exports'

OnboardingActions = require './onboarding-actions'
Providers = require './account-types'
url = require 'url'

class AccountChoosePage extends React.Component
  @displayName: "AccountChoosePage"

  constructor: (@props) ->
    @state =
      email: ""
      provider: ""

  componentWillUnmount: ->
    @_usub?()

  componentDidMount: ->
    if @props.pageData.provider
      providerData = _.findWhere(Providers, name: @props.pageData.provider)
      if providerData
        @_onChooseProvider(providerData)

  render: =>
    <div className="page account-choose">
      <div className="quit" onClick={ -> OnboardingActions.closeWindow() }>
        <RetinaImg name="onboarding-close.png" mode={RetinaImg.Mode.ContentPreserve}/>
      </div>

      <div className="caption" style={marginTop: 33, marginBottom:25}>Select your email provider:</div>

      {@_renderProviders()}

    </div>

  _renderProviders: ->
    return Providers.map (provider) =>
      <div className={"provider "+provider.name} key={provider.name} onClick={=>@_onChooseProvider(provider)}>

        <div className="icon-container">
          <RetinaImg name={provider.icon} mode={RetinaImg.Mode.ContentPreserve} className="icon"/>
        </div>
        <span className="provider-name">{provider.displayName}</span>
      </div>

  _renderError: ->
    if @state.error
      <div className="alert alert-danger" role="alert">
        {@state.error}
      </div>
    else <div></div>

  _onEmailChange: (event) =>
    @setState email: event.target.value

  _onChooseProvider: (provider) =>
    Actions.recordUserEvent('Auth Flow Started', {
      provider: provider.name
    })

    if provider.name is 'gmail'
      # Show the "Sign in to Gmail" prompt for a moment before actually bouncing
      # to Gmail. (400msec animation + 200msec to read)
      _.delay =>
        @_onBounceToGmail(provider)
      , 600
    OnboardingActions.moveToPage("account-settings", {provider})

  _base64url: (buf) ->
    # Python-style urlsafe_b64encode
    buf.toString('base64')
      .replace(/\+/g, '-') # Convert '+' to '-'
      .replace(/\//g, '_') # Convert '/' to '_'

  _onBounceToGmail: (provider) =>
    crypto = require 'crypto'

    # Client key is used for polling. Requirements are that it not be guessable
    # and that it never collides with an active key (keys are active only between
    # initiating gmail auth and successfully requesting the account data once.
    provider.clientKey = @_base64url(crypto.randomBytes(40))

    # Encryption key is used to AES encrypt the account data during storage on the
    # server.
    provider.encryptionKey = crypto.randomBytes(24)
    provider.encryptionIv = crypto.randomBytes(16)
    code = PlanckEnv.config.get('invitationCode') || ''
    state = [provider.clientKey,@_base64url(provider.encryptionKey),@_base64url(provider.encryptionIv),code].join(',')

    googleUrl = url.format({
      protocol: 'https'
      host: 'accounts.google.com/o/oauth2/auth'
      query:
        response_type: 'code'
        state: state
        client_id: '65711481506-e1cbv4cci49vacn58n9ujdp4j4hha9pp.apps.googleusercontent.com'
        redirect_uri: "https://sync-dev.planckapi.com/static/callback/gmail.html"
        access_type: 'offline'
        scope: 'https://www.googleapis.com/auth/userinfo.email \
            https://www.googleapis.com/auth/userinfo.profile \
            https://mail.google.com/ \
            https://www.google.com/m8/feeds \
            https://www.googleapis.com/auth/calendar'
        prompt: 'consent'
    })
    #{shell} = require 'electron'
    #shell.openExternal(googleUrl)

    {remote} = require 'electron'
    BrowserWindow = remote.require('browser-window')
    w = new BrowserWindow
      title: "Google Authentication"
      nodeIntegration: false
      webPreferences:
        webSecurity:false
      width: 800
      height: 650

    w.loadURL googleUrl

module.exports = AccountChoosePage
