--[[
		Retro-Gadgets Guide
			The goal is to get comfortable with the pixel layout of a 64x64 pixel screen, 
		creating basic sprites, and updating their movement on the screen with a controller.			

		Simulated Hardware Included in Project:
			Front: Lcd0, LedButton0, LedButton1, Led0, LedStrip0, Stick0, Screen0
			Back: VideoChip0, CPU0, ROM, FlashMemory0
		
		Symbolic Legend for function's dependencies
			-- (inherited variables) :: [hardware componets] :: {inherited functions} :: <assests>
		Tip
			Edit CPU0.lua in editor of choice, then copy/paste into Retro Gadgets to simulate
				A RetroGadets Update will be making improvements to the editor experience 

]]--


--]	IC Configurations [--
local video0: VideoChip = gdt.VideoChip0
local screen0: Screen = gdt.Screen0
local rom: ROM = gdt.ROM
local memory: FlashMemory = gdt.FlashMemory0
--]	I/O Configurations [--
local display0: LcdDisplay = gdt.Lcd0
local stick0: AnalogStick = gdt.Stick0
local btn0: LedButton = gdt.LedButton0
local btn1: LedButton = gdt.LedButton1
local led0: Led = gdt.Led0
local ledS0: LedStrip = gdt.LedStrip0
--]	Connect Screen to VideoChip and related variables [--
screen0.VideoChip = video0
local maxPixel: number = 64		--for a square
local playerPixels: number = 8	--for a square
local center: number = (maxPixel - playerPixels) / 2 - 1 	-- (64/2) - 1
--]	Assets [--
local font: SpriteSheet = rom.System.SpriteSheets["StandardFont"]
local player: SpriteSheet = rom.User.SpriteSheets["object.png"]
local border: SpriteSheet = rom.User.SpriteSheets["border.png"]
--]	Player object controller variables [--
local playerXpos:number, playerYpos:number = center, center		--inital position of player
local playerSpeed = 1
--]	Game Engine controller variables [--
local tick: number = 0
local autoSave_freq: number = 60
local globalTick: number = 0

--]	Update (Main) function at each tick [--
function update()
	video0:Clear(color.black)	--Upon update, clear screen (refresh)
	playerRecenter()			--Upon button press, recenter player
	playerSetSpeed()			--Upon button press, change players movement speed
	playerControl()				--Upon Joystick input, update players positition
	printPosition()				--Use LCD as serial to print player characteristics
	player_n_boundry()			--Upon intersection of player and boundry, do...
	drawBoundry()				--Draw boarder sprite :: should go last, after all changes to var's
	drawPlayer()				--Draw player sprite
	detectBoundry()				--Upon player to boundry proximity, turn on or off LED
--Main
end

--] Reset the Player object to center of the screen [--
function playerRecenter()	-- (playerXpos,playerYpos) :: [btn0]
	--Buttons Led is enabled for 1 tick on every press or depress
	if btn0.ButtonDown == false and btn0.ButtonUp == false then
		btn0.LedState = false 
	elseif btn0.ButtonUp == true then btn0.LedState = true
	else 
		playerXpos = center
		playerYpos = playerXpos
		btn0.LedState = true
	end
--No Return
end

--] Hardcoded control for Players speed of movement (acceleration) :: 4 settings [--
function playerSetSpeed()	-- (playerSpeed) :: [btn1,ledS0]
	local numSettings: number = 4
	local btnCount: number = playerSpeed
	if btn1.ButtonDown == true then btnCount = btnCount + 1 end
	if btnCount >= numSettings + 1 then btnCount = 1 end
	--Clear(Reset) all Leds in strip
	for i=1,numSettings do
		ledS0.States[i] = false
	end
	--Enable Leds to signal the speed setting of player object
	for i=1,btnCount do
		ledS0.States[i] = true
	end
	playerSpeed = btnCount	--update players object speed
--No Return
end

--]	Control 360 degrees of movement for the Player object [--
function playerControl()	-- (playerXpos,playerYpos,playerSpeed) :: [stick0] :: {getAngle(),getMagnitude()}
	--Get current joystick coordinates direction(angle) and speed(magnitude)
	local direction: number = getAngle(false, stick0.X, stick0.Y)	--the angle between the hypotenous of X,Y
	local speed: number = getMagnitude(stick0.X,stick0.Y)	--the hypotenous of the joysticks coordinates
	local scale: number = playerSpeed 						--velocity(speed) scaler
	local hypNew: number = scale * speed / 100				--new hypotenous
	local xNew: number = math.cos(direction)*hypNew			--new x coordinate (rect coordinates)
	local yNew: number = math.sin(direction)*hypNew			--new y coordinate (rect coordinates)
	--Update players postion given joysticks angle and value of X,Y coordinates
	playerXpos = playerXpos + xNew
	playerYpos = playerYpos - yNew
--No Return
end

--]	Print the Player objects and Joystick coordinate characteristics onto the LCD [--
function printPosition()	-- (playerXpos,playerYpos) :: [stick0,display0] :: {getAngle(),getMagnitude()}
	--Each formated to print on a single LCD line
	local formatMagnitude: string = string.format("mag = %6.2f    ", getMagnitude(stick0.X,stick0.Y))
	local formatAngle: string = string.format("angle = %6.2f  ", getAngle(true,stick0.X,stick0.Y)) --degrees
	local formatCoordinates: string = string.format("x,y = %+3i,%+3i", playerXpos, playerYpos)
	--Print the players X,Y screen position onto LCD :: in respect to the top left of the sprite image
		--display0.Text = formatCoordinates		--comment in/out (optional)
	--Print the Joysticks X,Y calculations onto LCD :: angle, magnitude
	display0.Text = formatMagnitude .. formatAngle
--No Return
end

--]	Determine what happens when Player object meets the Boundry :: 3 example methods to handle this [--
function player_n_boundry()		-- (maxPixel,playerPixels,playerXpos,playerYpos)
	--Method 0: No Bounds then comment out both Method 1 and 2 (Ctrl+Alt+/)
	--[[--Method 1: Bounds that roll-over the player object to other side when half of player crosses
		local minVal, maxVal = 1 - playerPixels / 2, maxPixel - playerPixels - 1
		if playerXpos <= minVal then playerXpos = maxVal end
		if playerXpos > maxVal then playerXpos = minVal end
		if playerYpos <= minVal then playerYpos = maxVal end
		if playerYpos > maxVal then playerYpos = minVal end--]]
	--Method 2: Bounds that do not allow movement across boarder
	local minVal: number, maxVal: number = 1, maxPixel - playerPixels - 1
	if playerXpos <= minVal then playerXpos = minVal end
	if playerXpos > maxVal then playerXpos = maxVal end
	if playerYpos <= minVal then playerYpos = minVal end
	if playerYpos > maxVal then playerYpos = maxVal end	
--No Return
end

--] Draw the Boarder sprite onto scree [--
function drawBoundry()		-- <border> 
	video0:DrawSprite(vec2(0,0), border, 0, 0, color.white, color.clear)
--No Return
end

--]	Static PlaceHolder for any animation [--
function drawPlayer()		-- (playerXpos,playerYpos) :: <player>
	video0:DrawSprite(vec2(playerXpos,playerYpos), player, 0, 0, color.white, color.clear)
--No Return
end

--] Proximity Detector between player and boundry for LED [--
function detectBoundry()	-- (playerPixels,maxPixel,playerXpos,playerYpos) :: [led0]
	local minVal: number, maxVal: number = playerPixels / 2, maxPixel - 3 * playerPixels / 2 - 1
	--Detect when player is within half of its pixel size away from the boundry
	if playerXpos <= minVal then led0.State = true
	elseif playerXpos > maxVal then led0.State = true
	elseif playerYpos <= minVal then led0.State = true
	elseif playerYpos > maxVal then led0.State = true
    else led0.State = false end
--No Return
end

--Utility Functions---------------------------------------------------------------------------------------------------------------

--] Get the angle in radians or degrees given x,y coordinates [--
function getAngle(unit:boolean, xVal:number, yVal:number)
	--Initialize parameters
	local unit: boolean = unit or false 	--false-->radians, true-->degrees
	local xVal: number = xVal or 0
	local yVal: number = yVal or 0
	--Local variables
	local piR: number, piD: number = math.pi, 180
	local rad2deg: number = piD / piR
	local angleRad: number = math.atan(yVal/xVal)
	local angleDeg: number = math.atan(yVal/xVal)*rad2deg
	local halfCircle: number = unit and piD or piR
	local angle: number = unit and angleDeg or angleRad
	--Account for output of atan()
	if xVal < 0 then angle = angle + halfCircle end
	if yVal < 0 and xVal >= 0 then angle = angle + halfCircle * 2 end
	if xVal == 0 and yVal == 0 then angle = 0 end
--Returns number
	return angle 
end

--] Get the magnitude of a given x,y coordinate pair [--
function getMagnitude(xVal:number, yVal:number)
	--Initialize parameters
	local xVal: number = xVal or 0
	local yVal: number = yVal or 0
	--Local variables
	local mag: number = math.sqrt(xVal^2 + yVal^2)
--Returns number
	return mag
end
