// This module is responsible for all the synthesized sounds in the game.

import "importUtil"
ensureImport "mathUtil"

// Build a warp sound of the given duration.
// This sound goes high, holds for a bit, then goes back low
// (with a little bounce at the end).
warp = function(duration=1)
	
	lowF = noteFreq(68)
	highF = noteFreq(72)
	endF = noteFreq(48)
	freq = [highF] * (duration*10)
	if freq.len < 8 then freq = [highF]*8
	tail = []
	for i in range(0,6)
		tail.push mathUtil.lerp(highF, endF, i/4)
	end for
	tail.push endF; tail.push endF
	freq = freq[:-tail.len] + tail
	
	envelope = [1]*freq.len + [0.1, 1, 1]
	
	snd = new Sound
	snd.init duration, freq, envelope, Sound.squareWave
	
	lowF = noteFreq(68+4)
	highF = noteFreq(72+4)
	endF = noteFreq(48+4)
	freq = [highF] * (duration*10)
	if freq.len < 8 then freq = [highF]*8
	tail = []
	for i in range(0,6)
		tail.push mathUtil.lerp(highF, endF, i/4)
	end for
	freq = freq[:-tail.len] + tail
	snd2 = new Sound
	snd2.init duration, freq, envelope, Sound.sawtoothWave
	snd.mix snd2, 0.6
	
	envelope = [1,1,0.5] + [0]*freq.len + [0.5,1,1,0]
	snd3 = new Sound
	snd3.init duration, 1, envelope, Sound.noiseWave
	snd.mix snd3, 2
	
	snd.fadeIn = 0.1
	snd.fadeOut = 0.2
	return snd
end function

if locals == globals then
	warp.play
end if
