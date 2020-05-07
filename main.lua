local AdvTiledLoader = require("AdvTiledLoader.Loader")
require("camera")

function love.load()
	joystickRdy = love.joystick.open(1)

	love.graphics.setBackgroundColor( 220, 220, 255 )
	AdvTiledLoader.path = "maps/"
	map = AdvTiledLoader.load("map.tmx")
	index = "1"
	map:setDrawRange(0, 0, map.width * map.tileWidth, map.height * map.tileHeight)

	camera:setBounds(0, 0, map.width * map.tileWidth - love.graphics.getWidth(), map.height * map.tileHeight - love.graphics.getHeight())
	world =		{
				gravity = 1800,
				ground = 512,
				}

	WALK = 300
	RUN = 500
	alpha = 255
	JUMPBOOST = 150
	WALLJUMP = 600
	WALLJUMP_DECREMENT = 40
	STICKSLOWDOWN = 1300

	WALLJUMP_VERT = -900
	JUMP_VERT = -800

	FLY_SPEED = 1000
	-- end constants

		--Defintion des points
	points = 0


	player =	{
				x = 256,
				y = 256,
				x_vel = 0,
				y_vel = 0,
				jump_vel = JUMP_VERT,
				wall_jump_vel = WALLJUMP_VERT,
				speed = WALK,
				speed_status = "walk",
				flySpeed = FLY_SPEED,
				y_stick = 0,
				side_stick = 0,
				horizontal_jump_vel = 0,
				state = "",
				h = 32,
				w = 32,
				standing = false,
				bJumpLetGo = true,
				}

	function player:jump()
		if self.standing and self.bJumpLetGo then
			self.y_vel = self.jump_vel
			self.speed = self.speed + JUMPBOOST
			self.standing = false
			self.bJumpLetGo = false
		elseif not(self.side_stick == 0) and self.bJumpLetGo then
			self.y_vel = self.wall_jump_vel
			if self.speed_status == "run" then
				self.speed = RUN + JUMPBOOST
			else
				self.speed = WALK + JUMPBOOST
			end
			if self.side_stick == -1 then
				self.horizontal_jump_vel = WALLJUMP
			elseif self.side_stick == 1 then
				self.horizontal_jump_vel = -1*WALLJUMP
			end
			self.standing = false
			self.bJumpLetGo = false
		end
	end

	function player:jumpLetGo()
		if self.standing or not(self.side_stick == 0) then
			self.bJumpLetGo = true
		end
	end

	function player:right()
		if self.y_stick == 0 then
			self.x_vel = self.speed
		end
	end

	function player:left()
		if self.y_stick == 0 then
			self.x_vel = -1*self.speed
		end
	end

	function player:stop()
		self.x_vel = 0
	end

	function player:walk()
		if self.standing then
			self.speed = WALK
		end
		self.speed_status = "walk"
	end

	function player:run()
		if self.standing then
			self.speed = RUN
		end
		self.speed_status = "run"
	end

	function player:collide(event)
		if event == "floor" then
			self.y_vel = 0
			self.standing = true
		end
		if event == "ceiling" then
			self.y_vel = 0
		end
	end

	function player:update(dt)
		local halfX = self.w / 2
		local halfY = self.h / 2

		self.y_vel = self.y_vel + ((world.gravity - self.y_stick) * dt)

		if self.standing then
			self.horizontal_jump_vel = 0
		elseif self.horizontal_jump_vel > 0 then
			if self.x_vel > 0 then
				self.horizontal_jump_vel = 0
			else
				self.horizontal_jump_vel = self.horizontal_jump_vel - WALLJUMP_DECREMENT
			end
		elseif self.horizontal_jump_vel < 0 then
			if self.x_vel < 0 then
				self.horizontal_jump_vel = 0
			else
				self.horizontal_jump_vel = self.horizontal_jump_vel + WALLJUMP_DECREMENT
			end
		end

		self.x_vel = math.clamp(self.x_vel, -self.speed, self.speed)
		self.y_vel = math.clamp(self.y_vel, -self.flySpeed, self.flySpeed)

		local nextY = self.y + (self.y_vel*dt)
		local nextX
		if self.horizontal_jump_vel == 0 then
			nextX = self.x + (self.x_vel*dt)
		else
			nextX = self.x + (self.horizontal_jump_vel*dt)
		end

		if self.y_vel < 0 then
			if not (self:isColliding(map,self.x-halfX+1, nextY - halfY))
				and not (self:isColliding(map,self.x + halfX - 1, nextY - halfY)) then
				self.y = nextY
				self.standing = false
			else
				self.y = nextY + map.tileHeight - ((nextY - halfY) % map.tileHeight)
				self:collide("ceiling")
			end
			self.y_stick = 0
		elseif self.y_vel > 0 then
			if not (self:isColliding(map, self.x-halfX+1, nextY + halfY))
				and not (self:isColliding(map, self.x+halfX-1,nextY+halfY)) then
				self.y = nextY
				self.standing = false
				if (self:isColliding(map, self.x + halfX, self.y)) then
					self.side_stick = 1
					self.y_stick = STICKSLOWDOWN
				elseif (self:isColliding(map, self.x - halfX-1, self.y)) then
					self.side_stick = -1
					self.y_stick = STICKSLOWDOWN
				else
					self.side_stick = 0
					self.y_stick = 0
				end
			else
				self.y = nextY - ((nextY + halfY) % map.tileHeight)
				self:collide("floor")
				self.side_stick = 0
				self.y_stick = 0
			end
		end

		if self.x_vel > 0 or nextX > self.x then
			if not (self:isColliding(map, nextX + halfX, self.y))
				and not (self:isColliding(map, nextX + halfX, self.y + halfY - 1)) then
				self.x = nextX
			else
				self.x = nextX - ((nextX + halfX) % map.tileWidth)
			end
		elseif self.x_vel < 0 or nextX < self.x then
			if not (self:isColliding(map, nextX - halfX, self.y))
				and not (self:isColliding(map, nextX - halfX, self.y + halfY - 1)) then
				self.x = nextX
			else
				self.x = nextX + map.tileWidth - ((nextX - halfX) % map.tileWidth)
			end
		end

		self.state = self:getState()
	end

	function player:isColliding(map, x, y)
		local layer = map.tl["Ground"]
		local tileX, tileY = math.floor(x / map.tileWidth), math.floor(y / map.tileHeight)
		local tile = layer.tileData(tileX,tileY)
		return not(tile == nil)
	end

	function player:getState()
		local tempState = ""
		if self.standing then
			if self.x_vel > 0 then
				tempState = "right"
			elseif self.x_vel < 0 then
				tempState = "left"
			else
				tempState = "stand"
			end
		end

		if self.y_vel > 0 then
			tempState = "fall"
		elseif self.x_vel < 0 then
			tempState = "jump"
		end

		return tempState
	end
