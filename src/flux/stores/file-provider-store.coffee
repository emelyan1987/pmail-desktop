NylasStore = require 'nylas-store'
_ = require 'underscore'

Actions = require '../actions'
DropboxAPI = require '../clouds/dropbox-api'
BoxAPI = require '../clouds/box-api'
GoogleDriveAPI = require '../clouds/googledrive-api'
OneDriveAPI = require '../clouds/onedrive-api'

AccountStore = require './account-store'



class FileProviderStore
    constructor: ->
        #DropboxAPI.setCredentials null
        #DropboxAPI.setUserInfo null
        #BoxAPI.setCredentials null
        #BoxAPI.setUserInfo null
        #GoogleDriveAPI.setCredentials null
        #GoogleDriveAPI.setUserInfo null
        #OneDriveAPI.setCredentials null
        #OneDriveAPI.setUserInfo null

    localProvider: ->
        @_localProvider = {
            type: 'local',
            provider: 'local',
            id: 'local-file-provider',
            title: 'Desktop'
        }

    emailProviders: ->
        @_emailProviders = _.map AccountStore.accounts(), (account)=>
            provider =
                type: 'email'
                provider: account.provider
                id: account.id
                accountId: account.id
                emailAddress: account.emailAddress
                title: account.emailAddress


            return provider

    cloudProviders: ->
        @_cloudProviders = [
            {
                type: 'cloud'
                provider: 'dropbox'
                id: "dropbox-#{DropboxAPI.getAccountId()}"
                accountId: DropboxAPI.getAccountId()
                emailAddress: DropboxAPI.getEmailAddress()
                title: 'Dropbox'
            }
            {
                type: 'cloud'
                provider: 'box'
                id: "box-#{BoxAPI.getAccountId()}"
                accountId: BoxAPI.getAccountId()
                emailAddress: BoxAPI.getEmailAddress()
                title: 'Box'
            }
            {
                type: 'cloud'
                provider: 'googledrive'
                id: "googledrive-#{GoogleDriveAPI.getAccountId()}"
                accountId: GoogleDriveAPI.getAccountId()
                emailAddress: GoogleDriveAPI.getEmailAddress()
                title: 'GoogleDrive'
            }
            {
                type: 'cloud'
                provider: 'onedrive'
                id: "onedrive-#{OneDriveAPI.getAccountId()}"
                accountId: OneDriveAPI.getAccountId()
                emailAddress: OneDriveAPI.getEmailAddress()
                title: 'OneDrive'
            }
        ]

    signedCloudProviders: ->
        @_signedCloudProviders = []

        if DropboxAPI.getAccountId()
            @_signedCloudProviders.push({
                type: 'cloud'
                provider: 'dropbox'
                id: "dropbox-#{DropboxAPI.getAccountId()}"
                accountId: DropboxAPI.getAccountId()
                emailAddress: DropboxAPI.getEmailAddress()
                title: 'Dropbox'
              })

        if BoxAPI.getAccountId()
            @_signedCloudProviders.push({
                    type: 'cloud'
                    provider: 'box'
                    id: "box-#{BoxAPI.getAccountId()}"
                    accountId: BoxAPI.getAccountId()
                    emailAddress: BoxAPI.getEmailAddress()
                    title: 'Box'
            })

        if GoogleDriveAPI.getAccountId()
            @_signedCloudProviders.push({
                    type: 'cloud'
                    provider: 'googledrive'
                    id: "googledrive-#{GoogleDriveAPI.getAccountId()}"
                    accountId: GoogleDriveAPI.getAccountId()
                    emailAddress: GoogleDriveAPI.getEmailAddress()
                    title: 'GoogleDrive'
            })

        if OneDriveAPI.getAccountId()
            @_signedCloudProviders.push({
                    type: 'cloud'
                    provider: 'onedrive'
                    id: "onedrive-#{OneDriveAPI.getAccountId()}"
                    accountId: OneDriveAPI.getAccountId()
                    emailAddress: OneDriveAPI.getEmailAddress()
                    title: 'OneDrive'
            })

        console.log @_signedCloudProviders
        return @_signedCloudProviders

module.exports = new FileProviderStore()
