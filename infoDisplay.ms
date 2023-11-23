// This file draws and manages the two information displays:
// Fleet Information and Planet Information.

import "importUtil"
ensureImport "mathUtil"
ensureImport "bmfFonts"
ensureImport "fleet"
ensureImport "empire"
ensureImport "resources"
ensureImport "buttons"
ensureImport "planetView"

g = gfx
numToStr = @mathUtil.numToStr

if not globals.hasIndex("bigFont") then
	globals.bigFont = bmfFonts.Font.load("/sys/fonts/minimicro-pro-16.bmf")
end if
if not globals.hasIndex("font") then
	font = bmfFonts.Font.load("/sys/fonts/minimicro-pro-12.bmf")
end if

headerColor = "#37C824"
labelColor = "#51A1FB"
infoColor = "#FFFF44"
invalidColor = "#FF0000"
buttonColor = "#DA00FF"
disabledColor = "#B9B9B9"

statusNames = ["Independent", "Occupied", "Empire"]
techNames = ["N/A", "Primitive", "Limited", "Advanced", "Superior"]

drawTitledBox = function(left, top, width, height, title)
	bottom = top - height
	g.fillRect left, bottom, width, height, color.black
	g.drawRect left, bottom, width, height, "#888888"
	bigFont.printCentered title, left+width/2, top-18, 1, "#AAAAAA"
	g.line left, top-24, left+width, top-24, "#888888"
end function

drawHeader = function(left, top, width, header)
//	g.line left, top, left+width, top, color.gray
	headerWidth = font.width(header)
	midx = left + width/2
	right = left + width
	x1 = floor(midx - headerWidth/2 - 3)
	x2 = x1 + headerWidth + 6
	for y in [top-4, top-6, top-8]
		g.line left, y, x1, y, headerColor
		g.line x2, y, right, y, headerColor
	end for
	font.print header, midx - headerWidth/2, top - 10, 1, headerColor
end function

drawLabeledField = function(left, top, width, label, value, valid=true)
//	g.line left, top, left+width, top, color.gray
	y = top - 10
	font.print label + ":", left, y, 1, labelColor
	font.printRight value, left+width, y, 1, infoColor * valid + invalidColor * (not valid)
end function

printUnderlined = function(s, x, y)
	w = font.width(s)
	y -= 10
	font.print s, x, y, 1, labelColor
	g.line x, y-2, x+w, y-2, labelColor
end function

printUnderlinedCenter = function(s, x, y)
	w = font.width(s)
	left = round(x - w/2)
	y -= 10
	font.print s, left, y, 1, labelColor
	g.line left, y-2, left+w, y-2, labelColor
end function

printUnderlinedRight = function(s, x, y)
	w = font.width(s)
	left = round(x - w)
	y -= 10
	font.print s, left, y, 1, labelColor
	g.line left, y-2, left+w, y-2, labelColor
end function

drawEmpireInfo = function
	top = 640
	width = 400
	drawTitledBox 960-width, top, width, 180, "Empire Status"
	leftColLeft = 960-width + 4
	rightColRight = 960 - 4
	infoWidth = rightColRight - leftColLeft
	colWidth = floor(width/2 - 12)
	rightColLeft = rightColRight - colWidth
	lineHeight = 16
	y = top - 28
	
	drawLabeledField leftColLeft, y, colWidth, "Star Date", numToStr(empire.year, 2)
	drawLabeledField rightColLeft, y, colWidth, "Credits", empire.credits
	y -= lineHeight

	drawHeader leftColLeft, y, infoWidth, "Planet Status Summary"
	y -= lineHeight
	drawLabeledField leftColLeft, y, font.width("Empire: 99"), "Empire", empire.counts[planet.EMPIRE]
	w = font.width("Occupied: 99")
	drawLabeledField leftColLeft + infoWidth/2 - w/2, y, w, "Occupied", empire.counts[planet.OCCUPIED]
	w = font.width("Independent: 99")
	drawLabeledField rightColRight - w, y, w, "Independent", empire.counts[planet.INDEPENDENT]
end function

