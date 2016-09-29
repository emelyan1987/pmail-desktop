React = require 'react'
{Actions} = require 'nylas-exports'
{RetinaImg} = require 'nylas-component-kit'
ContactsCommands = require '../contacts-commands'


class ContactsSwitcher extends React.Component
  @displayName: 'ContactsSwitcher'

  @propTypes:
    accounts: React.PropTypes.array.isRequired
    focusedAccounts: React.PropTypes.array.isRequired


  _makeMenuTemplate: =>
    template = ContactsCommands.menuTemplate(
      @props.accounts,
      @props.focusedAccounts,
      clickHandlers: true
    )
    template = template.concat [
      {type: 'separator'}
      {label: 'Add Contact...', click: @_onAddContact}
      {label: 'Manage Accounts...', click: @_onManageAccounts}
    ]
    return template

  # Handlers

  _onAddContact: =>
    ipc = require('electron').ipcRenderer
    ipc.send('command', 'application:add-account')

  _onManageAccounts: =>
    Actions.switchPreferencesTab('Accounts')
    Actions.openPreferences()

  _onShowMenu: =>
    remote = require('electron').remote
    Menu = remote.Menu
    menu = Menu.buildFromTemplate(@_makeMenuTemplate())
    menu.popup()

  render: =>
    <div className="contacts-switcher" onMouseDown={@_onShowMenu}>
      <RetinaImg
        style={width: 13, height: 14}
        name="account-switcher-dropdown.png"
        mode={RetinaImg.Mode.ContentDark} />
    </div>


module.exports = ContactsSwitcher
