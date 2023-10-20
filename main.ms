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
end function

tryWarpToTarget = function
	if targetPlanet == fleet.planet then return
	if not fleet.canReach(targetPlanet) then return
	// WARP!!!
	dist = fleet.planet.distanceTo(targetPlanet)
	oldPlanet = fleet.planet
	fleet.makeTrip targetPlanet
	advanceTime dist
	galaxyMap.drawPlanet oldPlanet
	galaxyMap.drawPlanet targetPlanet, mouseOverPlanet == targetPlanet
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
		targetPlanet.status = planet.OCCUPIED
		targetPlanet.occupiedOn = empire.year
		galaxyMap.drawPlanet targetPlanet, mouseOverPlanet == targetPlanet
		targetPlanet.spaceForces = 0
		targetPlanet.groundForces = 0
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
	// for now, just build 50 at a time -- fighters with Option key, else transports
	qtyFighters = 0; qtyTransports = 0
	if key.pressed("left alt") or key.pressed("right alt") then 
		qtyFighters = 50
		qtyFighters = mathUtil.min(50, floor(targetPlanet.shipParts.amount / 10))
		qtyFighters = mathUtil.min(qtyFighters, floor(empire.credits / 16))
	else
		qtyTransports = 50
		qtyTransports = mathUtil.min(50, floor(targetPlanet.shipParts.amount / 5))
		qtyTransports = mathUtil.min(qtyTransports, floor(empire.credits / 4))
	end if
	totalQty = qtyFighters + qtyTransports
	if totalQty == 0 then return
	partCost = 10 * qtyFighters + 5 * qtyTransports
	creditCost = 16 * qtyFighters + 4 * qtyTransports
	empire.credits -= creditCost
	fleet.fighters += qtyFighters
	fleet.emptyTransports += qtyTransports
	targetPlanet.shipParts.amount -= partCost
	advanceTime 1
	infoDisplay.drawAll
end function

manTransports = function
	if targetPlanet != fleet.planet or targetPlanet.status != planet.EMPIRE then return
	// for now, just man up to 50 transports at a time
	qty = [50, fleet.emptyTransports, targetPlanet.troops.amount].min
	if qty == 0 then return
	fleet.emptyTransports -= qty
	fleet.mannedTransports += qty
	targetPlanet.troops.amount -= qty
	advanceTime 0.25
	infoDisplay.drawAll
end function

updateMap = function
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
end function

galaxyMap.draw
infoDisplay.drawAll

events.eventLoop.onUpdate = @updateMap
events.eventLoop.onKey["escape"] = @events.eventLoop.stop
events.eventLoop.run
key.clear
