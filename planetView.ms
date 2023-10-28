// This module handles drawing the planet view, which is part of the info display,
// but a particularly complex part.  It includes the starry background and the
// planet hemisphere -- which scroll in and out of view as the fleet arrives and
// departs -- as well as the visual warp effect when warping from one planet to
// another.
//
// All this has to be composited offscreen, so the animation is flicker-free.

import "importUtil"
ensureImport "resources"
ensureImport "mathUtil"

// Position on screen
top = 640 - 80 - 150 + 1
bottom = 260
height = top - bottom
width = 400
left = 960-width


tempDisp = new PixelDisplay
starPlanetImage = null	// image of planet we're currently orbiting
transitImage = null		// image of planet we're approaching, while in transit

makeStarPlanetImage = function(planet=null)
	// create an image of the stars and planet, tall enough that we can
	// scroll the planet out of view
	tempDisp.clear color.black, width, height*2.5	
	for i in range(500)
		c = color.rgb(100+155*rnd, 100+155*rnd, 100+155*rnd)
		tempDisp.setPixel width*rnd, tempDisp.height*rnd, c
	end for
	if planet == null then p = resources.planets[0] else p = planet.image
	tempDisp.drawImage p, 0, 0
	
	return tempDisp.getImage(0, 0, tempDisp.width, tempDisp.height)
end function

prepare = function(planet=null)
	outer.starPlanetImage = makeStarPlanetImage(planet)
end function

prepareTransit = function(newPlanet)
	outer.transitImage = makeStarPlanetImage(newPlanet)
end function

draw = function
	gfx.drawImage starPlanetImage, left, bottom, width, height, 0, 0, width, height
	
	// draw fleet ship icons (something I was experimenting with at some point)
//	y = top - 20
//	y -= drawIcons(left+8, y, width-16, resources.pics.transportIcon, fleet.mannedTransports)
//	y -= drawIcons(left+8, y, width-16, resources.pics.transportIconEmpty, fleet.emptyTransports)
//	y -= drawIcons(left+8, y, width-16, resources.pics.fighterIcon, fleet.fighters)
//	// ToDo: draw satellites, supply ships, and fuel ships too!
	
//	drawShips left+8, bottom, width-60, height, resources.pics.transportEmpty, ceil(fleet.emptyTransports/10)
//	drawShips left+8, bottom, width-60, height, resources.pics.transport, ceil(fleet.mannedTransports/10)
		
	gfx.drawRect left, bottom, width, height, "#888888"
end function

// Slowly pan away from the planet, showing only empty space (with stars)
animateDeparture = function(duration = 2.5)
	maxy = starPlanetImage.height - height
	startTime = time
	endTime = startTime + duration
	while time < endTime
		s = (time - startTime) / duration
		t = 3 * s^2 - 2 * s^3	// (ease-in, ease-out)
		y = mathUtil.lerp(0, maxy, t)
		gfx.drawImage starPlanetImage, left+1, bottom+1, width-2, height-2, 1, y+1, width-2, height-2
		yield
	end while
end function

// Slowly pan back towards from the planet
animateArrival = function(duration = 2.5)
	if transitImage != null then
		outer.starPlanetImage = transitImage
		outer.transitImage = null
	end if
	maxy = starPlanetImage.height - height
	startTime = time
	endTime = startTime + duration
	while time < endTime
		s = (time - startTime) / duration
		t = 3 * s^2 - 2 * s^3	// (ease-in, ease-out)
		y = mathUtil.lerp(maxy, 0, t)
		gfx.drawImage starPlanetImage, left+1, bottom+1, width-2, height-2, 1, y+1, width-2, height-2
		yield
	end while
end function

drawWarpRings = function(g, timeSinceStart, duration)
	midX = width/2; midY = height/2; yFactor = 3/5
	colors = [color.black, color.white]
	cidx = 1
	outerR = 20 * 1.1^(timeSinceStart*60)
	innerR = 5
	clearTime = mathUtil.min(0.5, duration/2)
	if timeSinceStart > duration - clearTime then
		timeLeft = duration - timeSinceStart
		innerR = mathUtil.lerp(width * 0.7, 5, timeLeft/clearTime)
	end if
	r = outerR
	while r > innerR
		nextr = r * 0.8
		if nextr < width * 0.7 then
			g.drawEllipse midX-r, midY-r*yFactor, r*2, r*2*yFactor, colors[cidx], r - nextr
		end if
		r = nextr
		cidx = not cidx
	end while
	g.fillEllipse midX-innerR, midY-innerR*yFactor, innerR*2, innerR*2*yFactor, color.clear	
end function

drawWarpFrame = function(timeSinceStart, duration)
	if timeSinceStart == 0 then tempDisp.clear color.clear, width, height
	drawWarpRings tempDisp, timeSinceStart, duration
	img = tempDisp.getImage(0, 0, width, height)
	if timeSinceStart > duration/2 and transitImage then p = transitImage else p = starPlanetImage
	gfx.drawImage p, left+1, bottom+1, width-2, height-2, 
			1, starPlanetImage.height - height+1, width-2, height-2
	gfx.drawImage img, left+1, bottom+1, width-2, height-2, 1, 1, width-2, height-2
end function

// Do the animated warp effect!
animateWarp = function(duration=1.5)
	startTime = time
	while time < startTime+duration
		drawWarpFrame  time-startTime, duration
	end while
end function

if locals == globals then
	clear
	prepare
	draw
	key.get;	animateDeparture
	key.get;	animateWarp
	key.get;	animateArrival
end if
