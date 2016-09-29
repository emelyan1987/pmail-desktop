NylasStore = require 'nylas-store'
_ = require 'underscore'
{Actions,
 AccountStore,
 DatabaseStore,
 ThreadCountsStore,
 WorkspaceStore,
 OutboxStore,
 FocusedPerspectiveStore,
 CategoryStore,
 Utils} = require 'nylas-exports'

SidebarSection = require './sidebar-section'
SidebarActions = require './sidebar-actions'
ContactsCommands = require './contacts-commands'
ContactSidebarStore = require './sidebar-store'

Sections = {
  "Account",
  "Contactslist"
}

StorageProviders = [
  {
    id: "dropbox"
    title: "Dropbox"
  }
  {
    id: "box"
    title: "Box"
  }
  {
    id: "googledrive"
    title: "Google Drive"
  }
  {
    id: "onedrive"
    title: "OneDrive"
  }
  {
    id: "icloud"
    title: "iCloud Drive"
  }
  {
    id: "evernote"
    title: "Evernote"
  }
]

class ContactSidebarStore extends NylasStore

  constructor: ->
    PlanckEnv.savedState.sidebarKeysCollapsed ?= {}

    @_sections = {}
    @_sections[Sections.Account] = {}
    @_sections[Sections.Contactslist] = []
    @_planckdb = null
    @_getplanckdb()
    @_focusedAccounts = FocusedPerspectiveStore.current().accountIds.map (id) ->
      AccountStore.accountForId(id)
    @_registerCommands()
    @_registerMenuItems()
    @_storageProviders = StorageProviders
    @_registerListeners()
    #@_updateSections()
    @_updateContactSections()

  emailAccounts: ->
    AccountStore.accounts()

  focusedAccounts: ->
    @_focusedAccounts

  accountSection: ->
    @_sections[Sections.Account]

  contactslistSections: ->
    @_sections[Sections.Contactslist]

  putcontactslistSections: (self, contactsresults) ->
    self._sections[Sections.Contactslist] = contactsresults.map (acc) ->
      opts = {}

      opts.title = acc.contact_address
      opts.collapsible = false
      SidebarSection.forUserContacts(acc, opts)

    self.trigger()

  putcontactslistSectionsself: (contactsresults) ->
    @_sections[Sections.Contactslist] = contactsresults.map (acc) ->
      opts = {}

      opts.title = acc.contact_address
      opts.collapsible = false
      SidebarSection.forUserContacts(acc, opts)
    @trigger()


  storageProviders: ->
    @_storageProviders

  _getplanckdb: ->
    planckdb = DatabaseStore.getplanckdb()

    if not planckdb
      setTimeout(@_getplanckdb, 10)
      return

    @_planckdb = planckdb

  _registerListeners: ->
    @listenTo SidebarActions.focusAccounts, @_onAccountsFocused
    @listenTo SidebarActions.setKeyCollapsed, @_onSetCollapsed
    @listenTo AccountStore, @_onAccountsChanged
    @listenTo FocusedPerspectiveStore, @_onFocusedPerspectiveChanged
    #@listenTo WorkspaceStore, @_updateSections
    #@listenTo OutboxStore, @_updateSections
    #@listenTo ThreadCountsStore, @_updateSections
    #@listenTo CategoryStore, @_updateSections
    @listenTo WorkspaceStore, @_updateContactSections
    @listenTo OutboxStore, @_updateContactSections
    @listenTo ThreadCountsStore, @_updateContactSections
    @listenTo CategoryStore, @_updateContactSections


    @configSubscription = PlanckEnv.config.onDidChange(
      'core.workspace.showUnreadForAllCategories',
      #@_updateSections
      @_updateContactSections
    )

    return

  _onSetCollapsed: (key, collapsed) =>
    PlanckEnv.savedState.sidebarKeysCollapsed[key] = collapsed
    #@_updateSections()
    @_updateContactSections()

  _registerCommands: (accounts = AccountStore.accounts()) =>
    ContactsCommands.registerCommands(accounts)

  _registerMenuItems: (accounts = AccountStore.accounts()) =>
    #ContactsCommands.registerMenuItems(accounts, @_focusedAccounts)

  _onAccountsFocused: (accounts) =>
    Actions.focusDefaultMailboxPerspectiveForAccounts(accounts)
    @_focusedAccounts = accounts
    @_registerMenuItems()
    #@_updateSections()
    @_updateContactSections()

  _onAccountsChanged: =>
    accounts = AccountStore.accounts()
    @_focusedAccounts = accounts
    @_registerCommands()
    @_registerMenuItems()
    #@_updateSections()
    @_updateContactSections()


  _onFocusedPerspectiveChanged: =>
    currentIds = _.pluck(@_focusedAccounts, 'id')
    newIds = FocusedPerspectiveStore.current().accountIds
    newIdsNotInCurrent = _.difference(newIds, currentIds).length > 0
    if newIdsNotInCurrent
      @_focusedAccounts = newIds.map (id) -> AccountStore.accountForId(id)
      @_registerMenuItems()
    #@_updateSections()
    @_updateContactSections()

  _updateSections: =>
    accounts = @_focusedAccounts
    multiAccount = accounts.length > 1

    @_sections[Sections.Account] = SidebarSection.standardSectionForAccounts(accounts)
    @_sections[Sections.Contactslist] = accounts.map (acc) ->
      opts = {}
      if multiAccount
        opts.title = acc.label
        opts.collapsible = false
      SidebarSection.forUserCategories(acc, opts)
    @trigger()

  _updateContactSections: =>
    accounts = @_focusedAccounts
    multiAccount = accounts.length > 1

    #console.log "accounts values #{accounts['label']}"
    @_sections[Sections.Account] = SidebarSection.standardSectionForAccounts(accounts)

    if multiAccount
      query = "select * from main.PlanckContacts;"
    else
      selectedAccount = accounts.map (account_value) ->
        selectresult = []
        selectresult.email_address = account_value.label

      query = "select * from main.PlanckContacts where email_address = '#{selectedAccount}';"

    putcontactslistSections_func = @putcontactslistSections
    self = @

    if @_planckdb
      @_planckdb.all "#{query}", values = [], (err, results = []) ->
        if err
          console.log("getdata error: Query #{query}, failed #{err.toString()}")
        else
          putcontactslistSections_func self, results

    else
      @_getplanckdb()
      setTimeout(@_updateContactSections, 10)


module.exports = new ContactSidebarStore()
