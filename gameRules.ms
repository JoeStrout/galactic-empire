// This module gathers many of the "game rules" that dictate how
// play unfolds.  That includes probabilities for various events,
// combat rules, etc.

// Do 1 round of combat between space forces.  After this call,
// one (or both) of the given space forces will be slightly reduced.
//	planets: list of combatant planets (use Galactica for the empire side)
//	spaceForces: list of integers, how many fighters are on each side
doSpaceCombat = function(planets, spaceForces)
	// Odds of winning depend on relative tech level.  If evenly
	// matched, side 0 wins with probability 0.5.  But each
	// level of tech difference changes this by 0.15.  There are
	// 4 tech levels, so worst case a difference of 3 means the
	// probability will be 0.05 or 0.95.
	p = 0.5 + 0.15 * (planets[0].tech - planets[1].tech)
	if rnd < p then	// side 0 wins
		spaceForces[1] -= 1
	else			// side 1 wins
		spaceForces[0] -= 1
	end if
end function

// Same as above, but for land forces.
// (Less advantage for tech here since even primitive forces can dig in.)
doLandCombat = function(planets, landForces)
	p = 0.5 + 0.1 * (planets[0].tech - planets[1].tech)
	if rnd < p then	// side 0 wins
		landForces[1] -= 1
	else			// side 1 wins
		landForces[0] -= 1
	end if
end function
