_ = require 'underscore'
path = require 'path'
fs = require 'fs'
{DropboxDownloadStore} = require 'nylas-exports'
IconUtils =
  ###

  ###
  icon: (file) =>
    return "../static/images/files/folder.png" if file.isFolder

    if file.cloud == 'dropbox'
      iconpath = DropboxDownloadStore.pathForFile(file, true)
      return iconpath if fs.existsSync iconpath

    ext = path.extname file.name

    if ext && ext.length>1
      ext = ext.substring(1)

      return "../static/images/files/#{ext}.png" if fs.existsSync path.join path.resolve(__dirname), "../static/images/files/#{ext}.png"

    return "../static/images/files/_blank.png"


module.exports = IconUtils
