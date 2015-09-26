-- Lua Wicked Engine Game script


-- basic engine setup
local print = backlog_post
backlog_fontsize(-5)
backlog_fontrowspacing(-2)
local sleep = waitSeconds

local envMapFileName = "dungeon/env.dds"
local colorGradingFileName = "dungeon/colorGrading.dds"

HairParticleSettings(20,50,200)
SetDirectionalLightShadowProps(1024,2)
SetPointLightShadowProps(3,512)
SetSpotLightShadowProps(3,512)

local gamecomponent = DeferredRenderableComponent()
gamecomponent.Initialize()
gamecomponent.SetReflectionsEnabled(true)
gamecomponent.SetSSREnabled(false)
gamecomponent.SetShadowsEnabled(true)
gamecomponent.SetSSSEnabled(false)
gamecomponent.SetMotionBlurEnabled(true)
gamecomponent.SetLightShaftsEnabled(false)
gamecomponent.SetLensFlareEnabled(false)
gamecomponent.SetDepthOfFieldEnabled(false)
gamecomponent.SetDepthOfFieldFocus(10)
gamecomponent.SetDepthOfFieldStrength(1.5)
gamecomponent.SetSSAOEnabled(false)
gamecomponent.SetFXAAEnabled(false)
gamecomponent.GetContent().Add(envMapFileName)
gamecomponent.GetContent().Add(colorGradingFileName)
main.SetActiveComponent(gamecomponent)
main.SetInfoDisplay(true)
main.SetWatermarkDisplay(true)
main.SetFPSDisplay(true)
main.SetCPUDisplay(true)


-- include character and camera controllers
dofile("player.lua")
dofile("tpCamera.lua")
-- Player Controller (player.lua)
local player = playerController
-- Third Person camera (tpCamera.lua)
local camera = tpCamera
dungeon_complexity = 10

local function ResetGame()
	ClearWorld()
	player:Load("girl/","girl","player","omino_player","Armature_player","testa")
	player:Reset()
	--player:Reposition(Vector(0,4,-20))
	camera:Reset()
	camera:Follow(player)
	
	dofile("dungeon.lua")
	dungeon.Generate(dungeon_complexity)
	FinishLoading()
	
	SetEnvironmentMap(gamecomponent.GetContent().Get(envMapFileName))
	SetColorGrading(gamecomponent.GetContent().Get(colorGradingFileName))
end

-- Very simple game logic
local GameLogic = function()
	
	ResetGame()
	
	while true do
		
		while( backlog_isactive() ) do
			sleep(1)
		end
		
		if(input.Press(VK_RETURN)) then
			ResetGame()
		end
		if(input.Press(string.byte('R'))) then
			camera:Reset()
		end
		if(input.Press(string.byte('U'))) then
			camera:UnFollow()
		end
		if(input.Press(string.byte('F'))) then
			camera:Follow(player)
		end
		
		player:Input()
		
		camera:Update()
		
		player:Update()
		
		
		-- Wait for the engine to update the game
		update()
	end
end

-- Update
runProcess(GameLogic)



-- Draw Helpers
local DrawAxis = function(point,f)
	DrawLine(point,point:Add(Vector(f,0,0)),Vector(1,0,0,0))
	DrawLine(point,point:Add(Vector(0,f,0)),Vector(0,1,0,0))
	DrawLine(point,point:Add(Vector(0,0,f)),Vector(0,0,1,0))
end
local DrawAxisTransformed = function(point,f,transform)
	DrawLine(point,point:Add( Vector(f,0,0).Transform(transform) ),Vector(1,0,0,0))
	DrawLine(point,point:Add( Vector(0,f,0).Transform(transform) ),Vector(0,1,0,0))
	DrawLine(point,point:Add( Vector(0,0,f).Transform(transform) ),Vector(0,0,1,0))
end

-- Draw
runProcess(function()
	while true do
	
		while( backlog_isactive() ) do
			sleep(1)
		end
		
		-- Drawing additional render data (slow, only for debug purposes)
		
		--velocity
		DrawLine(player.skeleton.GetPosition():Add(Vector(0,4)),player.skeleton.GetPosition():Add(Vector(0,4)):Add(player.velocity))
		--face
		DrawLine(player.skeleton.GetPosition():Add(Vector(0,4)),player.skeleton.GetPosition():Add(Vector(0,4)):Add(player.face:Normalize()),Vector(1,0,0,1))
		--intersection
		DrawAxis(player.p,0.5)
		
		-- Wait for the engine to render the scene
		render()
	end
end)
