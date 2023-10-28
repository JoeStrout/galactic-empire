import "importUtil"
ensureImport "mathUtil"

// planet status codes:
INDEPENDENT = 0
OCCUPIED = 1
EMPIRE = 2

globals.Resource = {}
Resource.name = "Agriculture"
Resource.allocation = 20		// %, from 10-100
Resource.production = 0			// production rate, per turn
Resource.amount = 0				// current amount
Resource.make = function(name, allocation=0)
	res = new Resource
	res.name = name
	res.allocation = allocation
	return res
end function
Resource.calcProduction = function(population, factor)
	if self.allocation <= 10 then
		self.production = 0
	else
		self.production = (self.allocation - 10) * population * factor
	end if
end function

IncomingSat = {}
IncomingSat.origin = null		// planet sats are coming from
IncomingSat.launchYear = 0		// empire.year at which sats were launched
IncomingSat.arriveYear = 0		// empire.year at which they should arrive

globals.Planet = {}

Planet.position = {"x":0, "y":0}
Planet.population = 40		// (million)
Planet.status = INDEPENDENT
Planet.tech = 2			// 1-4: primitive, limited, advanced, and superior
Planet.satellites = 0	// 0-3 orbiting satellites
Planet.supplies = Resource.make("Agriculture")
Planet.credits = Resource.make("Economy")
Planet.shipParts = Resource.make("Industry")
Planet.troops = Resource.make("Military")
Planet.fuel = Resource.make("Mining")
Planet.spaceForces = 0		// space forces (defending or occupying)
Planet.groundForces = 0		// ground forces (defending or occupying)
Planet.conqueredOn = null	// turn on which it was conquered
Planet.joinedOn = null		// turn on which it joined (or WILL JOIN) the empire
Planet.incomingSats = null	// list of IncomingSat instances
Planet.image = null

Planet.hasIndustry = function; return self.tech > 2; end function
Planet.hasFuel = function; return self.tech > 1; end function

Planet.distanceTo = function(other)
	return mathUtil.distance(self.position, other.position) / galaxyMap.mapDistanceFactor
end function

Planet.calcProduction = function
	// Production of each resource depends on population and allocation,
	// as well as a factor unique to each resource type.
	self.supplies.calcProduction  self.population, 0.0288
	self.credits.calcProduction   self.population, 0.2348
	self.shipParts.calcProduction self.population, 0.0339
	self.troops.calcProduction    self.population, 0.0105
	self.fuel.calcProduction      self.population, 0.0175
end function

_extraStartRow = -1	// (see comments in Planet.setAllocation)

Planet.setAllocation = function(resIndex, newPercent)
	// Set the given resource to the given percent (0-100); adjust all
	// others so that the sum is still 100.
	allocs = []
	for res in self.resources
		allocs.push res.allocation
	end for
	allocs[resIndex] = newPercent
	extra = allocs.sum - 100
//	text.clear; text.row = 25; print "extra: " + extra
	if extra then
		divisor = allocs.len - 1
		if not self.hasIndustry then divisor -= 1
		if not self.hasFuel then divisor -= 1
		// Loop over all allocations, applying adjustments until all the
		// extra is accounted for.  Do this starting at a different row
		// every time, so any uneven extra doesn't always go to the same one.
		outer._extraStartRow = (_extraStartRow + 1) % allocs.len
		i = _extraStartRow
		while extra
			if allocs[i] != 0 and i != resIndex then
				delta = -extra / divisor
				if delta > 0 then delta = ceil(delta) else delta = floor(delta)
//				print "#" + i + ": -" + extra + "/" + divisor + " = delta: " + delta
				if allocs[i] + delta < 10 then delta = 10 - allocs[i]
				allocs[i] += delta
				extra += delta
				if divisor > 1 then divisor -= 1
			end if
			i = (i + 1) % allocs.len
		end while
	end if
	for i in allocs.indexes
		self.resources[i].allocation = allocs[i]
	end for
end function

Planet.advanceTime = function(years)
	// grow population
	growthRate = 1.01	// ToDo: vary this based on allocations, etc.
	self.population *= growthRate^years
	
	// produce resources
	for res in self.resources
		res.amount += res.production * years
	end for
	
	// put incoming sats into orbit
	for i in range(self.incomingSats.len - 1, 0, -1)
		if empire.year >= self.incomingSats[i].arriveYear then
			if self.satellites < 3 then self.satellites += 1
			self.incomingSats.remove i
		end if
	end for
	
	// If independent, grow military forces (to full strength over 50 years);
	// if occupied, reduce occupation forces (at half the rate we would grow our own),
	// or give up and join the empire.	
	maxSpaceForce = gameRules.spaceForceSize(self)
	maxGroundForce = gameRules.groundForceSize(self)
	if self.status == INDEPENDENT then
		if self.spaceForces < maxSpaceForce then
			perYear = maxSpaceForce / 50
			self.spaceForces = mathUtil.min(maxSpaceForce, 
			  self.spaceForces + floor(perYear * years + rnd))
		end if
		if self.groundForces < maxGroundForce then
			perYear = maxGroundForce / 50
			self.groundForces = mathUtil.min(maxGroundForce, 
			  self.groundForces + floor(perYear * years + rnd))
		end if
	else if self.status == OCCUPIED then
		if self.spaceForces > 0 then
			perYear = maxSpaceForce / 100
			self.spaceForces = mathUtil.max(0, 
			  self.spaceForces - floor(perYear * years + rnd))
		end if
		if self.groundForces > 0 then
			perYear = maxGroundForce / 100
			self.groundForces = mathUtil.max(0, 
			  self.groundForces - floor(perYear * years + rnd))
		end if
		if self.spaceForces == 0 and self.groundForces == 0 and rnd > 0.5^years then
			self.rebel
		else if empire.year > self.joinedOn then
			self.joinEmpire
		end if
	end if
