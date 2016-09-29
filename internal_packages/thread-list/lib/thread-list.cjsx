_ = require 'underscore'
React = require 'react'
ReactDOM = require 'react-dom'
classNames = require 'classnames'

{MultiselectList,
 FocusContainer,
 EmptyListState,
 FluxContainer,
 ResizableRegion,
 Flexbox,
 RetinaImg} = require 'nylas-component-kit'

{Actions,
 Thread,
 Category,
 CanvasUtils,
 TaskFactory,
 ChangeUnreadTask,
 ChangeStarredTask,
 WorkspaceStore,
 AccountStore,
 CategoryStore,
 FocusedContentStore,
 MailboxPerspective,
 FocusedPerspectiveStore} = require 'nylas-exports'

ThreadListColumns = require './thread-list-columns'
ThreadListScrollTooltip = require './thread-list-scroll-tooltip'
ThreadListStore = require './thread-list-store'
ThreadListContextMenu = require './thread-list-context-menu'
CategoryRemovalTargetRulesets = require './category-removal-target-rulesets'


class ThreadList extends React.Component
  @displayName: 'ThreadList'

  @containerRequired: false
  @containerStyles:
    minWidth: 300
    maxWidth: 3000

  constructor: (@props) ->
    @state =
      style: 'unknown'
      prevSelItem: ''
      curSelItem: 'important'

  componentDidMount: =>
    window.addEventListener('resize', @_onResize, true)
    ReactDOM.findDOMNode(@).addEventListener('contextmenu', @_onShowContextMenu)
    @_onResize()

  componentWillUnmount: =>
    window.removeEventListener('resize', @_onResize, true)
    ReactDOM.findDOMNode(@).removeEventListener('contextmenu', @_onShowContextMenu)

  _shift: ({offset, afterRunning}) =>
    dataSource = ThreadListStore.dataSource()
    focusedId = FocusedContentStore.focusedId('thread')
    focusedIdx = Math.min(dataSource.count() - 1, Math.max(0, dataSource.indexOfId(focusedId) + offset))
    item = dataSource.get(focusedIdx)
    afterRunning()
    Actions.setFocus(collection: 'thread', item: item)

  _keymapHandlers: ->
    'application:remove-from-view': =>
      @_onRemoveFromView()
    'application:gmail-remove-from-view': =>
      @_onRemoveFromView(CategoryRemovalTargetRulesets.Gmail)
    'application:archive-item': @_onArchiveItem
    'application:delete-item': @_onDeleteItem
    'application:star-item': @_onStarItem
    'application:mark-important': => @_onSetImportant(true)
    'application:mark-unimportant': => @_onSetImportant(false)
    'application:mark-as-unread': => @_onSetUnread(true)
    'application:mark-as-read': => @_onSetUnread(false)
    'application:report-as-spam': => @_onMarkAsSpam(false)
    'application:remove-and-previous': =>
      @_shift(offset: -1, afterRunning: @_onRemoveFromView)
    'application:remove-and-next': =>
      @_shift(offset: 1, afterRunning: @_onRemoveFromView)
    'thread-list:select-read': @_onSelectRead
    'thread-list:select-unread': @_onSelectUnread
    'thread-list:select-starred': @_onSelectStarred
    'thread-list:select-unstarred': @_onSelectUnstarred

  render: ->
    if @state.style is 'wide'
      columns = ThreadListColumns.Wide
      itemHeight = 36
    else
      columns = ThreadListColumns.Narrow
      itemHeight = 85

    #####################################################################
    ## Added by Emelyan.A

    <Flexbox direction="column" style={order: 0, flexShrink: 1, flex: 1}>
      {@_renderTabs()}
      <FluxContainer
        stores=[ThreadListStore]
        getStateFromStores={ -> dataSource: ThreadListStore.dataSource() }>
        <FocusContainer collection="thread">
          <MultiselectList
            ref="list"
            columns={columns}
            itemPropsProvider={@_threadPropsProvider}
            itemHeight={itemHeight}
            className="thread-list thread-list-#{@state.style}"
            scrollTooltipComponent={ThreadListScrollTooltip}
            emptyComponent={EmptyListState}
            keymapHandlers={@_keymapHandlers()}
            onDragStart={@_onDragStart}
            onDragEnd={@_onDragEnd}
            draggable="true" />
        </FocusContainer>
      </FluxContainer>
    </Flexbox>

  _renderTabs: =>
    <div className="thread-tabs-container">
      <span id="tab-item-important" className="tab-item" onClick={@_onImportantTab}>Important</span>
      <span id="tab-item-social" className="tab-item" onClick={@_onSocialTab}>Social</span>
      <span id="tab-item-clutter" className="tab-item" onClick={@_onClutterTab}>Clutter</span>
      <span id="tab-item-reminder" className="tab-item" onClick={@_onReminderTab}>Reminder</span>
      <span id="tab-item-filter" className="tab-item" onMouseDown={@_onShowFilter}>
        <RetinaImg
          className="thread-filter-tab-button"
          style={width: 18, height: 18}
          url="nylas://thread-list/assets/tab-filter@2x.png"
          title="Filter"
          mode={RetinaImg.Mode.ContentDark} />
      </span>
    </div>

  _selectTabItem: (itemName) =>
    document.getElementById("tab-item-#{itemName}").style.borderBottomColor = "turquoise"
    document.getElementById("tab-item-#{itemName}").style.color = "turquoise"

  _deselectTabItem: (itemName) =>
    document.getElementById("tab-item-#{itemName}").style.borderBottomColor = "#f6f6f6"
    document.getElementById("tab-item-#{itemName}").style.color = "#231f20"

  # Handlers

  _onImportantTab: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "important"
    @_deselectTabItem(@state.prevSelItem)
    @_selectTabItem(@state.curSelItem)

    @_viewThreadListByStandardCategoryName("inbox")

  _onSocialTab: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "social"
    @_deselectTabItem(@state.prevSelItem)
    @_selectTabItem(@state.curSelItem)

    @_viewThreadListByUserCategoryDisplayName("Social")

  _onClutterTab: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "clutter"
    @_deselectTabItem(@state.prevSelItem)
    @_selectTabItem(@state.curSelItem)

    @_viewThreadListByUserCategoryDisplayName("Read Later")

  _onReminderTab: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "reminder"
    @_deselectTabItem(@state.prevSelItem)
    @_selectTabItem(@state.curSelItem)

    @_viewThreadListByUserCategoryDisplayName("N1-Snoozed")

  _onShowFilter: =>
    @state.prevSelItem = @state.curSelItem
    @state.curSelItem = "filter"
    @_deselectTabItem(@state.prevSelItem)
    @_selectTabItem(@state.curSelItem)

    remote = require('electron').remote
    Menu = remote.Menu
    menu = Menu.buildFromTemplate(@_makeMenuTemplate())
    menu.popup()

  _makeMenuTemplate: =>
    template = [
      {label: 'Unread', click: @_onUnreadTab}
      {label: 'Flagged', click: @_onFlaggedTab}
      {label: 'Attachments', click: @_onAttachmentsTab}
    ]
    return template

  _onUnreadTab: =>
    @_viewThreadListByStatusFilterName("unread")

  _onFlaggedTab: =>
    @_viewThreadListByStatusFilterName("flagged")

  _onAttachmentsTab: =>
    @_viewThreadListByStatusFilterName("attachments")

  _getSelAccountIds: =>
    perspective = FocusedPerspectiveStore.current() # current perspective
    console.log perspective
    accountIds = perspective.accountIds
    console.log accountIds
    return accountIds

  _viewThreadListByStandardCategoryName: (standardCategoryName) =>
    selAccountIds = @_getSelAccountIds()
    selCategories = []

    for accountId in selAccountIds
      accountCategories = CategoryStore.categories(accountId)
      console.log accountCategories

      for category in accountCategories
        if category.name == standardCategoryName
          selCategories.push category

    console.log selCategories
    if selCategories.length == 0
      alert "Not found this category !"
      return

    newMailboxPerspective = MailboxPerspective.forCategories(selCategories)
    console.log newMailboxPerspective
    if newMailboxPerspective.accountIds.length == 0
      alert "Empty MailboxPerspective"
      return

    Actions.focusMailboxPerspective(newMailboxPerspective)

  _viewThreadListByUserCategoryDisplayName: (userCategoryDisplayName) =>
    selAccountIds = @_getSelAccountIds()
    selCategories = []

    for accountId in selAccountIds
      accountCategories = CategoryStore.categories(accountId)
      console.log accountCategories

      for category in accountCategories
        if category.displayName == userCategoryDisplayName
          selCategories.push category

    console.log selCategories
    if selCategories.length == 0
      alert "Not found this category!"
      return

    newMailboxPerspective = MailboxPerspective.forCategories(selCategories)
    console.log newMailboxPerspective
    if newMailboxPerspective.accountIds.length == 0
      alert "Empty MailboxPerspective"
      return

    Actions.focusMailboxPerspective(newMailboxPerspective)

  _viewThreadListByStatusFilterName: (statusFilterName) =>
    selAccountIds = @_getSelAccountIds()

    if statusFilterName == "unread"
      newMailboxPerspective = MailboxPerspective.forUnread(selAccountIds)

    if statusFilterName == "flagged"
      newMailboxPerspective = MailboxPerspective.forStarred(selAccountIds)

    if statusFilterName == "attachments"
      newMailboxPerspective = MailboxPerspective.forAttachments(selAccountIds)
      console.log newMailboxPerspective.threads()

    Actions.focusMailboxPerspective(newMailboxPerspective)

