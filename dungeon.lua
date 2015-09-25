-- Simplistic random dungeon generator lua script

dungeon={
	
	Generate = function(complexity, gridSizeX, gridSizeZ)
		backlog_fontsize(-5)
		backlog_fontrowspacing(-5)
		backlog_clear()
	
		local scalingMat = matrix.Scale(Vector(10,10,10))
		local dungeonStartPos = Vector(0,0,0)
		
		local grid = {}
		for i = 1,gridSizeZ do
			grid[i] = {}
			for j = 1,gridSizeX do 
				grid[i][j] = '.'
			end
		end
		
		-- returns:
		-- 		bool 	isInsideGrid	: is it an indexable position?
		--		int		cellID_i		: first index position as grid[i][j]
		--		int		cellID_j		: second index position as grid[i][j]
		local function WorldToGrid(pos)
			local startX = gridSizeX / 2
			local startZ = gridSizeZ / 2
			local isInsideGrid = false
			local cellID_i = 0 
			local cellID_j = 0
			
			cellID_i = math.floor(startZ - pos.GetZ())
			cellID_j = math.floor(startX + pos.GetX())
			
			if cellID_i < gridSizeZ and cellID_i > 0 and cellID_j < gridSizeX and cellID_i > 0 then
				isInsideGrid = true
			end
			
			return isInsideGrid, cellID_i, cellID_j
		end
		
		-- returns:
		--		bool isValid	: Can place physical segment
		local function MarkCellsAsOccupied(pos, area, symbol)
			local area_nX = area.GetX()
			local area_pX = area.GetY()
			local area_nZ = area.GetZ()
			local area_pZ = area.GetW()
			local stepZ = 1
			local stepX = 1
			if area_nZ > area_pZ then
				stepZ = -1
				area_nZ = area_nZ - 1
			else
				area_pZ = area_pZ - 1
			end
			if area_nX > area_pX then
				stepX = -1
				area_nX = area_nX - 1
			else
				area_pX = area_pX - 1
			end
			
			-- check if the piece is inside the grid and cancel if it is not
			-- also check for any overlaps and cancel if an overlap occurs
			for z=area_nZ,area_pZ,stepZ do
				for x=area_nX,area_pX,stepX do
					isValid, i, j = WorldToGrid(pos:Add(Vector(x,0,z)))
					if isValid == false then
						return false
					elseif grid[i][j] ~= '.' then
						return false
					end
				end
			end
			
			-- if the cells are available, mark them as occupied 
			for z=area_nZ,area_pZ,stepZ do
				for x=area_nX,area_pX,stepX do
					isValid, i, j = WorldToGrid(pos:Add(Vector(x,0,z)))
					grid[i][j] = symbol
				end
			end
			
			return true
		end
		
		
		--MarkCellsAsOccupied(Vector(0,0,0),Vector(0,3,0,2),'A')
		
		LoadModel("dungeon/start/","start","segment0",scalingMat)
		LoadWorldInfo("dungeon/start/","start.wiw")
		MarkCellsAsOccupied(dungeonStartPos, Vector(-1,1,0,-2), 'S')
		
		-- Create physical dungeon segments
		local function GenerateDungeon(i, count, pos, rotY)
			local rotMat = matrix.RotationY(rotY)
			local transformMat = matrix.Multiply( rotMat, matrix.Multiply( matrix.Translation(pos), scalingMat ) )
			if (i >= count) then
				LoadModel("dungeon/end/","end","segment"..i,transformMat)
				MarkCellsAsOccupied(pos,Vector(-1,1,0,2).Transform(rotMat),'E')
				return;
			end
			local select = math.random(0,100)
			if( select < 30 ) then --room
				if MarkCellsAsOccupied(pos,Vector(-4,4,0,8).Transform(rotMat),'R') then
					LoadModel("dungeon/room/","room","segment"..i,transformMat )
					-- right
					GenerateDungeon(i+1,count,pos:Add(Vector(4,0,4)),rotY + 0.5*3.1415)
					-- left
					GenerateDungeon(i+1,count,pos:Add(Vector(-4,0,4)),rotY - 0.5*3.1415)
					-- straight
					GenerateDungeon(i+1,count,pos:Add(Vector(0,0,8).Transform(rotMat)),rotY)
				else
					GenerateDungeon(count,count,pos,rotY) --end
				end
			-- elseif( select < 30 ) then --turn
			-- 	local select2 = math.random(0,1)
			-- 	if(select2 == 0) then --left
			-- 		LoadModel("dungeon/turnleft/","turnleft","segment"..i,transformMat)
			-- 		GenerateDungeon(i+1,count,pos:Add(Vector(-2,0,2).Transform(rotMat)),rotY-0.5*3.1415)
			-- 	else --right
			-- 		LoadModel("dungeon/turnright/","turnright","segment"..i,transformMat)
			-- 		GenerateDungeon(i+1,count,pos:Add(Vector(2,0,2).Transform(rotMat)),rotY+0.5*3.1415)
			-- 	end
			-- elseif( select < 40 ) then --small room left
			-- 	if MarkCellsAsOccupied(pos:Add(Vector(-3).Transform(rotMat)),Vector(3,0,3).Transform(rotMat),'r') then
			-- 		LoadModel("dungeon/smallroomleft/","smallroomleft","segment"..i,transformMat )
			-- 		GenerateDungeon(i+1,count,pos:Add(Vector(-5,0,5).Transform(rotMat)),rotY-0.5*3.1415)
			-- 	else
			-- 		GenerateDungeon(count,count,pos,rotY) --end
			-- 	end
			-- elseif( select < 55 ) then --odd corridor
			-- 	if MarkCellsAsOccupied(pos,Vector(2,0,4).Transform(rotMat),'O') then
			-- 		LoadModel("dungeon/oddcorridor/","oddcorridor","segment"..i,transformMat )
			-- 		GenerateDungeon(i+1,count,pos:Add(Vector(2,0,8).Transform(rotMat)),rotY)
			-- 	else
			-- 		GenerateDungeon(count,count,pos,rotY) --end
			-- 	end
			-- elseif( select < 60 ) then --up corridor
			-- 	if MarkCellsAsOccupied(pos,Vector(1,0,3).Transform(rotMat),'U') then
			-- 		LoadModel("dungeon/upcorridor/","upcorridor","segment"..i,transformMat )
			-- 		GenerateDungeon(i+1,count,pos:Add(Vector(0,2,6).Transform(rotMat)),rotY)
			-- 	else
			-- 		GenerateDungeon(count,count,pos,rotY) --end
			-- 	end
			else --corridor
				if MarkCellsAsOccupied(pos,Vector(-1,1,0,6).Transform(rotMat),'C') then
					LoadModel("dungeon/corridor/","corridor","segment"..i,transformMat )
					GenerateDungeon(i+1,count,pos:Add(Vector(0,0,6).Transform(rotMat)),rotY)
				else
					GenerateDungeon(count,count,pos,rotY) --end
				end
			end
		end
		
		GenerateDungeon(0,complexity,dungeonStartPos,0)
		
		for i=1,gridSizeZ do
			local str = ""
			for j=1,gridSizeX do 
				str = str..grid[i][j]
			end
			backlog_post(str)
		end
	
	end,

}