end function

// Planet is freshly conquered!  Mark it as occupied
Planet.occupy = function
	self.status = OCCUPIED
	self.conqueredOn = empire.year
	self.joinedOn = round(empire.year + 40 + rnd*5 + rnd*5)
	self.spaceForces = 0
	self.groundForces = 0
end function

// Shake off our occupation and become independent again.
Planet.rebel = function
	self.status = INDEPENDENT
	galaxyMap.drawPlanet self
	infoDisplay.drawAll
	dialogs.MsgDialog.show "Control of " + self.name + " has been lost."
end function

// Join the glorious Empire.
Planet.joinEmpire = function
	self.status = EMPIRE
	self.joinedOn = empire.year
	galaxyMap.drawPlanet self
	for res in [self.supplies, self.credits, self.shipParts, self.troops, self.fuel]
		res.amount = 0
	end for
	infoDisplay.drawAll
	dialogs.MsgDialog.show self.name + " has joined the Empire."
end function

Planet.addIncomingSat = function
	if fleet.planet == self then
		// fleet is right here; deploy directly to orbit
		self.satellites += 1
	else
		// launch a satellite to arrive later
		noob = new IncomingSat
		noob.origin = fleet.planet
		noob.launchYear = empire.year
		noob.arriveYear = noob.launchYear + noob.origin.distanceTo(self)
		self.incomingSats.push noob
	end if
end function

availableNames = ("Alhambra Bok Drassa Eventide Farside Harkon Javiny Kgolta Llythll" +
 " Moonsweep Novena Ootsi Procy Sparta Twyrx Utopia Viejo Yang-tzu Zoe").split
usedNames = []
availableNames.shuffle

randomPosition = function
	result = {}
	result.x = 50 + round(450*rnd)
	result.y = 30 + round(550*rnd)
	return result
end function

randomAllocs = function(qty=5)
	while true
		result = []
		for i in range(1, qty - 1)
			result.push round(100/qty * (1 + mathUtil.randNormal / 3))
			if result[-1] < 10 then result[-1] = 10
			if result[-1] > 90 then result[-1] = 90
		end for
		if result.sum > 90 then continue
		result.push 100 - result.sum
		result.shuffle
		return result
	end while
end function

Planet.overlaps = function(other)
	return abs(self.position.x - other.position.x) < 80 and
		abs(self.position.y - other.position.y) < 24
end function

Planet.makeGalactica = function
	p = new Planet
	p.name = "Galactica"
	p.position = randomPosition
	p.status = EMPIRE
	p.tech = 3
	p.supplies = Resource.make(p.supplies.name, 20)
	p.credits = Resource.make(p.credits.name, 20)
	p.troops = Resource.make(p.troops.name, 20)
	p.fuel = Resource.make(p.fuel.name, 20)
	p.shipParts = Resource.make(p.shipParts.name, 20)
	p.resources = [p.supplies, p.credits, p.shipParts, p.troops, p.fuel]
	p.satellites = 3
	p.incomingSats = []
	p.image = resources.planets[0]
	return p
end function

Planet.makeRandom = function
	p = new Planet
	if not availableNames then
		outer.availableNames += usedNames
		availableNames.shuffle
	end if
	p.name = availableNames.pull
	usedNames.push p.name
	p.image = resources.planets[1 + rnd * (resources.planets.len-1)]
	
	while true
		p.position = randomPosition
		ok = true
		for other in planets
			if p.overlaps(other) then
				ok = false
				break
			end if
		end for
		if ok then break
	end while
	
	p.tech = 1 + floor(rnd*4)
	p.population = 5 + round(35*rnd)
	
	if p.tech > 2 then
		r = randomAllocs(5)
	else if p.tech > 1 then
		r = randomAllocs(4) + [0]  // no ship parts
	else
		r = randomAllocs(3) + [0, 0]  // no ship parts or fuel
	end if
	p.supplies = Resource.make(p.supplies.name, r[0])
	p.credits = Resource.make(p.credits.name, r[1])
	p.troops = Resource.make(p.troops.name, r[2])
	p.fuel = Resource.make(p.fuel.name, r[3])
	p.shipParts = Resource.make(p.shipParts.name, r[4])
	if p.hasIndustry then p.spaceForces = 10 + round(p.population*2*rnd)
	p.groundForces = 10 + round(p.population*3*rnd)
	p.resources = [p.supplies, p.credits, p.shipParts, p.troops, p.fuel]
	p.incomingSats = []
	return p
end function

