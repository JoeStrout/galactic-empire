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
Planet.joinedOn = null		// turn on which it joined the empire

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
		divisor = self.resources.len - 1
		if not self.hasIndustry then divisor -= 1
		if not self.hasFuel then divisor -= 1
		// loop over all allocations, starting at a random point
		i = floor(allocs.len * rnd)
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
	
	// If independent, grow military forces;
	// if occupied, battle occupation forces or give up and join the empire.
	// Exact rules for this are TBD; below is a placeholder for now.
	if self.status == INDEPENDENT then
		if self.hasIndustry then self.spaceForces += round(years * rnd * 0.5)
		self.groundForces += round(years * rnd * 0.8)
	else if self.status == OCCUPIED then
		self.spaceForces = mathUtil.max(0, self.spaceForces - round(years * rnd * 3))
		self.groundForces = mathUtil.max(0, self.groundForces - round(years * rnd))
		if self.spaceForces == 0 and self.groundForces == 0 and rnd > 0.5^years then
			self.rebel
		else if empire.year - self.conqueredOn > 20 then
			self.joinEmpire
		end if
	end if
end function

// Shake off our occupation and become independent again.
Planet.rebel = function
	self.status = INDEPENDENT
	galaxyMap.drawPlanet self
//	infoDisplay.drawAll
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
	return p
end function

