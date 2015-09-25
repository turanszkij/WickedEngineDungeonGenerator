-- Third person camera controller lua script
-- It references a player (targetPlayer)

tpCamera = {
	camera = GetCamera(),
	targetPlayer = nil,
	
	Reset = function(self)
		self.targetPlayer = nil
		self.camera.ClearTransform()
	end,
	Follow = function(self, targetPlayer)
		self.targetPlayer = targetPlayer
		self.camera.Rotate(Vector(0.1))
		self.camera.Translate(Vector(2,7,-12))
		self.camera.AttachTo(targetPlayer.target)
	end,
	UnFollow = function(self)
		self.targetPlayer = nil
		self.camera.Detach()
	end,
	
	Update = function(self)
		--camera collision
		if(self.targetPlayer ~= nil) then
			local camRestDistance = 12.0
			local camTargetDiff = vector.Subtract(self.targetPlayer.target.GetPosition(), self.camera.GetPosition())
			local camTargetDistance = camTargetDiff:Length()
			if(camTargetDistance < camRestDistance) then
				self.camera.Translate( Vector(0,0,-0.14) )
			end
			local camRay = Ray(self.camera.GetPosition(),camTargetDiff:Normalize())
			local camCollObj,camCollPos,camCollNor = Pick(camRay)
			if(camCollObj:IsValid() and camCollObj:GetName() ~= self.targetPlayer.meshname) then
				local camCollDiff = vector.Subtract(camCollPos, self.camera.GetPosition())
				local camCollDistance = camCollDiff:Length()
				if(camCollDistance < camTargetDistance) then
					self.camera.Translate(Vector(0,0,camCollDistance))
				end
			end
		end
	end,
}