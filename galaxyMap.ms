import "importUtil"
ensureImport "sounds"

left = 0
bottom = 0
width = 550
height = 600

mapDistanceFactor = 7.5		// divide map distances by this to get light years!

planetColors = ["#51A1FB", "#FF8888", "#37C824"]

display(7).mode = displayMode.pixel; starsGfx = display(7)
display(6).mode = displayMode.pixel; underlayGfx = display(6)
display(5).mode = displayMode.pixel; mapGfx = display(5)

drawPlanet = function(p, hovered=false)
	x = p.position.x; y = p.position.y
	c = planetColors[p.status]
	if hovered then c = color.lerp(c, color.white)
	
	mapGfx.fillEllipse x-5, y-5, 11, 11, c
	
	if p != targetPlanet then mapGfx.drawRect x-7, y-7, 15, 15, color.black
	if p != fleet.planet then mapGfx.drawEllipse x-7, y-7, 15, 15, color.black
	
	if p == targetPlanet then mapGfx.drawRect x-7, y-7, 15, 15, c
	if p == fleet.planet then mapGfx.drawEllipse x-7, y-7, 15, 15, c
	
	oldGfx = gfx; globals.gfx = mapGfx
	font.printCentered p.name, x, y - 15, 1, c
	globals.gfx = oldGfx	
end function

drawUnderlay = function
	underlayGfx.fillRect left, bottom, width, height, color.clear
	for p in planets
		for sat in p.incomingSats
			t = (empire.year - sat.launchYear) / (sat.arriveYear - sat.launchYear)
			p0 = mathUtil.lerp2d(sat.origin.position, p.position, t)
			underlayGfx.line p0[0], p0[1], p.position.x, p.position.y, "#CCCCCC"
		end for
	end for
end function

animateWarp = function(fromPlanet, toPlanet)
	duration = mathUtil.max(0.5, fromPlanet.distanceTo(toPlanet) / 20)
	fromPos = fromPlanet.position
	toPos = toPlanet.position
	
	sounds.warp(duration).play
	
	// Animate a line where the head reaches the target half a second
	// or so early, and the tail leaves the source by the same delay.
	delay = mathUtil.min(0.5, duration/2)
	startTime = time
	endTime = time + duration
	while time < endTime
		headT = mathUtil.min(1, (time - startTime) / (duration - delay))
		tailT = mathUtil.max(0, (time - delay - startTime) / (duration - delay))
		headPos = mathUtil.lerp2d(fromPos, toPos, headT)
		tailPos = mathUtil.lerp2d(fromPos, toPos, tailT)
		underlayGfx.line headPos[0], headPos[1], tailPos[0], tailPos[1], "#FFFFCC"
		yield
		underlayGfx.line headPos[0], headPos[1], tailPos[0], tailPos[1], color.clear
	end while
	
end function

drawStars = function
	starsGfx.fillRect left, bottom, width, height, color.black
	for i in range(500)
		c = color.rgb(200+55*rnd, 200+55*rnd, 200+55*rnd)
		starsGfx.setPixel left + width*rnd, bottom + height*rnd, c
	end for
end function

drawPlanets = function
	mapGfx.fillRect left, bottom, width, height, color.clear
	for p in planets
		drawPlanet p
	end for
end function

drawAll = function
	drawStars
	drawPlanets
	drawUnderlay
end function

planetUnderMouse = function
	pos = {}
	pos.x = mouse.x - left
	pos.y = mouse.y - bottom
	result = null
	bestD = 0
	for p in planets
		d = mathUtil.distance(pos, p.position)
		if d < 20 and (result == null or d < bestD) then
			result = p
			bestD = d
		end if
	end for
	return result
end function
