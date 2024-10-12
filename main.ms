import "importUtil"

clear

// Load resources
ensureImport "bmfFonts"
bigFont = bmfFonts.Font.load("/sys/fonts/minimicro-pro-16.bmf")
font = bmfFonts.Font.load("/sys/fonts/minimicro-pro-12.bmf")

// Load helper modules
ensureImport "mathUtil"
ensureImport "listUtil"
ensureImport "planet"
ensureImport "infoDisplay"
ensureImport "galaxyMap"
ensureImport "fleet"
ensureImport "empire"
ensureImport "events"
ensureImport "dialogs"
ensureImport "planetView"

// Initialize the game
planets = []
planets.push Planet.makeGalactica
for i in range(1,19)
	planets.push Planet.makeRandom
end for
for p in planets
	p.calcProduction
	p.advanceTime 40
end for
mouseUpTime = 0
mouseOverPlanet = null
targetPlanet = planets[0]
fleet.planet = planets[0]
planetView.prepare

empire.updateTotals

setTarget = function(planet)
	oldTarget = targetPlanet
	globals.targetPlanet = planet
	infoDisplay.drawTargetInfo
	galaxyMap.drawPlanet oldTarget
	galaxyMap.drawPlanet targetPlanet, mouseOverPlanet == targetPlanet
end function

advanceTime = function(years)
	empire.year += years
	for p in planets
		p.advanceTime years
	end for
	empire.updateTotals
	galaxyMap.drawUnderlay
	if empire.counts[planet.INDEPENDENT] == 0 then
		gameOver = new dialogs.GameOverDialog
		gameOver.won = true
		gameOver.run
		exit
	else if empire.year >= 1200 then
		gameOver = new dialogs.GameOverDialog
		gameOver.won = false
		gameOver.run
		exit
	end if
end function

tryWarpToTarget = function
	if targetPlanet == fleet.planet then return
	if not fleet.canReach(targetPlanet) then return

	// WARP!!!
	planetView.prepareTransit targetPlanet
	planetView.animateDeparture
	galaxyMap.animateWarp fleet.planet, targetPlanet, @planetView.drawWarpFrame
	planetView.animateArrival
	
	dist = fleet.planet.distanceTo(targetPlanet)
	oldPlanet = fleet.planet
	fleet.makeTrip targetPlanet
	advanceTime dist
	galaxyMap.drawPlanet oldPlanet
	galaxyMap.drawPlanet targetPlanet, mouseOverPlanet == targetPlanet
	infoDisplay.drawAll
end function

sendSpySats = function
	//dialogs.MsgDialog.show "Not implemented yet.", "Send Spy Satellites"
	if fleet.satellites < 1 then
		dialogs.MsgDialog.show "The fleet has no spy satellites to spare.", "Send Spy Satellites"		
	else if targetPlanet.satellites + targetPlanet.incomingSats.len >= 3 then
		dialogs.MsgDialog.show targetPlanet.name + " already has 3 satellites.", "Send Spy Satellites"
	else
		fleet.satellites -= 1
		targetPlanet.addIncomingSat
		infoDisplay.drawAll
		galaxyMap.drawUnderlay
	end if
end function

cryosleep = function
	d = new dialogs.CryonicsDialog
	d.run
	infoDisplay.drawAll
end function

scrapShips = function
	d = new dialogs.ScrapDialog
	d.run
	infoDisplay.drawAll
end function

attack = function
	if targetPlanet != fleet.planet or targetPlanet.status != planet.INDEPENDENT then return
	dlog = new dialogs.BattleDialog
	dlog.sides = ["Empire", targetPlanet.name]
	dlog.spaceForces = [fleet.fighters, targetPlanet.spaceForces]
	dlog.groundForces = [fleet.mannedTransports, targetPlanet.groundForces]

	dlog.run

	fleet.fighters = dlog.spaceForces[0]
	fleet.mannedTransports = dlog.groundForces[0]
	if dlog.winner == 0 then	// empire won
		targetPlanet.occupy
		galaxyMap.drawPlanet targetPlanet, mouseOverPlanet == targetPlanet
		empire.updateTotals
	else						// empire lost or withdrew
		targetPlanet.spaceForces = dlog.spaceForces[1]
		targetPlanet.groundForces = dlog.groundForces[1]
	end if
	infoDisplay.drawAll
