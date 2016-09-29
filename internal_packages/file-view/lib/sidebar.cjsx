_ = require 'underscore'
React = require 'react'
{Actions} = require 'nylas-exports'
{OutlineView,
 ScrollRegion,
 Flexbox,
 RetinaImg} = require 'nylas-component-kit'
ContactsSwitcher = require './components/contacts-switcher'
SidebarStore = require './sidebar-store'
SidebarActions = require './sidebar-actions'



class FileViewSidebar extends React.Component
  @displayName: 'FileViewSidebar'

  @containerRequired: false
  @containerStyles:
    minWidth: 180
    maxWidth: 250

  constructor: (@props) ->
    @state = @_getStateFromStore()

  componentDidMount: =>
    @_unlisteners = []
    @_unlisteners.push SidebarStore.listen @_onStoreChange

  componentWillUnmount: =>
    unlisten() for unlisten in @_unlisteners

  _onStoreChange: =>
    @setState @_getStateFromStore()

  _getStateFromStore: =>
      emailProviders: SidebarStore.emailProviders()
      cloudProviders: SidebarStore.cloudProviders()

  render: =>
    {emailProviders, cloudProviders} = @state

    <Flexbox direction="column" style={order: 0, flexShrink: 1, flex: 1}>
      <ScrollRegion className="fileview-sidebar" style={order: 2}>
        <div className="section">
          <div className="title">Email Providers</div>
          {@_renderEmailProvidersSection(emailProviders)}
        </div>
        <div className="section">
          <div className="title">Cloud Providers</div>
          {@_renderCloudProvidersSection(cloudProviders)}
        </div>
      </ScrollRegion>
    </Flexbox>

  _renderEmailProvidersSection: (providers) =>
    providers.map (provider) =>
      <div className="item-container" key={provider.accountId} onClick={=>@_onSelectProvider(provider)}>
        <div className="item">
            <div className="icon"><RetinaImg name="ic-provider-#{provider.provider}.png"
                        mode={RetinaImg.Mode.ContentPreserve} /></div>
            <div className="name">{provider.emailAddress}</div>
        </div>
      </div>

  _renderCloudProvidersSection: (providers) =>
    providers.map (provider) =>
      isLoggedIn = true if provider.accountId
      <div className="item-container" key={provider.provider} onClick={=>@_onSelectProvider(provider)}>
        <div className="item">
            <div className="icon"><RetinaImg name={"ic-provider-" + provider.provider + (unless isLoggedIn then "-disabled" else "") + ".png"}
                        mode={RetinaImg.Mode.ContentPreserve} /></div>
            <div className="name">{(unless isLoggedIn then "Add " else "Your ") + provider.provider}</div>
        </div>
      </div>


  _onSelectProvider: (provider) =>
    console.log provider
    SidebarActions.selectFileProvider(provider)

module.exports = FileViewSidebar