################################################################################

  _threadPropsProvider: (item) ->
    props =
      className: classNames
        'unread': item.unread

    props.shouldEnableSwipe = =>
      perspective = FocusedPerspectiveStore.current()
      tasks = perspective.tasksForRemovingItems([item], CategoryRemovalTargetRulesets.Default)
      return tasks.length > 0

    props.onSwipeRightClass = =>
      perspective = FocusedPerspectiveStore.current()
      tasks = perspective.tasksForRemovingItems([item], CategoryRemovalTargetRulesets.Default)
      return null if tasks.length is 0

      # TODO this logic is brittle
      task = tasks[0]
      name = if task instanceof ChangeStarredTask
        'unstar'
      else if task.categoriesToAdd().length is 1
        task.categoriesToAdd()[0].name
      else
        'remove'

      return "swipe-#{name}"

    props.onSwipeRight = (callback) ->
      perspective = FocusedPerspectiveStore.current()
      tasks = perspective.tasksForRemovingItems([item], CategoryRemovalTargetRulesets.Default)
      callback(false) if tasks.length is 0
      Actions.closePopover()
      Actions.queueTasks(tasks)
      callback(true)

    if FocusedPerspectiveStore.current().isInbox()
      props.onSwipeLeftClass = 'swipe-snooze'
      props.onSwipeCenter = =>
        Actions.closePopover()
      props.onSwipeLeft = (callback) =>
        # TODO this should be grabbed from elsewhere
        SnoozePopover = require '../../thread-snooze/lib/snooze-popover'

        element = document.querySelector("[data-item-id=\"#{item.id}\"]")
        originRect = element.getBoundingClientRect()
        Actions.openPopover(
          <SnoozePopover
            threads={[item]}
            swipeCallback={callback} />,
          {originRect, direction: 'right', fallbackDirection: 'down'}
        )

    return props

  _targetItemsForMouseEvent: (event) ->
    itemThreadId = @refs.list.itemIdAtPoint(event.clientX, event.clientY)
    unless itemThreadId
      return null

    dataSource = ThreadListStore.dataSource()
    if itemThreadId in dataSource.selection.ids()
      return {
        threadIds: dataSource.selection.ids()
        accountIds: _.uniq(_.pluck(dataSource.selection.items(), 'accountId'))
      }
    else
      thread = dataSource.getById(itemThreadId)
      return null unless thread
      return {
        threadIds: [thread.id]
        accountIds: [thread.accountId]
      }

  _onShowContextMenu: (event) =>
    data = @_targetItemsForMouseEvent(event)
    if not data
      event.preventDefault()
      return
    (new ThreadListContextMenu(data)).displayMenu()

  _onDragStart: (event) =>
    data = @_targetItemsForMouseEvent(event)
    if not data
      event.preventDefault()
      return

    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.dragEffect = "move"

    canvas = CanvasUtils.canvasWithThreadDragImage(data.threadIds.length)
    event.dataTransfer.setDragImage(canvas, 10, 10)
    event.dataTransfer.setData('nylas-threads-data', JSON.stringify(data))
    return

  _onDragEnd: (event) =>

  _onResize: (event) =>
    current = @state.style
    desired = if ReactDOM.findDOMNode(@).offsetWidth < 540 then 'narrow' else 'wide'
    if current isnt desired
      @setState(style: desired)

  _threadsForKeyboardAction: ->
    return null unless ThreadListStore.dataSource()
    focused = FocusedContentStore.focused('thread')
    if focused
      return [focused]
    else if ThreadListStore.dataSource().selection.count() > 0
      return ThreadListStore.dataSource().selection.items()
    else
      return null

  _onStarItem: =>
    threads = @_threadsForKeyboardAction()
    return unless threads
    task = TaskFactory.taskForInvertingStarred({threads})
    Actions.queueTask(task)

  _onSetImportant: (important) =>
    threads = @_threadsForKeyboardAction()
    return unless threads
    return unless PlanckEnv.config.get('core.workspace.showImportant')

    if important
      tasks = TaskFactory.tasksForApplyingCategories
        threads: threads
        categoriesToRemove: (accountId) -> []
        categoriesToAdd: (accountId) ->
          [CategoryStore.getStandardCategory(accountId, 'important')]

    else
      tasks = TaskFactory.tasksForApplyingCategories
        threads: threads
        categoriesToRemove: (accountId) ->
          important = CategoryStore.getStandardCategory(accountId, 'important')
          return [important] if important
          return []

    Actions.queueTasks(tasks)

  _onSetUnread: (unread) =>
    threads = @_threadsForKeyboardAction()
    return unless threads
    Actions.queueTask(new ChangeUnreadTask({threads, unread}))
    Actions.popSheet()

  _onMarkAsSpam: =>
    threads = @_threadsForKeyboardAction()
    return unless threads
    tasks = TaskFactory.tasksForMarkingAsSpam
      threads: threads
    Actions.queueTasks(tasks)

  _onRemoveFromView: (ruleset = CategoryRemovalTargetRulesets.Default) =>
    threads = @_threadsForKeyboardAction()
    return unless threads
    current = FocusedPerspectiveStore.current()
    tasks = current.tasksForRemovingItems(threads, ruleset)
    Actions.queueTasks(tasks)
    Actions.popSheet()

  _onArchiveItem: =>
    threads = @_threadsForKeyboardAction()
    if threads
      tasks = TaskFactory.tasksForArchiving
        threads: threads
      Actions.queueTasks(tasks)
    Actions.popSheet()

  _onDeleteItem: =>
    threads = @_threadsForKeyboardAction()
    if threads
      tasks = TaskFactory.tasksForMovingToTrash
        threads: threads
      Actions.queueTasks(tasks)
    Actions.popSheet()

  _onSelectRead: =>
    dataSource = ThreadListStore.dataSource()
    items = dataSource.itemsCurrentlyInViewMatching (item) -> not item.unread
    dataSource.selection.set(items)

  _onSelectUnread: =>
    dataSource = ThreadListStore.dataSource()
    items = dataSource.itemsCurrentlyInViewMatching (item) -> item.unread
    dataSource.selection.set(items)

  _onSelectStarred: =>
    dataSource = ThreadListStore.dataSource()
    items = dataSource.itemsCurrentlyInViewMatching (item) -> item.starred
    dataSource.selection.set(items)

  _onSelectUnstarred: =>
    dataSource = ThreadListStore.dataSource()
    items = dataSource.itemsCurrentlyInViewMatching (item) -> not item.starred
    dataSource.selection.set(items)

module.exports = ThreadList
