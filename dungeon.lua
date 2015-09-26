-- Simplistic random dungeon generator lua script

dungeon={
	
	Generate = function(complexity)
		-- backlog_fontsize(-5)
		-- backlog_fontrowspacing(-5)
		-- backlog_clear()
	
		local scalingMat = matrix.Scale(Vector(10,10,10))
		local dungeonStartPos = Vector(0,0,0)
		
		-- array keeps track of occupied segment spaces
		local occupied = {}
		
		-- summary:
		--		This function manages physical space so that no intersecting segments are placed
		-- params:
		--		Vector pos		: enter position (pivot)
		--		Vector area		: rectangular area description (left x position, right x, near z position, far z position)
		-- returns:
		--		bool isValid	: Can place physical segment
		local function MarkCellsAsOccupied(pos, area)
			local area_nX = math.min(area.GetX(),area.GetY())
			local area_pX = math.max(area.GetX(),area.GetY())
			local area_nZ = math.min(area.GetZ(),area.GetW())
			local area_pZ = math.max(area.GetZ(),area.GetW())
			
			-- check if the piece is available (its coordinates are not already in the occupied array)
			-- if it is not, then exit early
			for z=area_nZ,area_pZ do
				if z ~= 0 then
					for x=area_nX,area_pX do
						if x~=0 then
							local store_pos = pos:Add(Vector(x,0,z))
							for k, v in pairs(occupied) do
								if v[1] == math.floor(store_pos.GetX()) and v[2] == math.floor(store_pos.GetZ()) then
									return false;
								end
							end
						end
					end
				end
			end
			
			-- if the control is here, the piece can be placed, but we need to mark the area cells (add them to the occupied array)
			for z=area_nZ,area_pZ do
				if z ~= 0 then
					for x=area_nX,area_pX do
						if x ~= 0 then
							local store_pos = pos:Add(Vector(x,0,z))
							table.insert(occupied,{math.floor(store_pos.GetX()),math.floor(store_pos.GetZ())})
						end
					end
				end
			end
			
			return true
		end
		
		
		-- Place the start piece of the dungeon
		LoadModel("dungeon/start/","start","segment0",scalingMat)
		LoadWorldInfo("dungeon/start/","start.wiw")
		MarkCellsAsOccupied(dungeonStartPos, Vector(-1,1,0,-2))
		
		-- Create physical dungeon segments recursively
		local function GenerateDungeon(i, count, pos, rotY)
			local rotMat = matrix.RotationY(rotY)
			local transformMat = matrix.Multiply( rotMat, matrix.Multiply( matrix.Translation(pos), scalingMat ) )
			if (i >= count) then
				LoadModel("dungeon/end/","end","segment"..i,transformMat)
				MarkCellsAsOccupied(pos,Vector(-1,1,0,2).Transform(rotMat))
				return;
			end
			local select = math.random(0,100)
			if( select < 15 ) then --room
				if MarkCellsAsOccupied(pos,Vector(-4,4,0,8).Transform(rotMat)) then
					LoadModel("dungeon/room/","room","segment"..i,transformMat )
					-- right
					GenerateDungeon(i+1,count,pos:Add(Vector(4,0,4)),rotY + 0.5*3.1415)
					-- left
					GenerateDungeon(i+1,count,pos:Add(Vector(-4,0,4)),rotY - 0.5*3.1415)
					-- straight
					GenerateDungeon(i+1,count,pos:Add(Vector(0,0,8).Transform(rotMat)),rotY)
				else
					GenerateDungeon(i+1,count,pos,rotY)
				end
			elseif( select < 30 ) then --turn
				local select2 = math.random(0,1)
				if(select2 == 0) then --left
					if MarkCellsAsOccupied(pos,Vector(-2,1,0,3).Transform(rotMat)) then
						LoadModel("dungeon/turnleft/","turnleft","segment"..i,transformMat)
						GenerateDungeon(i+1,count,pos:Add(Vector(-2,0,2).Transform(rotMat)),rotY-0.5*3.1415)
					else
						GenerateDungeon(i+1,count,pos,rotY)
					end
				else --right
					if MarkCellsAsOccupied(pos,Vector(-1,2,0,3).Transform(rotMat)) then
						LoadModel("dungeon/turnright/","turnright","segment"..i,transformMat)
						GenerateDungeon(i+1,count,pos:Add(Vector(2,0,2).Transform(rotMat)),rotY+0.5*3.1415)
					else
						GenerateDungeon(i+1,count,pos,rotY)
					end
				end
			elseif( select < 40 ) then --small room left
				if MarkCellsAsOccupied(pos,Vector(-5,1,0,6).Transform(rotMat)) then
					LoadModel("dungeon/smallroomleft/","smallroomleft","segment"..i,transformMat )
					GenerateDungeon(i+1,count,pos:Add(Vector(-5,0,5).Transform(rotMat)),rotY-0.5*3.1415)
				else
					GenerateDungeon(i+1,count,pos,rotY)
				end
			elseif( select < 50 ) then --odd corridor
				if MarkCellsAsOccupied(pos,Vector(-1,3,0,8).Transform(rotMat)) then
					LoadModel("dungeon/oddcorridor/","oddcorridor","segment"..i,transformMat )
					GenerateDungeon(i+1,count,pos:Add(Vector(2,0,8).Transform(rotMat)),rotY)
				else
					GenerateDungeon(i+1,count,pos,rotY)
				end
			elseif( select < 60 ) then --up corridor
				if MarkCellsAsOccupied(pos,Vector(-1,1,0,6).Transform(rotMat)) then
					LoadModel("dungeon/upcorridor/","upcorridor","segment"..i,transformMat )
					GenerateDungeon(i+1,count,pos:Add(Vector(0,2,6).Transform(rotMat)),rotY)
				else
					GenerateDungeon(i+1,count,pos,rotY)
				end
			else --corridor
				if MarkCellsAsOccupied(pos,Vector(-1,1,0,6).Transform(rotMat)) then
					LoadModel("dungeon/corridor/","corridor","segment"..i,transformMat )
					GenerateDungeon(i+1,count,pos:Add(Vector(0,0,6).Transform(rotMat)),rotY)
				else
					GenerateDungeon(i+1,count,pos,rotY)
				end
			end
		end
		
		-- Call recursive generator function
		GenerateDungeon(0,complexity,dungeonStartPos,0)
		
		
		-- for k, v in pairs(occupied) do
		-- 	backlog_post(k, ": ", v[1], ",", v[2])
		-- end
	
	end,

}