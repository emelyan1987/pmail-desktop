NylasStore = require 'nylas-store'
Rx = require 'rx-lite'
_ = require 'underscore'
Request = require 'request'
progress = require 'request-progress'

{Message,
 MutableQueryResultSet,
 MutableQuerySubscription,
 ObservableListDataSource,
 DatabaseStore,
 FileDownloadStore,
 MessageStore,
 Actions,
 File,
 Message,
 NylasAPI} = require 'nylas-exports'
{ListTabular} = require 'nylas-component-kit'

class ContactListStore extends NylasStore
  constructor: ->
    console.log "Contact List Store"

    @listenTo Actions.selectEmailAccountForFileView, @_onFileViewChanged
    @_createFileListDataSource(null)

  dataSource: =>
    @_dataSource

  selectionObservable: =>
    return Rx.Observable.fromListSelection(@)

  # Inbound Events

  _onFileViewChanged: (emailId) =>
    @_createFileListDataSource(emailId)

  # Internal

  _createFileListDataSource: (emailId) =>

    console.log emailId

    if emailId != null
      query = DatabaseStore.findAll(File)
        .order(File.attributes.filename.descending())
        .where(accountId: emailId)
        .page(0, 1)

      subscription = new MutableQuerySubscription(query, {asResultSet: true})
      $resultSet = Rx.Observable.fromNamedQuerySubscription('file-list', subscription)
      @_dataSource = new ObservableListDataSource($resultSet, subscription.replaceRange)
      console.log @_dataSource

    else
      @_dataSource = new ListTabular.DataSource.Empty()

    @trigger(@)

  _sendFileRequest: (emailId) =>
    ###
    NylasAPI.makeRequest
      path: "/files"
      accountId: emailId
      returnsModel: true
    .then (body)  =>
      console.log "Get Files Success"
      @_getFileList(body, emailId)
      #return if @_unmounted
      #@setState({error: null})
      # message will be put into the database and the MessageBodyProcessor
      # will provide us with the new body once it's been processed.
    .catch (error) =>
      console.log "Get Files Error"
      console.log error
    ###

module.exports = new ContactListStore()
