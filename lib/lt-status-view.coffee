module.exports =
class LTStatusView
  constructor: ->
    @viewUpdatePending = false
    
    @element = document.createElement('status-bar-lt-server-info')
    @element.classList.add('lt-server-info', 'inline-block', 'hide')
    @logo = document.createElement('a')
    @logo.textContent = 'LT'
    @element.appendChild(@logo)
    
    lthelper = require './ltserver-helper'
    @subscription = lthelper.onDidChangeLTInfo ( (info) =>
      @update(info)
    )
    
    @tooltip = atom.tooltips.add(@element, title: => "#{@info.name} Version: #{@info.version} (#{@info.buildDate})")
    
  destroy: ->
    @tooltip.dispose()
    @subscription.dispose
        
  update: (info) ->
    return if @viewUpdatePending
    @viewUpdatePending = true
    @updateSubscription = atom.views.updateDocument =>
      @viewUpdatePending = false
      @info = info
      if @info
        @element.classList.remove('hide')
      else
        @element.classList.add('hide')