React = require "react"
{ipcRenderer} = require "electron"
{Actions, ComponentRegistry, WorkspaceStore, DropboxAPI, BoxAPI, GoogleDriveAPI, OneDriveAPI} = require "nylas-exports"
{FileList} = require "nylas-component-kit"
FileSidebar = require "./sidebar"

url = require('url')
{remote} = require 'electron'
protocol = remote.require('protocol')
qs = require("querystring")



module.exports =

  activate: ->
    React = require 'react'

    WorkspaceStore.defineSheet 'Files', {root: true},
      split: ['FileSidebar', 'FileList']
      list: ['FileSidebar', 'FileList']

    ComponentRegistry.register FileSidebar,
      location: WorkspaceStore.Location.FileSidebar

    ComponentRegistry.register FileList,
      location: WorkspaceStore.Location.FileList


    # Register Custom URL Scheme for Cloud Storage
    protocol.unregisterProtocol('cloud-storage') # cloud-storage-protocol

    # Now register the new protocol
    protocol.registerStringProtocol 'cloud-storage', (request, callback) =>
      {host:cloud_action, query:rawQuery} = url.parse(request.url) # href, protocol, host, auth, hostname, port, pathname, search, path, query, hash
      params = qs.parse(rawQuery)

      switch params.cloud_type
        when "dropbox"
            CloudAPI = DropboxAPI
        when "box"
            CloudAPI = BoxAPI
        when "googledrive"
            CloudAPI = GoogleDriveAPI
        when "onedrive"
            CloudAPI = OneDriveAPI

      switch cloud_action
        when "auth_success"
          console.log "cloud-storage:auth_success"
          console.log params
          CloudAPI.setCredentials params
          CloudAPI.loadUserInfo(callback: (body, response)->
                                console.log "LoadUserInfo Succedeed"
                                console.log body
                                console.log response)
        when "auth_failure"
          console.log "cloud-storage:auth_failure"
        when "file_link"
          console.log params # clientDraftId, cloud_type, link_url, file_name
          draftClientId = params.draftClientId
          fileUrl = params.link_url
          fileName = params.file_name
          cloudType = params.cloud_type
          @_addLinkToDraft(draftClientId,fileUrl,fileName,cloudType)

  deactivate: ->
    ComponentRegistry.unregister FileSidebar
    ComponentRegistry.unregister FileList
    ComponentRegistry.unregister FilePreview

  serialize: -> @state
