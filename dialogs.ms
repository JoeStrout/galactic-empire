// This module manages various pop-up dialogs drawn over the main UI.

import "importUtil"
ensureImport "mathUtil"
ensureImport "bmfFonts"
ensureImport "textUtil"
ensureImport "gameRules"
ensureImport "buttons"

if not globals.hasIndex("bigFont") then
	globals.bigFont = bmfFonts.Font.load("/sys/fonts/minimicro-pro-16.bmf")
end if

display(1).mode = displayMode.text
globals.text = display(1)
text.clear

display(3).mode = displayMode.pixel
disp = display(3)
disp.clear

display(2).mode = displayMode.sprite	// (for dialog buttons)
display(2).clear

backColor = "#000044"
borderColor = "#8800FF"
titleColor = "#FFFF00"
textColor = "#8888FF"
surroundTint = "#00000044"

clear = function
	disp.clear
	text.clear
end function

rpad = function(value, spaces=5)
	value = str(value)
	return " " * (spaces - value.len) + value
end function

cpad = function(value, spaces=5)
	value = str(value)
	extra = spaces - value.len
	extraLeft = ceil(extra/2)
	return " " * extraLeft + value + " " * (extra - extraLeft)
end function

// Wrap a long text into multiple lines, breaking on words,
// as needed to fit within the given width.  Return a list of strings.
wrapLines = function(s="", width=550, font=null)
	if not s then return [""]
	if not font then font = globals.font
	result = []
	while true
		lenToFit = font.lenToFit(s, width)
		if lenToFit+1 >= s.len then
			result.push s
			break
		end if
		while lenToFit > 1
			c = s[lenToFit+1]
			if c <= " " then break
			lenToFit = lenToFit - 1
		end while
		result.push s[:lenToFit+1]
		s = s[lenToFit+1:].trimLeft
	end while
	return result
end function

// Extend the Font class to draw wrapped text, and return the next Y.
bmfFonts.Font.printWrapped = function(s="", x, y, wrapWidth, tint="#FFFFFF")
	if s isa list then lines = s else lines = wrapLines(s, wrapWidth, self)
	for line in lines
		self.print line, x, y, 1, tint
		y = y - self.lineHeight
	end for
	return y
end function

printHeader = function(s, x, y, color)
	w = bigFont.width(s)
	left = round(x - w/2)
	y -= 10
	bigFont.print s, left, y, 1, color
	gfx.line left, y-2, left+w, y-2, color
end function

printHeaderRight = function(s, x, y, color)
	w = bigFont.width(s)
	left = round(x - w)
	y -= 10
	bigFont.print s, left, y, 1, color
	gfx.line left, y-2, left+w, y-2, color
end function


// Simple BMF-based numeric input field.
InputField = {}
InputField.bounds = null		// a Bounds instance representing the field bounds
InputField.text = ""
InputField.backColor = "#111111"
InputField.borderColor = "#888888"
InputField.textColor = "#AAAAFF"
InputField.focusedTextColor = "#FFFFAA"
InputField.selColor = "#FFFFAA"
InputField.selTextColor = "#000044"
InputField.textSelected = false
InputField.gfx = disp
InputField.font = bigFont
InputField.onTextChange = null
// Class (not instance) properties:
InputField.instances = []
InputField.focusedField = null	// (class property, points to field with focus)

InputField.make = function(left, bottom, width, height, text="0")
	fld = new InputField
	fld.bounds = new Bounds
	fld.bounds.x = left + width/2
	fld.bounds.y = bottom + height/2
	fld.bounds.width = width
	fld.bounds.height = height
	fld.text = text
	InputField.instances.push fld
	return fld
end function

InputField.close = function
	idx = InputField.instances.indexOf(self)
	if idx != null then InputField.instances.remove idx
	self.gfx.fillPoly mathUtil.offsetPoly(self.bounds.corners, -1), color.clear
end function

InputField.closeAll = function
	for i in range(InputField.instances.len-1, 0, -1)
		InputField.instances[i].close
	end for
end function

InputField.handleClickAll = function
	for fld in InputField.instances
		if fld.bounds.contains(mouse) then
			fld.select
			while mouse.button; yield; end while
		end if
	end for
