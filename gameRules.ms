// This module gathers many of the "game rules" that dictate how
// play unfolds.  That includes probabilities for various events,
// combat rules, etc.

// Do 1 round of combat between space forces.  After this call,
// one (or both) of the given space forces will be slightly reduced.
// Return index of which side won.
//	planets: list of combatant planets (use Galactica for the empire side)
//	spaceForces: list of integers, how many fighters are on each side
doSpaceCombat = function(planets, spaceForces)
	// Odds of winning depend on relative tech level.  If evenly
	// matched, side 0 wins with probability 0.5.  But each
	// level of tech difference changes this by 0.15.  There are
	// 4 tech levels, so worst case a difference of 3 means the
	// probability will be 0.05 or 0.95.
	p = 0.5 + 0.15 * (planets[0].tech - planets[1].tech)
	winner = (rnd > p)
	spaceForces[1 - winner] -= 1
	return winner
end function

// Same as above, but for land forces.
// (Less advantage for tech here since even primitive forces can dig in.)
doLandCombat = function(planets, landForces)
	p = 0.5 + 0.1 * (planets[0].tech - planets[1].tech)
	winner = (rnd > p)
	landForces[1 - winner] -= 1
	return winner
end function

// Return how many fighters this planet will build if left alone.
// Depends on tech level, population size, and military allocation
// (and eventually, on game difficulty).
spaceForceSize = function(planet)
	techFactor = [0, 0, 0.29, 0.32][planet.tech - 1]
	return round(techFactor * planet.population * planet.troops.allocation * 0.1)
end function

// Return how many ground forces this planet will build if left alone.
// Depends on tech level, population size, and military allocation.
groundForceSize = function(planet)
	techFactor = [0.61, 0.79, 1, 1][planet.tech - 1]
	return round(techFactor * planet.population * planet.troops.allocation * 0.1)
end function
