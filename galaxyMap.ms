
left = 0
bottom = 0
width = 550
height = 600

mapDistanceFactor = 7.5		// divide map distances by this to get light years!

planetColors = ["#51A1FB", "#FF8888", "#37C824"]

drawPlanet = function(p, hovered=false)
	x = p.position.x; y = p.position.y
	c = planetColors[p.status]
	if hovered then c = color.lerp(c, color.white)
	
	gfx.fillEllipse x-5, y-5, 11, 11, c
	
	if p != targetPlanet then gfx.drawRect x-7, y-7, 15, 15, color.black
	if p != fleet.planet then gfx.drawEllipse x-7, y-7, 15, 15, color.black
	
	if p == targetPlanet then gfx.drawRect x-7, y-7, 15, 15, c
	if p == fleet.planet then gfx.drawEllipse x-7, y-7, 15, 15, c
	
	font.printCentered p.name, x, y - 15, 1, c
end function

draw = function
	gfx.fillRect left, bottom, width, height, color.black
	for i in range(500)
		c = color.rgb(200+55*rnd, 200+55*rnd, 200+55*rnd)
		gfx.setPixel left + width*rnd, bottom + height*rnd, c
	end for
	for p in planets
		drawPlanet p
	end for
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
	