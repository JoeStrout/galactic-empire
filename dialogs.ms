// This module manages various pop-up dialogs drawn over the main UI.

import "importUtil"
ensureImport "bmfFonts"
ensureImport "textUtil"

if not globals.hasIndex("bigFont") then
	globals.bigFont = bmfFonts.Font.load("/sys/fonts/minimicro-pro-16.bmf")
end if

display(1).mode = displayMode.text
globals.text = display(1)
text.clear

display(3).mode = displayMode.pixel
disp = display(3)
disp.clear

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

// Class representing the battle dialog.
BattleDialog = {}
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
	width = 400
	height = 150
	midx = 480
	left = midx - width/2
	bottom = 328 - height/2
	disp.clear surroundTint
	disp.fillRect left, bottom, width, height, backColor
	disp.drawRect left, bottom, width, height, borderColor
	disp.fillRect left, bottom+height, width, 20, borderColor
	
	oldGfx = gfx
	globals.gfx = disp
	
	bigFont.printCentered "Battle for " + self.sides[1], 
	    midx, bottom+height+4, 1, titleColor
	
	y = bottom + height - 24 - 32

	x0 = left + width * 0.45
	x1 = left + width * 0.75
	bigFont.printCentered self.sides[0], x0, y, 1, textColor
	w = bigFont.width(self.sides[0])
	disp.line x0 - w/2 - 2, y-3, x0 + w/2 + 2, y-3, textColor
	
	bigFont.printCentered self.sides[1], x1, y, 1, textColor
	w = bigFont.width(self.sides[1])
	disp.line x1 - w/2 - 2, y-3, x1 + w/2 + 2, y-3, textColor
	y -= 24
	
	bigFont.print "Ships Left:", left + 8, y, 1, textColor
	
	text.color = color.yellow
	row = textUtil.textRow(y + 4)

	if self.spaceForces[1] > 0 then
		bigFont.printCentered "Space Battle", midx, bottom + height - 24, 1, textColor
	
		textUtil.printAt textUtil.textCol(x0)-2, row, cpad(self.spaceForces[0])
		textUtil.printAt textUtil.textCol(x1)-2, row, cpad(self.spaceForces[1])
		wait
	
		while self.spaceForces[0] > 0 and self.spaceForces[1] > 0
			if rnd < 0.6 then
				self.spaceForces[1] -= 1
			else
				self.spaceForces[0] -= 1
			end if
			textUtil.printAt textUtil.textCol(x0)-2, row, cpad(self.spaceForces[0])
			textUtil.printAt textUtil.textCol(x1)-2, row, cpad(self.spaceForces[1])
			yield
		end while
	else
		bigFont.printCentered "(No Space Defense)", midx, bottom + height - 24, 1, textColor	
	end if

	if self.spaceForces[0] > 0 and self.groundForces[1] > 0 then
		wait
		disp.fillRect left+4, bottom + height - 27, width-8, 26, backColor
		bigFont.printCentered "Land Battle", midx, bottom + height - 24, 1, textColor
	
		textUtil.printAt textUtil.textCol(x0)-2, row, cpad(self.groundForces[0])
		textUtil.printAt textUtil.textCol(x1)-2, row, cpad(self.groundForces[1])
		wait
	
		while self.groundForces[0] > 0 and self.groundForces[1] > 0
			if rnd < 0.6 then
				self.groundForces[1] -= 1
			else
				self.groundForces[0] -= 1
			end if
			textUtil.printAt textUtil.textCol(x0)-2, row, cpad(self.groundForces[0])
			textUtil.printAt textUtil.textCol(x1)-2, row, cpad(self.groundForces[1])
			yield
		end while
	end if
	
	y -= 32	
	if self.winner == 0 then
		bigFont.printCentered "Planet Secured!", midx, y, 1, "#FF6666"
	else if self.winner == 1 then
		bigFont.printCentered "Battle Lost!", midx, y, 1, "#FF6666"
	end if
	wait 1.5
	
	globals.gfx = oldGfx
	clear
end function

if locals == globals then
	bd = new BattleDialog
	bd.spaceForces = [200, 124]
	bd.groundForces = [180, 120]
	bd.run
	key.get
	disp.clear
	text.clear
	text.color = color.orange
end if