end function

InputField.handleKeyAll = function(keyChar)
	fld = InputField.focusedField
	keyCode = keyChar.code
	if fld == null and keyCode != 9 and keyCode != 25 then return
	if keyCode == 9 or keyCode == 25 then		// tab or shift-tab
		if not InputField.instances then return
		reverse = key.pressed("left shift") or key.pressed("right shift") or keyCode == 25		
		idx = InputField.instances.indexOf(fld)
		if idx == null then
			idx = 0 - reverse
		else
			idx += 1 - 2*reverse
			if idx >= InputField.instances.len then idx = 0
		end if
		InputField.instances[idx].select
	else if keyChar == char(8) then	// backspace
		if fld.textSelected then fld.text = ""
		fld.text = fld.text[:-1]
		if fld.text == "" then fld.text = "0"
		fld.textSelected = false
		fld.draw
		fld.onTextChange
	else if keyChar >= "0" and keyChar <= "9" then
		if fld.text == "0" or fld.textSelected then fld.text = ""
		fld.text += keyChar
		fld.textSelected = false
		fld.draw
		fld.onTextChange
	else
		//print "Unknown char: " + keyChar.code
	end if
end function

InputField.deselect = function
	if InputField.focusedField == self then InputField.focusedField = null
	self.textSelected = false
	self.draw
end function

InputField.select = function(selectIt=true)
	if not selectIt then return self.deselect

	if InputField.focusedField then InputField.focusedField.deselect
	InputField.focusedField = self
	self.textSelected = true
	self.draw
end function

InputField.draw = function
	focused = (InputField.focusedField == self)
	c = self.bounds.corners
	self.gfx.fillPoly c, self.backColor
	self.gfx.drawPoly c, self.borderColor
	x = c[2][0] - 8 - self.font.width(self.text)
	y = c[0][1] + 8
	if self.textSelected then
		self.gfx.fillPoly mathUtil.offsetPoly(c, 3), self.selColor
		self.font.print self.text, x, y, 1, self.selTextColor
	else
		if focused then clr = self.focusedTextColor else clr = self.textColor
		self.font.print self.text, x, y, 1, clr
	end if
end function

// Generic dialog base class.  Handles drawing the box frame, background
// and title, plus maybe a few other utilities.
Dialog = {}
Dialog.midX = 480
Dialog.midY = 320
Dialog.width = 400
Dialog.height = 200
Dialog.left = function; return self.midX - self.width/2; end function
Dialog.right = function; return self.midX + self.width/2; end function
Dialog.bottom = function; return self.midY - self.height/2; end function
Dialog.top = function; return self.midY + self.height/2; end function
Dialog.title = ""
Dialog.draw = function
	disp.clear surroundTint
	disp.fillRect self.left, self.bottom, self.width, self.height, backColor
	disp.drawRect self.left, self.bottom, self.width, self.height, borderColor
	disp.fillRect self.left, self.top, self.width, 20, borderColor
	oldGfx = gfx; globals.gfx = disp	
	bigFont.printCentered self.title, self.midX, self.top+4, 1, titleColor
	self.drawContent
	globals.gfx = oldGfx
end function
Dialog.drawContent = null
Dialog.wait = function(delay=1)
	// Wait... but let the user dismiss by pressing Esc, Space, Enter, or Return.
	endTime = time + delay
	mouseWasDown = mouse.button
	while time < endTime
		yield
		if key.available then
			k = key.get.code
			if [3, 10, 13, 27, 32].indexOf(k) != null then return
		end if
		if mouse.button and not mouseWasDown then return
		mouseWasDown = mouse.button
	end while
end function

MsgDialog = new Dialog
MsgDialog.width = 300
MsgDialog.height = 120
MsgDialog.message = "Your message here."
MsgDialog.drawContent = function
	wrapWidth = self.width - 40
	lines = wrapLines(self.message, wrapWidth, bigFont)
	y = self.midY + bigFont.lineHeight * (lines.len/2 + 0)
	bigFont.printWrapped lines, self.left + 20, y, wrapWidth, textColor
