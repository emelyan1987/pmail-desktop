/**
 * Created by lionstar on 8/25/16.
 */
/** @babel */
import _ from 'underscore'
import React, {Component, PropTypes} from 'react'
import {Actions, FileProviderStore} from 'nylas-exports'
import {Menu, MenuItem, RetinaImg} from 'nylas-component-kit'



class FileProviderPopover extends Component {
    static displayName = 'FileProviderPopover';

    static propTypes = {
        onSelectProvider: PropTypes.func.isRequired
    };

    constructor(props) {
        //console.log("FileProviderPopover->constructor");
        super(props);

        const items = [];
        items.push(FileProviderStore.localProvider());
        items.push({type:'separator', id:'divider-1'});

        _.each(FileProviderStore.emailProviders(), (provider)=>{
            items.push(provider);
        });


        const cloudProviders = FileProviderStore.signedCloudProviders();
        //console.log(cloudProviders);
        if(cloudProviders.length) {

            items.push({type:'separator', id:'divider-2'});

            _.each(cloudProviders, (provider)=>{
                items.push(provider);
            });
        }


        this.items = items;
        //console.log(this.items);
    }

    onEscape() {
        Actions.closePopover();
    }

    onSelectMenuOption = (item)=> {
        //console.log("FileProviderPopover->onSelectMenuOption");
        Actions.closePopover();
        this.props.onSelectProvider(item);
    };


    renderMenuOption(item) {
        if(item.type == 'separator')
            return (
                <Menu.Item divider={true} key={item.id}/>
            );
        else
            return (
                <div className="file-provider-option" key={item.id}>
                    <RetinaImg name={"ic-provider-"+item.provider+".png"}
                               mode={RetinaImg.Mode.ContentPreserve} /> {item.title}
                </div>
            );
    }

    render() {
        //console.log("FileProviderPopover");
        //console.log(this.items);
        const headerComponents = [
            <span key="file-provider-header">File Provider:</span>,
        ]

        return (
            <div className="file-provider-popover">
                <Menu
                    ref="menu"
                    items={this.items}
                    itemKey={item => item.id}
                    itemContent={this.renderMenuOption}
                    defaultSelectedIndex={-1}
                    headerComponents={headerComponents}
                    onEscape={this.onEscape}
                    onSelect={this.onSelectMenuOption} />
            </div>
        );
    }

}

export default FileProviderPopover
