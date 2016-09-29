_ = require 'underscore'
React = require 'react'
{Actions} = require 'nylas-exports'
{OutlineView,
 ScrollRegion,
 Flexbox,
 RetinaImg} = require 'nylas-component-kit'
ContactsSwitcher = require './components/contacts-switcher'
ContactSidebarStore = require './sidebar-store'


class ContactViewSidebar extends React.Component
  @displayName: 'ContactViewSidebar'

  @containerRequired: false
  @containerStyles:
    minWidth: 180
    maxWidth: 250

  constructor: (@props) ->
    @state = @_getStateFromStores()

  componentDidMount: =>
    @unsubscribers = []
    @unsubscribers.push ContactSidebarStore.listen @_onStoreChange

  componentWillUnmount: =>
    unsubscribe() for unsubscribe in @unsubscribers

  _onStoreChange: =>
    @setState @_getStateFromStores()

  #_getStateFromStores: =>
  #  emailAccounts: ContactSidebarStore.emailAccounts()
  #  storageProviders: ContactSidebarStore.storageProviders()

  _getStateFromStores: =>
    accounts: ContactSidebarStore.emailAccounts()
    focusedAccounts: ContactSidebarStore.focusedAccounts()
    contactslistSections: ContactSidebarStore.contactslistSections()
    accountSection: ContactSidebarStore.accountSection()


  _renderUserSections: (sections) =>
    sections.map (section) =>
      <OutlineView key={section.title} {...section} />

  render: =>
    {accounts, focusedAccounts, contactslistSections, accountSection} = @state

    <Flexbox direction="column" style={order: 0, flexShrink: 1, flex: 1}>
      <ScrollRegion className="contactview-sidebar" style={order: 2}>
        <ContactsSwitcher accounts={accounts} focusedAccounts={focusedAccounts} />
        <div className="email-accounts-section">
          <OutlineView {...accountSection} />
          {@_renderUserSections(contactslistSections)}
        </div>
      </ScrollRegion>
    </Flexbox>


  _renderEmailAccountsSection: (accounts) =>
    accounts.map (account) =>
      <div className="email-account-item-container" key={account.accountId} onClick={=>@_onChooseEmailAccount(account.accountId)}>
        <div className="email-icon-container">
          <RetinaImg name={account.provider} style={width:40, height:40}
            url={"nylas://file-view/assets/ic-email-" + account.provider + "@2x.png"}
            mode={RetinaImg.Mode.ContentPreserve} />
        </div>
        <span className="email-account-name">{account.emailAddress}</span>
      </div>

  _onChooseEmailAccount: (emailAccountId) =>
    #console.log emailAccountId
    Actions.selectEmailAccountForFileView(emailAccountId)

  _onChooseStorageProvider: (storageProvierName) =>
    console.log storageProvierName

module.exports = ContactViewSidebar