end function
MsgDialog.show = function(message, title="")
	dlog = new MsgDialog
	dlog.title = title
	dlog.message = message
	dlog.draw
	self.wait 4
	clear
end function

// Class representing the battle dialog.
BattleDialog = new Dialog
BattleDialog.sides = ["Empire", "Defender"]
BattleDialog.spaceForces = [0, 0]
BattleDialog.groundForces = [0, 0]
BattleDialog.winner = function
	if self.groundForces[0] or self.groundForces[1] then
		// if any ground forces are left, but one side has none,
		// then the side with some left wins.
		if self.groundForces[0] == 0 then return 1
		if self.groundForces[1] == 0 then return 0
		// but if both sides have some left, then there is no winner
		return null
	end if
	// if there are no ground forces, but we have space forces,
	// then let that determine it
	if self.spaceForces[0] or self.spaceForces[1] then
		if self.spaceForces[0] == 0 then return 1
		if self.spaceForces[1] == 0 then return 0
	end if
	return null
end function
// Run the dialog until somebody wins, or the user cancels.
BattleDialog.run = function
	self.width = 400
	self.height = 150
	self.midY = 328
	self.title = "Battle for " + self.sides[1]
	super.draw
	oldGfx = gfx
	globals.gfx = disp
	y = self.top - 24 - 32

	x0 = self.left + self.width * 0.45
	x1 = self.left + self.width * 0.75
	bigFont.printCentered self.sides[0], x0, y, 1, textColor
	w = bigFont.width(self.sides[0])
	disp.line x0 - w/2 - 2, y-3, x0 + w/2 + 2, y-3, textColor
	
	bigFont.printCentered self.sides[1], x1, y, 1, textColor
	w = bigFont.width(self.sides[1])
	disp.line x1 - w/2 - 2, y-3, x1 + w/2 + 2, y-3, textColor
	y -= 24
	
	bigFont.print "Ships Left:", self.left + 8, y, 1, textColor
	
	text.color = color.yellow
	row = textUtil.textRow(y + 4)

	planets = [globals.planets[0], fleet.planet]
	if self.spaceForces[1] > 0 then
		bigFont.printCentered "Space Battle", self.midX, self.top - 24, 1, textColor
	
		textUtil.printAt textUtil.textCol(x0)-2, row, cpad(self.spaceForces[0])
		textUtil.printAt textUtil.textCol(x1)-2, row, cpad(self.spaceForces[1])
		self.wait
	
		while self.spaceForces[0] > 0 and self.spaceForces[1] > 0
			gameRules.doSpaceCombat planets, self.spaceForces
			textUtil.printAt textUtil.textCol(x0)-2, row, cpad(self.spaceForces[0])
			textUtil.printAt textUtil.textCol(x1)-2, row, cpad(self.spaceForces[1])
			yield
		end while
	else
		bigFont.printCentered "(No Space Defense)", self.midX, self.top - 24, 1, textColor	
	end if

	if self.spaceForces[0] > 0 and self.groundForces[1] > 0 then
		self.wait
		disp.fillRect self.left+4, self.top - 27, self.width-8, 26, backColor
		bigFont.printCentered "Land Battle", self.midX, self.top - 24, 1, textColor
	
		textUtil.printAt textUtil.textCol(x0)-2, row, cpad(self.groundForces[0])
		textUtil.printAt textUtil.textCol(x1)-2, row, cpad(self.groundForces[1])
		self.wait
	
		while self.groundForces[0] > 0 and self.groundForces[1] > 0
			gameRules.doLandCombat planets, self.groundForces
			textUtil.printAt textUtil.textCol(x0)-2, row, cpad(self.groundForces[0])
			textUtil.printAt textUtil.textCol(x1)-2, row, cpad(self.groundForces[1])
			yield
		end while
	end if
	
	y -= 32	
	if self.winner == 0 then
		bigFont.printCentered "Planet Secured!", self.midX, y, 1, "#FF6666"
	else if self.winner == 1 then
		bigFont.printCentered "Battle Lost!", self.midX, y, 1, "#FF6666"
	end if
	self.wait 1.5
	
	globals.gfx = oldGfx
	clear
	disp.clear
	text.clear
	text.color = color.orange