fleetButtons = {}
addFleetButtons = function(left, y, width)
	if fleetButtons then return		// (already added)
	ids = [7, 8, 9, 10]
	qty = ids.len
	w = round((width - 8 - qty + 1) / qty)

	x = left; id = ids[0]
	b = buttons.addButton(x, y, w+4, resources.buttonIcons[id], resources.buttonNames[id], true, false)
	b.action = @tryWarpToTarget
	fleetButtons.embark = b
	
	x += w+4 + 1; id = ids[1]
	b = buttons.addButton(x, y, w, resources.buttonIcons[id], resources.buttonNames[id], false, false)
	b.action = @sendSpySats
	fleetButtons.spysats = b

	x += w + 1; id = ids[2]
	b = buttons.addButton(x, y, w, resources.buttonIcons[id], resources.buttonNames[id], false, false)
	b.action = @cryosleep
	fleetButtons.cryonics = b
		
	x += w + 1; id = ids[3]
	b = buttons.addButton(x, y, width-x+left, resources.buttonIcons[id], resources.buttonNames[id],
		false, true)
	b.action = @scrapShips
	fleetButtons.scrap = b
end function

drawFleetInfo = function
	top = 640 - 80
	width = 400
	drawTitledBox 960-width, top, width, 150, "Fleet Orbiting " + fleet.planet.name
	leftColLeft = 960-width + 4
	rightColRight = 960 - 4
	infoWidth = rightColRight - leftColLeft
	colWidth = floor(width/2 - 12)
	rightColLeft = rightColRight - colWidth
	lineHeight = 16
	y = top-32
	
	addFleetButtons leftColLeft, y - lineHeight - 2, rightColRight - leftColLeft
	y -= lineHeight+4

	drawHeader leftColLeft, y, infoWidth, "Ships in Fleet"
	y -= lineHeight
	drawLabeledField leftColLeft, y, colWidth, "Manned Transports", fleet.mannedTransports
	drawLabeledField rightColLeft, y, colWidth, "Empty Transports", fleet.emptyTransports
	y -= lineHeight
	drawLabeledField leftColLeft, y, colWidth, "Fighters", fleet.fighters
	drawLabeledField rightColLeft, y, colWidth, "Spy Satellites", fleet.satellites
	y -= lineHeight
	drawLabeledField leftColLeft, y, colWidth, "Supply Ships", 3
	drawLabeledField rightColLeft, y, colWidth, "Fuel Ships", 2
	y -= lineHeight
	
	drawHeader leftColLeft, y, infoWidth, "Fleet Cargo/Capacity"
	y -= lineHeight
	drawLabeledField leftColLeft, y, colWidth, "Supplies", fleet.supplies + "/" + fleet.maxSupplies
	drawLabeledField rightColLeft, y, colWidth, "Fuel", fleet.fuel + "/" + fleet.maxFuel
	y -= lineHeight
	
	fleetButtons.scrap.enable fleet.totalShips > 0
end function

// draw a bunch of little icons, using multiple rows if necessary;
// return how much Y space was used
drawIcons = function(left, bottom, width, icon, count)
	spacing = 5	
	x = left
	y = bottom
	maxx = left + width
	for i in range(1, count)
		g.drawImage icon, x, y		
		x += spacing
		if x + icon.width > maxx and i < count then
			x = left
			y -= 16
		end if
	end for
	return bottom - y + 16
end function

// draw a bunch of ships of varying sizes (smallest first)
drawShips = function(left, bottom, width, height, pic, count)
	scale = 2/count
	scaleStep = 0.5/count
	for i in range(1, count)
		w = ceil(pic.width*scale)
		h = ceil(pic.height*scale)
		x = left + (width-w)*rnd
		y = bottom + (height-h)*rnd
		g.drawImage pic, x, y, w, h
		scale += scaleStep
	end for
end function

drawPlanetView = function
	planetView.draw
end function

