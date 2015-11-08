do ->
  $ = window.jQuery
  # Default options

  createSvgElement = (name) ->
    document.createElementNS svgNS, name

  leadingZero = (num) ->
    (if num < 10 then '0' else '') + num

  uniqueId = (prefix) ->
    id = ++idCounter + ''
    if prefix then prefix + id else id

  # LolliClock

  LolliClock = (element, options) ->
    popover = $(tpl)
    plate = popover.find('.lolliclock-plate')
    hoursView = popover.find('.lolliclock-dial-hours')
    minutesView = popover.find('.lolliclock-dial-minutes')
    isInput = element.prop('tagName') == 'INPUT'
    input = if isInput then element else element.find('input')
    self = this
    # Mousedown or touchstart

    mousedown = (e) ->
      offset = plate.offset()
      isTouch = /^touch/.test(e.type)
      x0 = offset.left + dialRadius
      y0 = offset.top + dialRadius
      dx = (if isTouch then e.originalEvent.touches[0] else e).pageX - x0
      dy = (if isTouch then e.originalEvent.touches[0] else e).pageY - y0
      z = Math.sqrt(dx * dx + dy * dy)
      moved = false
      outsideMode = true
      # Ignore plate clicks that aren't even close
      if z < outSizeRadius + tickRadius and z > outSizeRadius - tickRadius
        outsideMode = true
      else if z > radius - tickRadius and z < radius + tickRadius and options.hour24 and self.currentView == 'hours'
        outsideMode = false
      else
        return
      e.preventDefault()
      $(document.body).addClass 'lolliclock-moving'
      # Place the canvas to top
      plate.append self.canvas
      # Clock
      self.setHand dx, dy, outsideMode
      # Mousemove on document
      $(document).off(mousemoveEvent).on mousemoveEvent, (e) ->
        `var isTouch`
        e.preventDefault()
        isTouch = /^touch/.test(e.type)
        x = (if isTouch then e.originalEvent.touches[0] else e).pageX - x0
        y = (if isTouch then e.originalEvent.touches[0] else e).pageY - y0
        if !moved and x == dx and y == dy
          # Clicking in chrome on windows will trigger a mousemove event
          return
        moved = true
        self.setHand x, y, outsideMode
        return
      # Mouseup on document
      $(document).off(mouseupEvent).on mouseupEvent, (e) ->
        `var isTouch`
        e.preventDefault()
        isTouch = /^touch/.test(e.type)
        x = (if isTouch then e.originalEvent.changedTouches[0] else e).pageX - x0
        y = (if isTouch then e.originalEvent.changedTouches[0] else e).pageY - y0
        if x == dx and y == dy
          self.setHand x, y, outsideMode
        if self.currentView == 'hours'
          self.toggleView 'minutes', duration / 2
        else if options.autoclose
          self.done()
        plate.prepend canvas
        # Reset mouse cursor
        $(document.body).removeClass 'lolliclock-moving'
        # Unbind mousemove event
        $(document).off mousemoveEvent
        $(document).off mouseupEvent
        return
      return

    @id = uniqueId('lolli')
    @element = element
    @options = options
    @isAppended = false
    @isShown = false
    @currentView = 'hours'
    @isInput = isInput
    @input = input
    @popover = popover
    @plate = plate
    @hoursView = hoursView
    @minutesView = minutesView
    @header = popover.find('.lolliclock-header')
    @spanHours = popover.find('.lolliclock-hours')
    @spanMinutes = popover.find('.lolliclock-minutes')
    @spanNewTime = popover.find('.lolliclock-time-new')
    @spanOldTime = popover.find('.lolliclock-time-old')
    @spanAmPm = popover.find('.lolliclock-am-pm')
    @amOrPm = 'PM'
    @AmPmButtons = popover.find('.lolliclock-ampm-btn')
    @amButton = popover.find('#lolliclock-btn-am')
    @pmButton = popover.find('#lolliclock-btn-pm')
    if @options.hour24
      @AmPmButtons.hide()
      @spanAmPm.hide()
    #var exportName = (this.input[0].name || this.input[0].id) + '-export';
    #this.dateTimeVal = $('<input type="hidden" id="' + exportName + '"></input>').insertAfter(input);
    # If autoclose is not setted, append a button
    if !options.autoclose
      @popover.css 'height', '380px'
      $closeButtons = $('<div class="lolliclock-buttons"></div>').appendTo(popover)
      $('<div class="lolliclock-button">Cancel</div>').click($.proxy(@hide, this)).appendTo $closeButtons
      $('<div class="lolliclock-button">OK</div>').click($.proxy(@done, this)).appendTo $closeButtons
      @closeButtons = popover.find('.lolliclock-button')
    # Show or toggle
    input.on 'focus.lolliclock click.lolliclock', $.proxy(@show, this)
    # Build ticks
    tickTpl = $('<div class="lolliclock-tick"></div>')
    i = undefined
    tick = undefined
    radian = undefined
    # Hours view
    if options.hour24
      i = 1
      while i < 13
        tick = tickTpl.clone()
        radian = i / 6 * Math.PI
        tick.css
          left: dialRadius + Math.sin(radian) * radius - tickRadius
          top: dialRadius - (Math.cos(radian) * radius) - tickRadius
        tick.html i
        hoursView.append tick
        i++
      i = 13
      while i <= 24
        tick = tickTpl.clone()
        radian = i / 6 * Math.PI
        tick.css
          left: dialRadius + Math.sin(radian) * outSizeRadius - tickRadius
          top: dialRadius - (Math.cos(radian) * outSizeRadius) - tickRadius
        if i == 24
          tick.html '00'
        else
          tick.html i
        hoursView.append tick
        i++
    else
      i = 1
      while i < 13
        tick = tickTpl.clone()
        radian = i / 6 * Math.PI
        tick.css
          left: dialRadius + Math.sin(radian) * outSizeRadius - tickRadius
          top: dialRadius - (Math.cos(radian) * outSizeRadius) - tickRadius
        tick.html i
        hoursView.append tick
        i++
    # Minutes view
    i = 0
    while i < 60
      tick = tickTpl.clone()
      radian = i / 30 * Math.PI
      tick.css
        left: dialRadius + Math.sin(radian) * outSizeRadius - tickRadius
        top: dialRadius - (Math.cos(radian) * outSizeRadius) - tickRadius
      tick.html leadingZero(i)
      minutesView.append tick
      i += 5
    #Move click to nearest tick
    plate.on mousedownEvent, mousedown
    # Draw clock SVG
    canvas = popover.find('.lolliclock-canvas')
    svg = createSvgElement('svg')
    svg.setAttribute 'class', 'lolliclock-svg'
    svg.setAttribute 'width', diameter
    svg.setAttribute 'height', diameter
    g = createSvgElement('g')
    g.setAttribute 'transform', 'translate(' + dialRadius + ',' + dialRadius + ')'
    bearing = createSvgElement('circle')
    bearing.setAttribute 'class', 'lolliclock-bearing'
    bearing.setAttribute 'cx', 0
    bearing.setAttribute 'cy', 0
    bearing.setAttribute 'r', 1.25
    hand = createSvgElement('line')
    hand.setAttribute 'x1', 0
    hand.setAttribute 'y1', 0
    bg = createSvgElement('circle')
    bg.setAttribute 'class', 'lolliclock-canvas-bg'
    bg.setAttribute 'r', tickRadius
    fg = createSvgElement('circle')
    fg.setAttribute 'class', 'lolliclock-canvas-fg'
    fg.setAttribute 'r', 3.5
    g.appendChild hand
    g.appendChild bg
    g.appendChild fg
    g.appendChild bearing
    svg.appendChild g
    canvas.append svg
    @hand = hand
    @bg = bg
    @fg = fg
    @bearing = bearing
    @g = g
    @canvas = canvas
    raiseCallback @options.init
    return

  raiseCallback = (callbackFunction) ->
    if callbackFunction and typeof callbackFunction == 'function'
      callbackFunction()
    return

  LolliClock.DEFAULTS =
    startTime: ''
    autoclose: false
    vibrate: true
    hour24: false
  # Listen touch events in touch screen device, instead of mouse events in desktop.
  touchSupported = 'ontouchstart' of window
  mousedownEvent = 'mousedown' + (if touchSupported then ' touchstart' else '')
  mousemoveEvent = 'mousemove.lolliclock' + (if touchSupported then ' touchmove.lolliclock' else '')
  mouseupEvent = 'mouseup.lolliclock' + (if touchSupported then ' touchend.lolliclock' else '')
  # Vibrate the device if supported
  vibrate = if navigator.vibravarte then 'vibrate' else if navigator.webkitVibrate then 'webkitVibrate' else null
  svgNS = 'http://www.w3.org/2000/svg'
  # Get a unique id
  idCounter = 0
  # Clock size
  dialRadius = 84
  radius = 50
  outSizeRadius = 70
  tickRadius = 12
  diameter = dialRadius * 2
  duration = 350
  # Popover template
  tpl = [
    '<div class="lolliclock-popover">'
    '<div class="lolliclock-header">'
    '<div class="lolliclock-time">'
    '<div class="lolliclock-hours lolliclock-primary-text">'
    '<div class="lolliclock-time-old"></div>'
    '<div class="lolliclock-time-new"></div>'
    '</div>'
    '<span class="lolliclock-colon">:</span>'
    '<div class="lolliclock-minutes">'
    '<div class="lolliclock-time-old"></div>'
    '<div class="lolliclock-time-new"></div>'
    '</div>'
    '</div>'
    '<span class="lolliclock-am-pm"></span>'
    '</div>'
    '<div class="popover-content">'
    '<div class="lolliclock-plate">'
    '<div class="lolliclock-canvas"></div>'
    '<div class="lolliclock-dial lolliclock-dial-hours"></div>'
    '<div class="lolliclock-dial lolliclock-dial-minutes lolliclock-dial-out"></div>'
    '</div>'
    '<div class="lolliclock-ampm-block">'
    '<div id="lolliclock-btn-am" class="lolliclock-ampm-btn">'
    '<div class="lolliclock-btn-background"></div>'
    '<div class="lolliclock-btn-text">AM</div>'
    '</div>'
    '<div style="flex: 1;"></div>'
    '<div id="lolliclock-btn-pm" class="lolliclock-ampm-btn">'
    '<div class="lolliclock-btn-background"></div>'
    '<div class="lolliclock-btn-text">PM</div>'
    '</div>'
    '</div>'
    '</div>'
    '</div>'
  ].join('')
  # Show or hide popover

  LolliClock::toggle = ->
    @[if @isShown then 'hide' else 'show']()
    return

  LolliClock::changeAmPm = (isAmOrPm) ->
    if ! !isAmOrPm and isAmOrPm == @amOrPm and @options.hour24
      return
    @amOrPm = if @amOrPm == 'AM' then 'PM' else 'AM'
    @spanAmPm.html @amOrPm
    $(@amButton[0].childNodes[0]).toggleClass 'lolliclock-active-button-background', @amOrPm == 'AM'
    $(@pmButton[0].childNodes[0]).toggleClass 'lolliclock-active-button-background', @amOrPm == 'PM'
    $(@amButton[0].childNodes[1]).toggleClass 'lolliclock-active-button-text', @amOrPm == 'AM'
    $(@pmButton[0].childNodes[1]).toggleClass 'lolliclock-active-button-text', @amOrPm == 'PM'
    return

  # Set popover position, keep it on screen no matter how it's scrolled

  LolliClock::locate = ->
    element = @element
    popover = @popover
    popoverMargin = 8
    leftOffset = element.offset().left + (element.outerWidth() - popover.width()) / 2
    maxLeft = $(window).width() - popover.width() - popoverMargin
    minLeft = popoverMargin
    maxTop = $(window).height() + $(window).scrollTop() - popoverMargin - popover.height()
    minTop = popoverMargin + $(window).scrollTop()
    topOffset = element.offset().top
    styles = {}
    styles.top = if topOffset < minTop then minTop else if topOffset > maxTop then maxTop else topOffset
    styles.left = if leftOffset < minLeft then minLeft else if leftOffset > maxLeft then maxLeft else leftOffset
    popover.css styles
    popover.show()
    return

  # Show popover

  LolliClock::show = ->
    #this.input.trigger('blur');
    #Get the time

    timeToDate = (time) ->
      parts = time.split(':')
      if parts.length == 2
        hours = +parts[0]
        minAM = parts[1].split(' ')
        if minAM.length == 2
          mins = minAM[0]
          if minAM[1] == 'PM'
            hours += 12
          return new Date(1970, 1, 1, hours, mins)
      new Date('x')

    isValidTime = (time) ->
      !isNaN(timeToDate(time).getTime())

    if @isShown
      return
    raiseCallback @options.beforeShow
    self = this
    # Initialize
    if !@isAppended
      # Append popover to body
      $(document.body).append @popover
      @isAppended = true
      # Reset position when resize
      $(window).on 'resize.lolliclock' + @id, ->
        if self.isShown
          self.locate()
        return
      # Reset position on scroll
      $(window).on 'scroll.lolliclock', ->
        if self.isShown
          self.locate()
        return
      #Add listeners
      @AmPmButtons.on 'click', (e) ->
        self.changeAmPm e.currentTarget.children[1].innerHTML
        return
      @spanMinutes.on 'click', ->
        self.toggleView 'minutes'
        return
      @spanHours.on 'click', ->
        self.toggleView 'hours'
        return
      @spanAmPm.on 'click', ->
        self.changeAmPm()
        return
    # Set position
    self.locate()
    #animate show
    @plate.addClass 'animate'
    @header.addClass 'animate'
    @popover.addClass 'animate'
    @AmPmButtons.addClass 'animate'
    @spanNewTime.addClass 'animate'
    @spanOldTime.addClass 'animate'
    !@options.autoclose and @closeButtons.addClass('animate')
    @plate.on 'webkitAnimationEnd animationend MSAnimationEnd oanimationend', ->
      self.plate.removeClass 'animate'
      self.header.removeClass 'animate'
      self.popover.removeClass 'animate'
      self.AmPmButtons.removeClass 'animate'
      self.spanNewTime.removeClass 'animate'
      self.spanOldTime.removeClass 'animate'
      !self.options.autoclose and self.closeButtons.removeClass('animate')
      self.plate.off 'webkitAnimationEnd animationend MSAnimationEnd oanimationend'
      return
    value = undefined
    inputValue = @input.prop('value')
    defaultValue = @options.startTime
    placeholderValue = @input.prop('placeholder')
    if inputValue and isValidTime(inputValue)
      value = timeToDate(inputValue)
    else if defaultValue == 'now'
      value = new Date
    else if defaultValue and isValidTime(defaultValue)
      value = timeToDate(defaultValue)
    else if placeholderValue and isValidTime(placeholderValue)
      value = timeToDate(placeholderValue)
    else
      value = new Date
    if @options.hour24
      @hours = value.getHours()
    else
      @hours = value.getHours() % 12
      @amOrPm = if value.getHours() > 11 then 'AM' else 'PM'
    @minutes = value.getMinutes()
    #purposefully wrong because we change it next line
    @changeAmPm()
    # Set time
    self.toggleView 'minutes'
    self.toggleView 'hours'
    self.isShown = true
    # Hide when clicking or tabbing on any element except the clock, input
    $(document).on 'click.lolliclock.' + @id + ' focusin.lolliclock.' + @id, (e) ->
      target = $(e.target)
      if target.closest(self.popover).length == 0 and target.closest(self.input).length == 0
        self.done()
      return
    # Hide when ESC is pressed
    $(document).on 'keyup.lolliclock.' + @id, (e) ->
      if e.keyCode == 27
        self.hide()
      return
    raiseCallback @options.afterShow
    return

  # Hide popover

  LolliClock::hide = ->
    raiseCallback @options.beforeHide
    #animate out
    self = this
    self.popover.addClass 'animate-out'
    self.plate.addClass 'animate-out'
    self.header.addClass 'animate-out'
    self.AmPmButtons.addClass 'animate-out'
    !self.options.autoclose and self.closeButtons.addClass('animate-out')
    @popover.on 'webkitAnimationEnd animationend MSAnimationEnd oanimationend', ->
      $(self.spanHours[0].childNodes[0]).html ''
      $(self.spanMinutes[0].childNodes[0]).html ''
      self.popover.removeClass 'animate-out'
      self.plate.removeClass 'animate-out'
      self.header.removeClass 'animate-out'
      self.AmPmButtons.removeClass 'animate-out'
      !self.options.autoclose and self.closeButtons.removeClass('animate-out')
      self.popover.off 'webkitAnimationEnd animationend MSAnimationEnd oanimationend'
      # Unbinding events on document
      $(document).off 'click.lolliclock.' + self.id + ' focusin.lolliclock.' + self.id
      $(document).off 'keyup.lolliclock.' + self.id
      self.popover.hide()
      raiseCallback self.options.afterHide
      return
    self.isShown = false
    return

  # Toggle to hours or minutes view

  LolliClock::toggleView = (view, delay) ->
    isHours = view == 'hours'
    nextView = if isHours then @hoursView else @minutesView
    hideView = if isHours then @minutesView else @hoursView
    @currentView = view
    @spanHours.toggleClass 'lolliclock-primary-text', isHours
    @spanMinutes.toggleClass 'lolliclock-primary-text', !isHours
    # Let's make transitions
    hideView.addClass 'lolliclock-dial-out'
    nextView.css('visibility', 'visible').removeClass 'lolliclock-dial-out'
    # Reset clock hand
    @resetClock delay
    # After transitions ended
    clearTimeout @toggleViewTimer
    @toggleViewTimer = setTimeout((->
      hideView.css 'visibility', 'hidden'
      return
    ), duration)
    #Add pointer mouse cursor to show you can click between ticks
    if isHours
      @plate.off mousemoveEvent
    else
      self = this
      @plate.on mousemoveEvent, (e) ->
        offset = self.plate.offset()
        x0 = offset.left + dialRadius
        y0 = offset.top + dialRadius
        dx = e.pageX - x0
        dy = e.pageY - y0
        z = Math.sqrt(dx * dx + dy * dy)
        if z > outSizeRadius - tickRadius and z < outSizeRadius + tickRadius
          $(document.body).addClass 'lolliclock-clickable'
        else
          $(document.body).removeClass 'lolliclock-clickable'
        return
    return

  # Reset clock hand

  LolliClock::resetClock = (delay) ->
    view = @currentView
    outSizeMode = true
    value = @[view]
    isHours = view == 'hours'
    if isHours
      unit = Math.PI / 6
      if value != 0 and value <= 12 and @options.hour24
        outSizeMode = false
    else
      unit = Math.PI / 30
    radian = value * unit
    x = Math.sin(radian) * radius
    y = -Math.cos(radian) * radius
    self = this
    if delay
      self.canvas.addClass 'lolliclock-canvas-out'
      setTimeout (->
        self.canvas.removeClass 'lolliclock-canvas-out'
        self.setHand x, y, outSizeMode
        return
      ), delay
    else
      @setHand x, y, outSizeMode
    return

  # Set clock hand to (x, y)

  LolliClock::setHand = (x, y, outSizeMode) ->
    #Keep radians postive from 1 to 2pi
    radian = Math.atan2(-x, y) + Math.PI
    isHours = @currentView == 'hours'
    unit = Math.PI / (if isHours then 6 else 30)
    value = undefined
    # Get the round value

    cleanupAnimation = ($obj) ->
      $obj.on 'webkitAnimationEnd animationend MSAnimationEnd oanimationend', ->
        $oldTime.html value
        #only needed for -up transitions
        $oldTime.removeClass 'old-down old-up'
        $newTime.removeClass 'new-down new-up'
        $oldTime.off 'webkitAnimationEnd animationend MSAnimationEnd oanimationend'
        return
      return

    if outSizeMode and @options.hour24 and isHours
      value = Math.round(radian / unit)
      if value == 12 or value == 0
        value = 0
      else
        value += 12
    else
      value = Math.round(radian / unit)
    # Get the round radian
    radian = value * unit
    # Correct the hours or minutes
    if isHours
      if value == 0 and !(@options.hour24 and outSizeMode)
        value = 12
      @fg.style.visibility = 'hidden'
    else
      isOnNum = value % 5 == 0
      if isOnNum
        @fg.style.visibility = 'hidden'
      else
        @fg.style.visibility = 'visible'
      if value == 60
        value = 0
    # Once hours or minutes changed, vibrate the device
    if @[@currentView] != value
      if vibrate and @options.vibrate
        # Do not vibrate too frequently
        if !@vibrateTimer
          navigator[vibrate] 10
          @vibrateTimer = setTimeout($.proxy((->
            @vibrateTimer = null
            return
          ), this), 100)
    #TODO: Keep tens digit static for changing hours
    @[@currentView] = value
    $oldTime = undefined
    $newTime = undefined
    if isHours
      $oldTime = $(@spanHours[0].childNodes[0])
      $newTime = $(@spanHours[0].childNodes[1])
      if @options.hour24
        value = leadingZero(value)
    else
      $oldTime = $(@spanMinutes[0].childNodes[0])
      $newTime = $(@spanMinutes[0].childNodes[1])
      value = leadingZero(value)
    cleanupAnimation $oldTime
    if value < +$oldTime.html()
      $newTime.html $oldTime.html()
      $oldTime.html value
      $newTime.addClass 'new-down'
      $oldTime.addClass 'old-down'
    else if value > +$oldTime.html() or !$oldTime.html()
      $newTime.html value
      $oldTime.addClass 'old-up'
      $newTime.addClass 'new-up'
    @g.insertBefore @hand, @bearing
    @g.insertBefore @bg, @fg
    @bg.setAttribute 'class', 'lolliclock-canvas-bg'
    # Set clock hand and others' position
    r = radius
    if outSizeMode
      r = outSizeRadius
    cx = Math.sin(radian) * r
    cy = -Math.cos(radian) * r
    @hand.setAttribute 'x2', Math.sin(radian) * (r - tickRadius)
    @hand.setAttribute 'y2', -Math.cos(radian) * (r - tickRadius)
    @bg.setAttribute 'cx', cx
    @bg.setAttribute 'cy', cy
    @fg.setAttribute 'cx', cx
    @fg.setAttribute 'cy', cy
    return

  # Hours and minutes are selected

  LolliClock::done = ->
    raiseCallback @options.beforeDone
    last = @input.prop('value')
    value = ''
    if !@options.hour24
      value = @hours + ':' + leadingZero(@minutes) + ' ' + @amOrPm
    else
      value = leadingZero(@hours) + ':' + leadingZero(@minutes)
    if value != last
      @input.prop 'value', value
      @input.trigger 'input'
      @input.trigger 'change'
    @hide()
    return

  # Remove lolliclock from input

  LolliClock::remove = ->
    @element.removeData 'lolliclock'
    @input.off 'focus.lolliclock click.lolliclock'
    if @isShown
      @hide()
    if @isAppended
      $(window).off 'resize.lolliclock' + @id
      $(window).off 'scroll.lolliclock' + @id
      @popover.remove()
    return

  # Extends $.fn.lolliclock

  $.fn.lolliclock = (option) ->
    args = Array::slice.call(arguments, 1)
    @each ->
      $this = $(this)
      data = $this.data('lolliclock')
      if !data
        options = $.extend({}, LolliClock.DEFAULTS, $this.data(), typeof option == 'object' and option)
        $this.data 'lolliclock', new LolliClock($this, options)
      else
        # Manual operatsions. show, hide, remove, e.g.
        if typeof data[option] == 'function'
          data[option].apply data, args
      return

  return

# ---
# generated by js2coffee 2.1.0