end function

// Build dialog: select how many ships you want to build, and build 'em.
BuildDialog = new Dialog
BuildDialog.shipTypes = ["Fighters", "Transports", "Spy Satellites", "Supply Ships", "Fuel Ships"]
BuildDialog.partCosts = [12, 6, 100, 200, 300]
BuildDialog.creditCosts = [18, 5, 115, 269, 451]	// ToDo: vary by planet
BuildDialog.partColor = "#AAAAAA"
BuildDialog.creditColor = "#88CC88"
BuildDialog.done = false
BuildDialog.planet = null
BuildDialog.totalQty = 0

BuildDialog.availableParts = function
	if self.planet == null then return 0
	return floor(self.planet.shipParts.amount)
end function

BuildDialog.setup = function
	self.width = 632
	self.midX = self.width/2 + 10
	self.height = 400
	self.title = "Build Ships"
	super.draw
	x0 = self.left + 168
	dx = 88
	y1 = self.top - 32	// "Unit Cost" and "Total Cost"
	y2 = self.top - 60	// "Parts", "Credits"
	printHeader "Unit Cost", x0 + dx*2+20, y1, textColor
	printHeader "Total Cost", x0 + dx*4+20, y1, textColor
	printHeaderRight "Parts", x0 + dx*2, y2, self.partColor
	printHeaderRight "Credits", x0 + dx*3, y2, self.creditColor
	printHeaderRight "Parts", x0 + dx*4, y2, self.partColor
	printHeaderRight "Credits", x0 + dx*5, y2, self.creditColor
	
	self.qtyFields = []
	y = self.top - 100
	for i in self.shipTypes.indexes
		type = self.shipTypes[i]
		bigFont.printRight type, x0 - 8, y, 1, textColor
		fld = InputField.make(x0, y-8, 80, 28)
		dialog = self
		fld.onTextChange = function; dialog.updateTotals; end function
		fld.draw
		self.qtyFields.push fld		
		bigFont.printRight self.partCosts[i], x0 + dx*2, y, 1, self.partColor
		bigFont.printRight self.creditCosts[i], x0 + dx*3, y, 1, self.creditColor
		bigFont.printRight self.partCosts[i]*0, x0 + dx*4, y, 1, self.partColor
		bigFont.printRight self.creditCosts[i]*0, x0 + dx*5, y, 1, self.creditColor		
		y -= 40
	end for
	self.totalY = y
	bigFont.printRight "Grand Total:", x0 + dx*3, self.totalY, 1, textColor
	bigFont.printRight 0, x0 + dx*4, self.totalY, 1, self.partColor
	bigFont.printRight 0, x0 + dx*5, self.totalY, 1, self.creditColor		
	gfx.line x0 + dx*3+20, self.totalY+24, x0 + dx*4, self.totalY+24, self.partColor
	gfx.line x0 + dx*4+20, self.totalY+24, x0 + dx*5, self.totalY+24, self.creditColor
	y = self.totalY - 30
	s = "Available"
	if self.planet != null then s += " at " + self.planet.name
	bigFont.printRight s + ":", x0 + dx*3, y, 1, textColor
	bigFont.printRight self.availableParts, x0 + dx*4, y, 1, self.partColor
	bigFont.printRight empire.credits, x0 + dx*5, y, 1, self.creditColor		
	
	self.done = false
	self.okButton = buttons.addButton(self.midX + 20, self.bottom + 20, 100, "OK")
	self.okButton.action = function; dialog.apply; end function
	self.cancelButton = buttons.addButton(self.midX - 20 - 100, self.bottom + 20, 100, "Cancel")
	self.cancelButton.action = function; dialog.done = true; end function
end function