targetButtons = {}
addTargetButtons = function(left, y, width)
	if targetButtons then
		for b in targetButtons.values
			b.y = y + b.image.height/2
		end for
		return
	end if
	ids = range(0, 6)
	keys = "tax enlist build supply fuel occupy attack".split
	qty = ids.len
	w = round((width - 8 - qty + 1) / qty)

	x = left
	for i in ids.indexes
		id = ids[i]
		extra = 4*(i==0 or i==qty-1)
		b = buttons.addButton(x, y, w + extra, 
		  resources.buttonIcons[id], resources.buttonNames[id], i==0, i==qty-1)
		targetButtons[keys[i]] = b
		x += w + extra + 1
	end for
	
	targetButtons.tax.action = @collectTaxes
	targetButtons.enlist.action = @manTransports
	targetButtons.build.action = @buildShips
	targetButtons.supply.action = @buySupplies
	targetButtons.fuel.action = @buyFuel
	targetButtons.occupy.action = @occupy
	targetButtons.attack.action = @attack
end function

hideTargetButtons = function
		for b in targetButtons.values
			b.y = -9999
		end for
end function

drawAllocations = function
	p = targetPlanet
	isOurs = (p.status == planet.EMPIRE)
	known = (p.satellites > 1 or isOurs or p == fleet.planet)
	y = allocTop
	lineHeight = 16
	allocWidth = allocRight - allocLeft
	x2 = allocRight + 40
	if p.status == planet.EMPIRE then barColor = buttonColor else barColor = infoColor
	for res in p.resources
		gfx.fillRect allocLeft, y-lineHeight, allocWidth + 70, lineHeight, color.black
		c = infoColor
		if (p.satellites > 0 or isOurs) and 
		   ((res.name == "Industry" and not p.hasIndustry) or
		    (res.name == "Mining" and not p.hasFuel)) then
			c = color.gray
			font.print "N/A", allocLeft, y-10, 1, c
		else if known then
			barW = round(allocWidth * res.allocation / 80)
			gfx.fillRect allocLeft, y-10, barW, 10, barColor
			font.print round(res.allocation) + "%", allocLeft + barW + 2, y-10, 1, barColor
		else
			font.print "Unknown", allocLeft, y-10, 1, infoColor
		end if
		if isOurs then s = round(res.production) else s = "N/A"
		font.printCentered s, x2, y-10, 1, c
		y -= lineHeight
	end for
end function

adjustAllocations = function
	if not (allocLeft <= mouse.x <= allocRight) then return
	p = targetPlanet
	lineHeight = 16
	allocWidth = allocRight - allocLeft
	idx = floor((allocTop - mouse.y) / lineHeight)
	if not (0 <= idx <= 4) then return
	
	minAllowed = 10
	maxAllowed = 80
	if p.hasIndustry then maxAllowed -= 10
	if p.hasFuel then maxAllowed -= 10
	
	while mouse.button		
		yield
		newAlloc = round(80 * (mouse.x - allocLeft) / allocWidth)
		if newAlloc < minAllowed then newAlloc = minAllowed
		if newAlloc > maxAllowed then newAlloc = maxAllowed
		if newAlloc == p.resources[idx].allocation then continue
		p.setAllocation idx, newAlloc
		targetPlanet.calcProduction
		drawAllocations
	end while	
end function

handleClick = function
	if mouse.y < allocTop and mouse.y > allocTop - 16*5 then
		// handle a click in the allocation area, if allowed
		if targetPlanet.status == planet.EMPIRE then adjustAllocations
	end if
end function

ifSats = function(statIfKnown, satsRequired)
	if targetPlanet.satellites < satsRequired and targetPlanet != fleet.planet then return "Unknown"
	return str(statIfKnown)
end function

