// Data related to the empire as a whole (excluding the fleet).

import "importUtil"
ensureImport "planet"

// how many years since the start of the game (aka "Star Date")
year = 0

// credits (money)
credits = 1900

// totals (derived from planetary data)
counts = {}
counts[planet.EMPIRE] = 1
counts[planet.OCCUPIED] = 0
counts[planet.INDEPENDENT] = 0
totalPop = {}
totalPop[planet.EMPIRE] = 40
totalPop[planet.OCCUPIED] = 0
totalPop[planet.INDEPENDENT] = 0

updateTotals = function
	for k in counts.indexes
		counts[k] = 0
		totalPop[k] = 0
	end for
	for p in planets
		counts[p.status] += 1
		totalPop[p.status] += p.population
	end for
end function


