_ = require 'underscore'
{Actions,
 AccountStore,
 SyncbackCategoryTask,
 DestroyCategoryTask,
 CategoryStore,
 Category} = require 'nylas-exports'
SidebarItem = require './sidebar-item'
SidebarActions = require './sidebar-actions'

isSectionCollapsed = (title) ->
  if PlanckEnv.savedState.sidebarKeysCollapsed[title] isnt undefined
    PlanckEnv.savedState.sidebarKeysCollapsed[title]
  else
    false

toggleSectionCollapsed = (section) ->
  return unless section
  SidebarActions.setKeyCollapsed(section.title, not isSectionCollapsed(section.title))

class SidebarSection

  @empty: (title) ->
    return {
      title,
      items: []
    }

  @standardSectionForAccount: (account) ->
    if not account
      throw new Error("standardSectionForAccount: You must pass an account.")

    cats = CategoryStore.standardCategories(account)
    return @empty(account.label) if cats.length is 0

    items = []

    return {
      title: account.label
      items: items
    }

  @standardSectionForAccounts: (accounts) ->
    return @empty('All Accounts') if not accounts or accounts.length is 0
    return @empty('All Accounts') if CategoryStore.categories().length is 0
    return @standardSectionForAccount(accounts[0]) if accounts.length is 1

    standardNames = []
    items = []

    return {
      title: 'All Accounts'
      items: items
    }

  @forUserCategories: (account, {title, collapsible} = {}) ->
    return unless account
    # Compute hierarchy for user categories using known "path" separators
    # NOTE: This code uses the fact that userCategoryItems is a sorted set, eg:
    #
    # Inbox
    # Inbox.FolderA
    # Inbox.FolderA.FolderB
    # Inbox.FolderB
    #
    items = []
    seenItems = {}

    title ?= account.categoryLabel()
    collapsed = isSectionCollapsed(title)
    if collapsible
      onCollapseToggled = toggleSectionCollapsed

    console.log title
    return {
      title: title
      iconName: account.categoryIcon()
      items: items
    }

  @forUserContacts: (account, {title, collapsible} = {}) ->
    #console.log("param data #{account}")
    return unless account
    # Compute hierarchy for user categories using known "path" separators
    # NOTE: This code uses the fact that userCategoryItems is a sorted set, eg:
    #
    # Inbox
    # Inbox.FolderA
    # Inbox.FolderA.FolderB
    # Inbox.FolderB
    #
    items = []
    seenItems = {}

    title = account.contact_address
    collapsed = isSectionCollapsed(title)
    if collapsible
      onCollapseToggled = toggleSectionCollapsed

    return {
      title: title
      items: items
    }


module.exports = SidebarSection