BuildDialog.updateTotals = function
	y = self.top - 100
	x0 = self.left + 168
	dx = 88
	totalParts = 0
	totalCredits = 0
	for i in self.qtyFields.indexes
		qty = self.qtyFields[i].text.val
		gfx.fillRect x0 + dx*3+10, y-6, dx*2, 24, backColor
		bigFont.printRight self.partCosts[i]*qty, x0 + dx*4, y, 1, self.partColor
		bigFont.printRight self.creditCosts[i]*qty, x0 + dx*5, y, 1, self.creditColor
		totalParts += self.partCosts[i]*qty
		totalCredits += self.creditCosts[i]*qty
		y -= 40
	end for
	self.totalY = y
	gfx.fillRect x0 + dx*3+10, self.totalY-6, dx*2, 24, backColor
	bigFont.printRight totalParts, x0 + dx*4, self.totalY, 1, self.partColor
	bigFont.printRight totalCredits, x0 + dx*5, self.totalY, 1, self.creditColor
	self.okButton.enable totalParts <= self.availableParts and totalCredits <= empire.credits		
end function

BuildDialog.autoMax = function
	// Fill in the maximum we can afford for the current ship type.
	idx = self.qtyFields.indexOf(InputField.focusedField)
	if idx < 0 then return
	// First, calculate total cost of everything else
	totalParts = 0; totalCredits = 0
	for i in self.qtyFields.indexes
		if i == idx then continue
		qty = self.qtyFields[i].text.val
		totalParts += self.partCosts[i]*qty
		totalCredits += self.creditCosts[i]*qty
	end for
	// Then, see how much we can afford of this one
	availParts = self.availableParts - totalParts
	availCreds = empire.credits - totalCredits
	if availParts <= 0 or availCreds <= 0 then
		qty = 0
	else
		qty = floor(mathUtil.min(availParts/self.partCosts[idx], availCreds/self.creditCosts[idx]))
	end if
	self.qtyFields[idx].text = str(qty)
	self.qtyFields[idx].draw
	self.updateTotals
end function

BuildDialog.apply = function
	totalParts = 0; totalCredits = 0; self.totalQty = 0
	for i in self.qtyFields.indexes
		qty = self.qtyFields[i].text.val
		if i == 0 then fleet.fighters += qty
		if i == 1 then fleet.emptyTransports += qty
		if i == 2 then fleet.satellites += qty
		if i == 3 then fleet.supplyShips += qty
		if i == 4 then fleet.fuelShips += qty
		self.totalQty += qty
		totalParts += self.partCosts[i]*qty
		totalCredits += self.creditCosts[i]*qty
	end for
	self.planet.shipParts.amount -= totalParts
	empire.credits -= totalCredits
	self.done = true
end function

BuildDialog.run = function
	oldGfx = gfx; globals.gfx = disp
	oldSpriteDisp = events.spriteDisplay; events.spriteDisplay = display(2)

	self.setup
	
	if self.qtyFields[0] == self.qtyFields[2] then exit
	
	self.updateTotals
	
	events.eventLoop.mouseWasDown = false
	events.eventLoop.running = true
	
	while not self.done
		yield
		if mouse.button then InputField.handleClickAll
		if key.available then
			k = key.get
			if k == char(27) then break
			if (k == char(10) or k == char(3) or k == char(13)) and
				self.okButton.isEnabled then self.apply
			if k == " " or k == "*" or k == "?" or k == "/" then self.autoMax
			InputField.handleKeyAll k
		end if		
		events.eventLoop.update
	end while
	
	disp.clear
	InputField.closeAll
	events.spriteDisplay.clear
	globals.gfx = oldGfx
	events.spriteDisplay = oldSpriteDisp
end function

if locals == globals then
	if false then
		bd = new BattleDialog
		bd.spaceForces = [200, 124]
		bd.groundForces = [180, 120]
		bd.run
	end if
	if false then
		MsgDialog.show "This is a test of the MsgDialog.show method.", "Testy McTester"
	end if
	if false then
		gfx.clear
		fld = InputField.make(400, 300, 80, 28, "111")
		fld.draw
		fld2 = InputField.make(400, 260, 80, 28, "222")
		fld2.draw
		fld3 = InputField.make(400, 220, 80, 28, "333")
		fld3.draw
		while true
			if mouse.button then
				InputField.handleClickAll
				while mouse.button; yield; end while
			end if
			if key.available then
				k = key.get
				if k == char(27) then break
				InputField.handleKeyAll k
			end if
		end while
		InputField.closeAll
	end if
	if true then
		bd = new BuildDialog
		bd.run
	end if
end if
