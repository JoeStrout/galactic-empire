// This module handles all the buttons in the main UI.

import "importUtil"
ensureImport "events"
ensureImport "resources"

buttonColor = "#DA00FF"

scratchDisp = new PixelDisplay

buttons = []

buttonImage = function(width=48, icon=null, roundLeft=true, roundRight=true)
	src = resources.pics.button
	h = src.height
	scratchDisp.clear color.black, width, h
	if roundLeft then
		scratchDisp.drawImage src, 0, 0, 8, h, 0, 0, 8, h, buttonColor
	else
		scratchDisp.drawImage src, 0, 0, 8, h, 8, 0, 8, h, buttonColor
	end if
	scratchDisp.drawImage src, 8, 0, width-16, h, 8, 0, src.width-16, h, buttonColor
	if roundRight then
		scratchDisp.drawImage src, width-8, 0, 8, h, src.width-8, 0, 8, h, buttonColor
	else
		scratchDisp.drawImage src, width-8, 0, 8, h, src.width-16, 0, 8, h, buttonColor
	end if
	if icon then
		scratchDisp.drawImage icon, width/2 - icon.width/2, h/2 - icon.height/2
	end if
	return scratchDisp.getImage(0, 0, width, h)
end function

clearAll = function
	for btn in buttons
		btn.stop
	end for
	outer.buttons = []
end function

Button = new events.EventSprite
Button.color = "#F0F0F0"
Button.disabledColor = "#E0E0E0AA"
Button.action = null
Button.highlightColor = color.white
Button.pressedColor = "#AAAAAA"

Button.state = "NORMAL"

Button.onMouseOver = function; self.enterState "HOVER"; end function

hoveredButton = null

Button.disable = function
	self.enterState "DISABLED"
end function

Button.enable = function(enableIt = true)
	if not enableIt then return self.disable
	if self.contains(mouse) then
		self.enterState "HOVER"
	else
		self.enterState "NORMAL"
	end if
end function

Button.onEnterState = function(newState)
	if newState == "HOVER" then
		self.tint = self.highlightColor
		if hoveredButton and hoveredButton != self then
			hoveredButton.enterState "NORMAL"
		end if
		outer.hoveredButton = self
		self.ignoreClicks = false
	else if newState == "NORMAL" then
		self.tint = self.color
		self.ignoreClicks = false
	else if newState == "DISABLED" then
		self.tint = self.disabledColor
		self.ignoreClicks = true
	end if
end function

Button.onClick = function
	if self.state == "DISABLED" then return
	pressed = true
	self.tint = self.pressedColor
	while mouse.button
		inBounds = self.contains(mouse)
		if pressed and not inBounds then
			self.tint = self.color
			pressed = false
		else if inBounds and not pressed then
			self.tint = self.pressedColor
			pressed = true
		end if
		yield
	end while
	if pressed then
		self.action
		self.tint = self.highlightColor
	end if
end function

Button.update = function
	// In Mini Micro 1.2, the events module does not support an onMouseExit
	// event.  So we just check for mouse-exit here in update instead.
	if self.state == "HOVER" and not self.contains(mouse) then
		self.enterState "NORMAL"
	end if
end function

addButton = function(left, bottom, width, icon, name, roundLeft=true, roundRight=true)
	btn = new Button
	btn.image = buttonImage(width, icon, roundLeft, roundRight)
	btn.name = name
	btn.x = left + width/2
	btn.y = bottom + btn.image.height/2
	btn.tint = btn.color
	
	// Note: due to a flaw in eventLoop.update (in Mini Micro 1.2 and older),
	// onMouseOver does not fire if it is inherited from a superclass.  We
	// work around that thusly:
	btn.onMouseOver = @Button.onMouseOver
	
	btn.start
	buttons.push btn
	return btn
end function

runTest = function
	clearAll
	x = 400
	for i in range(0, 3)
		w = 40 + 4 * (i==0 or i==3)
		b = addButton(x, 300, w, resources.buttonIcons[i], resources.buttonNames[i],
				 i==0, i==3)
		b.action = function; print "Clicked " + self.name; end function
		x += w + 1
	end for
	buttons[2].disable
	
	events.eventLoop.onKey["escape"] = function; events.eventLoop.running = false; end function
	events.eventLoop.run
	clearAll
end function

if locals == globals then runTest