drawTargetInfo = function
	p = targetPlanet
	isLocal = (targetPlanet == fleet.planet)
	isOurs = p.status == planet.EMPIRE
	width = 400
	top = 260
	drawTitledBox 960-width, top, width, 260, "Information on " + p.name
	leftColLeft = 960-width + 4
	rightColRight = 960 - 4
	infoWidth = rightColRight - leftColLeft
	colWidth = floor(width/2 - 12)
	rightColLeft = rightColRight - colWidth
	lineHeight = 16
	y = top-32
	
	if isLocal then
		addTargetButtons leftColLeft, y - lineHeight * 1.5, rightColRight - leftColLeft
		y -= lineHeight
	else
		hideTargetButtons
		dist = fleet.planet.distanceTo(targetPlanet)
		drawLabeledField leftColLeft, y, colWidth, "Distance", numToStr(dist, 2)
		drawLabeledField rightColLeft, y, colWidth, "Estimated Arrival", 
			numToStr(empire.year + dist, 2)
		y -= lineHeight
		suppCost = fleet.supplyCost(dist)
		drawLabeledField leftColLeft, y, colWidth, "Supplies Required", 
		  suppCost, suppCost <= fleet.supplies
		fuelCost = fleet.fuelCost(dist)
		drawLabeledField rightColLeft, y, colWidth, "Fuel Required",
		  fuelCost, fuelCost <= fleet.fuel		
	end if
	y -= lineHeight

	drawHeader leftColLeft, y, infoWidth, "General information"
	y -= lineHeight
	s = statusNames[p.status]
	if p.status == planet.OCCUPIED then s += " (" + floor(p.conqueredOn) + ")"
	drawLabeledField leftColLeft, y, colWidth, "Status", s
	
	sats = p.satellites
	if isLocal then sats = 3	// (unlike original: fleet presence equivalent to full spy sats)
	if sats == 0 then
		s = "Unknown"
	else if sats == 1 then
		s = "~" + round(p.population, -1) + " million"
	else
		s = numToStr(p.population, 1) + " million"
	end if
	drawLabeledField rightColLeft, y, colWidth, "Population", s

	y -= lineHeight
	drawLabeledField leftColLeft, y, colWidth, "Technology", ifSats(techNames[p.tech], 1)
	s = str(p.satellites)
	if p.incomingSats then s += "(" + p.incomingSats.len + ")"
	drawLabeledField rightColLeft, y, colWidth, "Orbiting Satellites", s
	y -= lineHeight
	
	drawHeader leftColLeft, y, infoWidth, "Resource Allocation and Information"
	y -= lineHeight
	x0 = leftColLeft + infoWidth * 0.22
	x1 = leftColLeft + infoWidth * 0.25
	x2 = leftColLeft + infoWidth * 0.72
	x3 = leftColLeft + infoWidth * 0.93
	printUnderlinedRight "Resource", x0, y
	printUnderlined "Allocation", x1, y
	printUnderlinedCenter "Production", x2, y
	printUnderlinedCenter "Current", x3, y
	y -= lineHeight
	outer.allocTop = y
	outer.allocLeft = x1
	outer.allocRight = x2 - 40
	for res in p.resources
		c = infoColor
		if sats > 0 and ((res.name == "Industry" and not p.hasIndustry) or
		   (res.name == "Mining" and not p.hasFuel)) then c = color.gray
		font.printRight res.name, x0, y-10, 1, c
		//font.print round(res.allocation) + "%", x1, y-10, 1, c
		//font.printCentered round(res.production), x2, y-10, 1, c
		if isOurs then s = round(res.amount) else s = "N/A"
		font.printCentered s, x3, y-10, 1, c
		y -= lineHeight
	end for
	drawAllocations
	
	if p.status == planet.EMPIRE then
		drawHeader leftColLeft, y, infoWidth, "Imperial History"
		y -= lineHeight
		// ToDo
		
	else
		if p.status == planet.OCCUPIED then h = "Occupation Strength" else h = "Military Strength"
		drawHeader leftColLeft, y, infoWidth, h
		y -= lineHeight
		drawLabeledField leftColLeft, y, colWidth, "Space Forces", ifSats(p.spaceForces, 3)
		drawLabeledField rightColLeft, y, colWidth, "Ground Forces", ifSats(p.groundForces, 3)
	end if
	
	targetButtons.tax.enable isLocal and isOurs
	targetButtons.enlist.enable isLocal and isOurs
	targetButtons.build.enable isLocal and isOurs and p.hasIndustry
	targetButtons.supply.enable isLocal and isOurs
	targetButtons.fuel.enable isLocal and isOurs and p.hasFuel
	targetButtons.occupy.enable isLocal and p.status == planet.OCCUPIED
	targetButtons.attack.enable isLocal and p.status == planet.INDEPENDENT
	
	fleetButtons.embark.enable not isLocal and fleet.canReach(p)
	fleetButtons.spysats.enable fleet.satellites > 0 and p.satellites + p.incomingSats.len < 3
end function

drawAll = function
	drawEmpireInfo
	drawFleetInfo
	drawPlanetView
	drawTargetInfo
end function
