/**
 * Created by lionstar on 8/25/16.
 */
import _ from 'underscore';
import {remote} from 'electron';
import React,{PropTypes} from 'react';
import Actions from '../../flux/actions';

import {Flexbox, RetinaImg, ScrollRegion, ButtonDropdown, Menu} from 'nylas-component-kit';
import {FileStore, DraftStore} from 'nylas-exports';

import FileList from './file-list';


class FilePicker extends React.Component {
    static displayName = 'FilePicker';

    static propTypes = {
        draftClientId: PropTypes.string.isRequired,
        provider: PropTypes.object.isRequired,
        onSelect: PropTypes.func.isRequired,
    };
    constructor(props) {
        super(props);
        //this.themes = PlanckEnv.themes;
        //this.state = this._getState();

    }

    componentDidMount() {
        // this.disposable = this.themes.onDidChangeActiveThemes(() => {
        //     this.setState(this._getState());
        // });
    }

    componentWillUnmount() {
        //this.disposable.dispose();
    }


    render() {
        const menu = (
            <Menu
                items={[{id:'link',title:'Attach link',icon:'fa fa-link'},{id:'download',title:'Attach download',icon:'fa fa-download'}]}
                itemKey={ (item) => item.id }
                itemContent={(item)=>{return <div><i className={item.icon}></i>&nbsp;{item.title}</div>}}
                onSelect={this._onAttachWithAction}
            />
        );
        return (
            <div className="file-picker">
                <div className="header">Select files...</div>
                <div className="content">
                    <FileList provider={this.props.provider} selector={true} ref="filelist"/>
                </div>
                <div className="footer">
                    <div style={{order: 0, flex: 1}}/>
                    <button className="btn btn-default" style={{marginRight:15}} onClick={this._onCancel}>Cancel</button>
                    <ButtonDropdown
                        className={"btn-emphasis"}
                        primaryItem="Attach"
                        primaryTitle="asdfasdfasfff"
                        primaryClick={this._onAttach}
                        closeOnMenuClick
                        menu={menu}/>
                </div>
            </div>
        );
    }

    _onCancel = () => {
        console.log("FilePicker->_onCancel")
        Actions.closeModal();
    }

    _verifyFilesToDownload = (files) => {
        for(index in files) {
            const file = files[index];
            console.log(file);
            if(file.isFolder) {
                remote.dialog.showMessageBox({
                    type: 'warning',
                    message: "Invalid file",
                    detail: "Can't download the folder. Please try to attach as link",
                    buttons: ["OK"]
                });

                return false;
            }
            if(file.size > 25 * 1000000) {
                remote.dialog.showMessageBox({
                    type: 'warning',
                    message: "Invalid file",
                    detail: "Can't download the file exceed 25MB. Please try to attach as link",
                    buttons: ["OK"]
                });

                return false;
            }
        }

        return true;
    }

    tryAttachDownload = (files) => {
        if(this._verifyFilesToDownload(files)) {
            DraftStore.sessionForClientId(this.props.draftClientId).then ((session)=> {
                downloads = session.draft().downloads.concat(files);
                session.changes.add({downloads});
                session.changes.commit();

                Actions.closeModal();console.log(downloads);

            });
        }
    }
    _onAttach = () => {
        const files = this.refs.filelist.selections();
        this.tryAttachDownload(files);
    }
    _onAttachWithAction = (action) => {
        console.log("FilePicker->_onOk")
        console.log(this.refs.filelist.selections());
        console.log(action);

        const files = this.refs.filelist.selections();
        if(files && files.length) {
            if(action.id == 'link') {
                console.log(this.props.provider);
                if(this.props.provider.type == 'email') {
                    remote.dialog.showMessageBox({
                        type: 'warning',
                        message: "Invalid file",
                        detail: "Can't attach with link. Please try to attach as download",
                        buttons: ["OK"]
                    });
                    return;
                }
                FileStore.getShareLinks(files, this.props.provider, (links)=>{
                    console.log(links);
                    if(links && links.length) {
                        DraftStore.sessionForClientId(this.props.draftClientId).then ((session)=> {
                            let tags = _.map(links, (link)=>{
                                return "<a href='"+link+"'>"+link+"</a>";
                            });

                            body = session.draft().body + '<br><br>' + tags.join('<br>');
                            session.changes.add({body});
                            session.changes.commit();

                            Actions.closeModal();
                        });
                    }
                });
            } else if(action.id == 'download') {
                this.tryAttachDownload(files);
            }
        }
    }



}

export default FilePicker;
