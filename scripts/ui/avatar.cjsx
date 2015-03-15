React = require 'react'
md5 = require('blueimp-md5').md5

module.exports = React.createClass

  displayName: 'avatar'

  propTypes:
    user: React.PropTypes.number.isRequired
    default: React.PropTypes.string

  getDefaultProps: ->
    default: 'retro'

  render: ->
    <img
      className='avatar'
      src={"//www.gravatar.com/avatar/#{md5 @props.user}?d=#{@props.default}"}
    />
