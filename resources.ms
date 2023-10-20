pics = {}

for filename in file.children("pictures")
	if filename[-4:] != ".png" then continue
	pics[filename - ".png"] = file.loadImage("pictures/" + filename)
end for

_buttonIcons = null
buttonIcons = function
	if _buttonIcons == null then
		outer._buttonIcons = []
		src = pics.buttonIcons
		x = 0
		while x + 20 < src.width
			_buttonIcons.push src.getImage(x, 0, 25, src.height)
			x += 25
		end while
	end if
	return _buttonIcons
end function

buttonNames = ["Collect Taxes", "Enlist Troops", "Build Ships", "Buy Supplies",
	"Buy Fuel", "Resource Allocation", "Occupation Forces", "Attack",
	"Embark", "Send Spy Sats", "Cryonics", "Scrap Ships"]
	
