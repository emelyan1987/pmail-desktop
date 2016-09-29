import _ from 'underscore'
import {
  Actions,
} from 'nylas-exports'

export default class FileListContextMenu {
  constructor(files=[]) {
    this.files = files
  }

  menuItemTemplate() {
    return _.compact([this.attachLinkItem(), this.attachDownloadItem(), this.downloadItem()]);
  }

  attachLinkItem() {
    return {
      label: "Attach Via Link",
      click: () => {
        Actions.attachFileLinks(this.files);
      },
    }
  }

  attachDownloadItem() {
    flag = false;
    _.each(this.files,(file)=>{
      if(file.isFolder || file.size > 25 * 1000000) flag = true;
    });

    if(flag) return null;
    return {
      label: "Attach Via Download",
      click: () => {
        Actions.attachFileDownloads(this.files);
      },
    }
  }

  downloadItem() {
    if (this.files.length !== 1 || this.files[0].isFolder) { return null }
    return {
      label: "Download this file",
      click: () => {
        Actions.fetchAndSaveAllFiles(this.files);
      },
    }
  }

  displayMenu() {
    const {remote} = require('electron')

    let template = this.menuItemTemplate();
    console.log("FileListContextMenu->displayMenu()");
    console.log(template);
    remote.Menu.buildFromTemplate(template)
        .popup(remote.getCurrentWindow());
  }
}