end function

occupy = function
	if targetPlanet != fleet.planet or targetPlanet.status != planet.OCCUPIED then return
	// for now, increase occupation forces by 25 at a time (hold Alt to use fighters)
	qtyGround = 0; qtySpace = 0
	if key.pressed("left alt") or key.pressed("right alt") then
		qtySpace = mathUtil.min(25, fleet.fighters)
	else
		qtyGround = mathUtil.min(25, fleet.mannedTransports)
	end if
	if qtyGround + qtySpace == 0 then return
	targetPlanet.groundForces += qtyGround
	fleet.mannedTransports -= qtyGround
	targetPlanet.spaceForces += qtySpace
	fleet.fighters -= qtySpace
	infoDisplay.drawAll
end function

collectTaxes = function
	if targetPlanet != fleet.planet or targetPlanet.status != planet.EMPIRE then return
	empire.credits += round(targetPlanet.credits.amount)
	targetPlanet.credits.amount = 0
	infoDisplay.drawAll
end function

buySupplies = function
	if targetPlanet != fleet.planet or targetPlanet.status != planet.EMPIRE then return
	// for now, just buy max possible
	unitCost = 3
	canCarry = fleet.maxSupplies - fleet.supplies
	canAfford = floor(empire.credits / unitCost)
	qty = mathUtil.min(canCarry, canAfford)
	qty = round(mathUtil.min(qty, targetPlanet.supplies.amount))
	if qty == 0 then return
	empire.credits -= qty * unitCost
	fleet.supplies += qty
	targetPlanet.supplies.amount -= qty
	advanceTime 0.25
	infoDisplay.drawAll
end function

buyFuel = function
	if targetPlanet != fleet.planet or targetPlanet.status != planet.EMPIRE then return
	// for now, just buy max possible
	unitCost = 4
	canCarry = fleet.maxFuel - fleet.fuel
	canAfford = floor(empire.credits / unitCost)
	qty = mathUtil.min(canCarry, canAfford)
	qty = round(mathUtil.min(qty, targetPlanet.fuel.amount))
	if qty == 0 then return
	empire.credits -= qty * unitCost
	fleet.fuel += qty
	targetPlanet.fuel.amount -= qty
	advanceTime 0.25
	infoDisplay.drawAll
end function

buildShips = function
	if targetPlanet != fleet.planet or targetPlanet.status != planet.EMPIRE then return	

	dlog = new dialogs.BuildDialog
	dlog.planet = fleet.planet
	dlog.run
	
	if dlog.totalQty > 0 then advanceTime 1
	infoDisplay.drawAll
end function

manTransports = function
	if targetPlanet != fleet.planet or targetPlanet.status != planet.EMPIRE then return
	// for now, just man up to 50 transports at a time
	qty = floor([50, fleet.emptyTransports, targetPlanet.troops.amount].min)
	if qty == 0 then return
	fleet.emptyTransports -= qty
	fleet.mannedTransports += qty
	targetPlanet.troops.amount -= qty
	advanceTime 0.25
	infoDisplay.drawAll
end function

updateMap = function
	if dialogs.current then return
	p = galaxyMap.planetUnderMouse
	if p != mouseOverPlanet then
		if mouseOverPlanet then galaxyMap.drawPlanet mouseOverPlanet
		outer.mouseOverPlanet = p
		if mouseOverPlanet then galaxyMap.drawPlanet mouseOverPlanet, true
	end if
	if mouse.button and p then
		sameTarget = (mouseOverPlanet == targetPlanet)
		if mouseOverPlanet and not sameTarget then setTarget mouseOverPlanet
		while mouse.button; yield; end while
		if time - mouseUpTime < 0.5 and sameTarget then
			tryWarpToTarget
		else
			outer.mouseUpTime = time
		end if
	end if
	if mouse.button and mouse.x > galaxyMap.width then infoDisplay.handleClick
end function

galaxyMap.drawAll
infoDisplay.drawAll

events.eventLoop.onUpdate = @updateMap
//events.eventLoop.onKey["escape"] = @events.eventLoop.stop
events.eventLoop.run
key.clear