end

function initplayer()
	player.x = 256
	player.y = 1200
end

function love.draw()
	camera:set()
	love.graphics.setColor(0,0,100)
	love.graphics.rectangle("fill", player.x - player.w/2, player.y - player.h/2, player.w, player.h)
  print(player.x, player.y)
  if player.x == 2512 then
    if player.y == 240 then
      endlevel()
    end
  end
	love.graphics.setColor(255,255,255)
	map:draw()
	camera:unset()
  print(index)
  givepoint()
  love.graphics.setNewFont(35)
  love.graphics.setColor(255,0,0,255)
  love.graphics.printf(points, 100, 100, 150)
  level = "Niveau"
  print(points)
  love.graphics.printf(level, 500, 100, 150)
  love.graphics.printf(index, 650, 100, 150)
  print(points)
end

function givepoint()
	if player.x == 1840 then
    if player.y == 528 then
      if index == "1" and points == 1 then
	  point = 1
	  else
	  pointsplus()
	  end
	end
	end
	if player.x == 1360 then
    if player.y == 752 then
      if index == "2" and points == 2 then
	  point = 2
	  else
	  pointsplus()
	  end
	end
	end
end

function pointsplus()
	points = points + 1
	print(points)
end

function endlevel()
	print(index)
	if index == "1" and points == 1 then
		index = "2"
		map = AdvTiledLoader.load("2.tmx")
		initplayer()
	elseif index == "2" and point == 2 then
		index = "3"
		map = AdvTiledLoader.load("3.tmx")
		initplayer()
	end
end

function love.joystickpressed(joystick, button)
   print(joystick, button)
end

function joystickControls()
	--player controls for moving left or right
	if love.joystick.getAxis(1,1) == 1 then
		player:right()
	elseif love.joystick.getAxis(1,1) == -1 then
		player:left()
	else
		player:stop()
	end

	--player controls for walking/running
	if love.joystick.isDown(1,3) then
		player:run()
	else
		player:walk()
	end

	--player controls for jumping
	if love.joystick.isDown(1,1) then
		player:jump()
	else
		player:jumpLetGo()
	end

end


function keyboardControls()
	--player controls for moving left or right
	if love.keyboard.isDown("left") then
		player:left()
	elseif love.keyboard.isDown("right") then
		player:right()
	else
		player:stop()
	end

	--player controls for walking/running
	if love.keyboard.isDown("lshift") then
		player:run()
	else
		player:walk()
	end

	--player controls for jumping
	if love.keyboard.isDown(" ") then
		player:jump()
	else
		player:jumpLetGo()
	end
end

function love.update(dt)
	if dt > 0.05 then
		dt = 0.05
	end
	alpha = alpha - (dt * (255 / 3)) -- so it takes 3 seconds to remove all the alpha
	if alpha < 0 then alpha = 0 end -- to ensure that a 0 is the lowest value we get
	if( joystickRdy ) then
		joystickControls()
	else
		keyboardControls()
	end

	player:update(dt)

	camera:setPosition( player.x - (love.graphics.getWidth()/2), player.y - (love.graphics.getHeight()/2))
end