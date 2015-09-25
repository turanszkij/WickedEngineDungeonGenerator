-- Lua Thrid person camera and character controller script


local gravity = Vector(0,-0.076,0)

playerController = {
	path,name,id = "",
	skeleton = Armature(),
	head = Transform(),
	meshname = "",
	target = Transform(),
	face = Vector(0,0,1),
	velocity = Vector(),
	ray = Ray(),
	o,p,n = Vector(0,0,0), -- collision props with scene (object,position,normal)
	savedPointerPos = Vector(),
	moveSpeed = 0.28,
	
	states = {
		STAND = 0,
		TURN = 1,
		WALK = 2,
		JUMP = 3,
	},
	state = STAND,
	
	Load = function(self,path,name,id,meshname,armaturename,headname) 
		self.path = path
		self.name = name
		self.id = id
		LoadModel(path,name,id)
 		FinishLoading()
		self.meshname = meshname
		self.skeleton = GetArmature(armaturename)
		self.head = self.skeleton.GetBone(headname)
	end,
	
	Reset = function(self)
		self.skeleton.ClearTransform()
		self.target.ClearTransform()
		self.skeleton.Rotate(Vector(0,3.1415))
		self.skeleton.Scale(Vector(1.9,1.9,1.9))
		self.target.Translate(Vector(0,7))
		self.target.AttachTo(self.skeleton,1,0,1)
	end,
	Reposition = function(self, pos)
		self.skeleton.Translate(pos)
	end,
	MoveForward = function(self,f)
		local velocityPrev = self.velocity;
		self.velocity = self.face:Multiply(Vector(f,f,f))
		self.velocity.SetY(velocityPrev.GetY())
		self.ray = Ray(self.skeleton.GetPosition():Add(self.velocity):Add(Vector(0,4)),Vector(0,-1,0))
		self.o,self.p,self.n = Pick(self.ray)
		if(self.o:IsValid()) then
			self.state = self.states.WALK
		else
			self.state = self.states.STAND
			self.velocity = velocityPrev
		end
		
		--front block
		local ray2 = Ray(self.skeleton.GetPosition():Add(self.velocity:Normalize():Multiply(1.2)):Add(Vector(0,4)),self.velocity)
		local o2,p2,n2 = Pick(ray2)
		local dist = vector.Subtract(self.skeleton.GetPosition():Add(Vector(0,4)),p2):Length()
		if(o2:IsValid() and o2:GetName() ~= self.meshname and dist < 2.8) then
			-- run along wall instead of going through it
			local undesiredMotion = n2:Multiply(vector.Dot(self.velocity.Normalize(), n2.Normalize()))
			local desiredMotion = vector.Subtract(self.velocity, undesiredMotion)
			self.velocity = desiredMotion
			
		end
	end,
	Turn = function(self,f)
		self.skeleton.Rotate(Vector(0,f))
		self.face = self.face.Transform(matrix.RotationY(f))
		self.state = self.states.TURN
	end,
	Jump = function(self,f)
		self.velocity = self.velocity:Add(Vector(0,f,0))
		self.state = self.states.JUMP
	end,
	MoveDirection = function(self,dir,f)
		local savedPos = self.skeleton.GetPosition()
		self.target.Detach()
		self.skeleton.ClearTransform()
		self.face = dir:Normalize().Transform(self.target.GetMatrix())
		self.face.SetY(0)
		self.face = self.face.Normalize()
		self.skeleton.MatrixTransform(matrix.LookTo(Vector(),self.face):Inverse())
		self.skeleton.Scale(Vector(1.9,1.9,1.9))
		self.skeleton.Rotate(Vector(0,3.1415))
		self.skeleton.Translate(savedPos)
		self.skeleton.GetMatrix()
		self.target.AttachTo(self.skeleton)
		self:MoveForward(f)
	end,
	
	Input = function(self)
		
		if(self.state==self.states.STAND) then
			local lookDir = Vector()
			if(input.Down(VK_LEFT) or input.Down(string.byte('A'))) then
				lookDir = lookDir:Add( Vector(-1) )
			end
			if(input.Down(VK_RIGHT) or input.Down(string.byte('D'))) then
				lookDir = lookDir:Add( Vector(1) )
			end
		
			if(input.Down(VK_UP) or input.Down(string.byte('W'))) then
				lookDir = lookDir:Add( Vector(0,0,1) )
			end
			if(input.Down(VK_DOWN) or input.Down(string.byte('S'))) then
				lookDir = lookDir:Add( Vector(0,0,-1) )
			end
			
			if(lookDir:Length()>0) then
				if(input.Down(VK_LSHIFT)) then
					self:MoveDirection(lookDir,self.moveSpeed*3)
				else
					self:MoveDirection(lookDir,self.moveSpeed)
				end
			end
		
		end
		
		if( input.Press(string.byte('J'))  or input.Press(VK_SPACE) ) then
			self:Jump(1.3)
		end
		
		
		if(input.Down(VK_RBUTTON)) then
			local mousePosNew = input.GetPointer()
			local mouseDif = vector.Subtract(mousePosNew,self.savedPointerPos)
			mouseDif = mouseDif:Multiply(0.01)
			self.target.Rotate(Vector(mouseDif.GetY(),mouseDif.GetX()))
			self.face.SetY(0)
			self.face=self.face:Normalize()
			input.SetPointer(self.savedPointerPos)
		else
			self.savedPointerPos = input.GetPointer()
		end
	end,
	
	Update = function(self)
		
		if(self.state == self.states.STAND) then
			self.skeleton.PauseAction()
			self.state = self.states.STAND
		elseif(self.state == self.states.TURN) then
			self.skeleton.PlayAction()
			self.state = self.states.STAND
		elseif(self.state == self.states.WALK) then
			self.skeleton.PlayAction()
			self.state = self.states.STAND
		elseif(self.state == self.states.JUMP) then
			self.skeleton.PauseAction()
			self.state = self.states.STAND
		end
		
		local w,wp,wn = Pick(self.ray,PICK_WATER)
		if(w:IsValid() and self.velocity.Length()>0) then
			PutWaterRipple("images/ripple.png",wp)
		end
		
		
		self.velocity = vector.Add(self.velocity, gravity)
		self.skeleton.Translate(self.velocity)
		self.ray = Ray(self.skeleton.GetPosition():Add(Vector(0,4)),Vector(0,-1,0))
		local pPrev = self.p
		self.o,self.p,self.n = Pick(self.ray)
		if(not self.o:IsValid()) then
			self.p=pPrev
		end
		if(self.skeleton.GetPosition().GetY() < self.p.GetY() and self.velocity.GetY()<=0) then
			self.state = self.states.STAND
			self.skeleton.Translate(vector.Subtract(self.p,self.skeleton.GetPosition()))
			self.velocity=Vector()
		end
		
	end
}