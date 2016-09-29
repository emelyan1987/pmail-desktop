React = require 'react'

class StatusViewer extends React.Component
  @displayName: 'StatusViewer'

  constructor: (@props)->
    @state = @props.data

  render: ->
    console.log "StatusViewer"
    console.log @state
    <div style={position:'relative', height:'100%'}>
        <div style={position:'absolute', top:'50%', height:'30%', width:'100%', textAlign:'center'}>
            {@state.text}
        </div>
    </div>

module.exports = StatusViewer
