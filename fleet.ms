// what planet we're currently orbiting
planet = null

// current ships of various types
mannedTransports = 60
emptyTransports = 60
fighters = 160
satellites = 9
supplyShips = 3
fuelShips = 2

// current supplies
supplies = 2640
fuel = 1760

// derived measures
maxSupplies = function; return supplyShips * 1000; end function
maxFuel = function; return fuelShips * 1000; end function

totalShips = function
	return mannedTransports + emptyTransports + fighters + satellites +
	  supplyShips + fuelShips
end function

fuelCost = function(distance)
	return round(totalShips * distance/10)
end function

supplyCost = function(distance)
	return floor(fighters * distance/10 + mannedTransports * 5 * distance/10)
end function

canReach = function(target)
	dist = planet.distanceTo(target)
	return fuel >= fuelCost(dist) and supplies >= supplyCost(dist)
end function

makeTrip = function(target)
	dist = planet.distanceTo(target)
print "fleet.makeTrip hacked"
//	outer.fuel -= fuelCost(dist)
//	outer.supplies -= supplyCost(dist)
	outer.planet = target
end function

