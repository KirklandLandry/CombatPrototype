
-- http://stackoverflow.com/questions/667034/simple-physics-based-movement

-- TODO 
-- do some screenshake when you get hit 
-- circle circle collision resolution between player and enemy 
-- assasination move (last alter hit. target and dash at them)
-- dodge (invulnerability frames. give to player and also to enemy ai)

-- some simple enemy ai 
-- (keep their distance if your heath is high or their health is low)
-- (rushdown if their health is hight or your health is low)
-- (enter rage mode in alter state. rushdown and increased attack)

-- player health 


local mx, my
local centreX, centreY

local acceleration = 50
local friction = 0.1
local angle = 0

local player = {
x = 200,
y = 200,
vx = 0,
vy = 0,
radius = 20,
meleeTimer = nil,
meleeAngle = 0,
meleeActive = false,
meleeHitList = {}}

local playerProjectiles = {}
function newPlayerProjectile(_x,_y, _vx, _vy)
	return {
	x = _x, 
	y = _y, 
	vx = _vx, 
	vy = _vy,
	radius = 10}
end

local playerMissiles = {}
function newPlayerMissile(_x,_y, _vx, _vy, id)
	return {
	x = _x, 
	y = _y, 
	vx = _vx, 
	vy = _vy,
	targetID = id, 
	radius = 10, 
	missileTimer =  Timer:new(0.2, TimerModes.repeating),
	explosionTimer = Timer:new(1, TimerModes.single)}
end


local particles = {}
function addParticleExplosion(_x,_y)
	for i=1,300 do 
		local _vx = 0 
		while _vx == 0 do _vx = love.math.random(-400,400) end 
		local _vy = 0 
		while _vy == 0 do _vy = love.math.random(-400,400) end
		table.insert(particles, {
		x = _x, 
		y = _y, 
		vx = _vx,
		vy = _vy, 
		alpha = 255,
		radius = 3})
	end 
end 

local enemies = {}
local idCounter = 0
function newEnemy(posx, posy)
	idCounter = idCounter + 1 
	table.insert(enemies, {
	x = posx,
	y = posy,
	vx = 0,
	vy = 0,
	radius = 20,
	id = idCounter,
	maxHealth = 50,
	currentHealth = 50,
	alterMaxHealth = 30,
	alterCurrentHealth = 30,
	dodgeTimer = nil,
	dodgeRadius = 60,
	dodgeInvincibility = false
	})
end


function magnitude(x, y)
	return math.sqrt((x*x)+(y*y))
end 

function circleCircleCollision(x1,y1,r1, x2,y2,r2)
	return (x2-x1)^2 + (y1-y2)^2 <= (r1+r2)^2
end 

--[[function circleCircleResolution(a, b)
	
	-- vector from a to b
	local normalx = b.x - a.x
	local normaly = b.y - a.y
	local penetration = 0 
	
	-- the above failed, so we know the circles collided 
	local d = magnitude(normalx, normaly)
	
	if d ~= 0 then 
		-- the distance is the difference between radius and distance 
		penetration = (a.radius + b.radius) - d 	
		-- use vector from a to b divided by the magnitude of said vector as the collision normal
		normalx = normalx/d
		normaly = normaly/d
		return {state = true, x = normalx, y = normaly, p = penetration}
	else -- the circles are on top of each other  
		penetration = a.radius 
		normalx = 1 
		normaly = 0 
		return {state = true, x = normalx, y = normaly, p = penetration}
	end
end]]


function lineCircleIntersection(bulletX, bulletY, bulletVX, bulletVY, enemyX, enemyY, enemyRadius)
	-- get the distance from the bullet to the enemy 
	bulletToCircleX = enemyX - bulletX
	bulletToCircleY = enemyY - bulletY
	
	-- temp variables for the velocity vector
	local planeX = bulletVX
	local planeY = bulletVY
	
	-- project the vector of the distance from the bullet to the enemy 
	-- onto the bullet's velocity 
	local dot = (bulletToCircleX * planeX) + (bulletToCircleY * planeY)			
	local proj = dot / ((planeX*planeX) + (planeY*planeY))
	local projX = bulletX + (planeX * proj )
	local projY = bulletY + (planeY * proj )
	
	-- if the projected point is less than the enemies radius then the 
	-- bullet is going to hit the enemy 
	local dist = magnitude(enemyX - projX, enemyY - projY)
	
	if dist <= enemyRadius then return true else return false end 
end 

function circleWallCollision(x,y,radius,vx,vy)
	local result = {
	x = 0,
	y = 0,
	vx = 1,
	vy = 1
	}
	
	if x - radius < 0 then 
		result.x = -(x-radius)
		result.vx = - 0.5
	elseif x + radius > screenWidth then 
		result.x = screenWidth - (x + radius)
		result.vx = -0.5
	end 
	
	if y - radius < 0 then 
		result.y = -(y-radius)
		result.vy = -0.5
	elseif y + radius > screenHeight then 
		result.y = screenHeight - (y + radius)
		result.vy = -0.5
	end 
	return result 
end 



function love.focus(f)
  if not f then
    --print("LOST FOCUS")
	releaseAllInput()
  else
    --print("GAINED FOCUS")
  end
end



function loadGame()
	mx, my = love.mouse.getPosition()
	prevMx = mx 
	prevMy = my 

	centreX = screenWidth/2
	centreY = screenHeight/2
	
	newEnemy(400,400)
	
	love.mouse.setVisible(false)
end



local missilePrimed=false 
local nextMissileTargetId = nil 

function updateGame(dt)	
	mx, my = love.mouse.getPosition()
	
	
	if getKeyDown("g") then dt = 0.001 end 
	
	if getKeyPress("h") then newEnemy(love.math.random(10,screenWidth - 10), love.math.random(10,screenHeight - 10)) end 
	
	
	-- update player velocity start
	if getKeyDown("a") then 
		player.vx = player.vx - (acceleration * dt)
	end 
	if getKeyDown("d") then 
		player.vx = player.vx + (acceleration * dt)
	end 
	
	if getKeyDown("w") then 
		player.vy = player.vy - (acceleration * dt)
	end 
	if getKeyDown("s") then 
		player.vy = player.vy + (acceleration * dt)
	end 
	
	player.vx = player.vx - (friction * player.vx)
	player.vy = player.vy - (friction * player.vy)
	
	player.x = player.x + player.vx
	player.y = player.y + player.vy
	-- update player velocity end
		
	
	-- player wall collision start 
	local collisionResult = circleWallCollision(player.x, player.y, player.radius, player.vx, player.vy)
	player.x = player.x + collisionResult.x 
	player.y = player.y + collisionResult.y
	player.vx = player.vx * collisionResult.vx 
	player.vy = player.vy * collisionResult.vy
	-- player wall collision end 
	
	
	--[[local rawAngleToMouse = math.atan2(mx - player.x, my - player.y)
	angle = rawAngleToMouse * (180/math.pi)
	if angle < 0 then angle = 360 - (-angle) end]]
	
	
	-- add playerProjectiles start 
	if lMouseDown then
		lMouseDown = false
		local mag = math.sqrt(math.pow(mx - player.x, 2) + math.pow(my - player.y, 2))
		local xv = ((mx - player.x)/mag) * 800
		local xy = ((my - player.y)/mag) * 800
		table.insert(playerProjectiles, newPlayerProjectile(player.x, player.y, xv, xy))
	end
	-- add playerProjectiles end 
	
	
	
	-- add player missile start
	if mMouseDown then 
		mMouseDown = false
		if missilePrimed then 
			missilePrimed = false 
			table.insert(playerMissiles, newPlayerMissile(player.x, player.y, 0, 1000, nextMissileTargetId))
		else 
			for i=#enemies,1,-1 do 
				local mag = math.sqrt(math.pow(mx - enemies[i].x, 2) + math.pow(my - enemies[i].y, 2))
				if mag <= enemies[i].radius then 
					nextMissileTargetId = enemies[i].id
					missilePrimed = true 
					break
				end 
			end 
		end 
	end 
	-- add player missile end 
	
	
	
	-- melee start 
	if rMouseDown and not player.meleeActive then 
		rMouseDown = false
		player.meleeTimer = Timer:new(0.12, TimerModes.single)
		player.meleeActive = true 
		player.meleeHitList = {}
	end
	
	if player.meleeActive and player.meleeTimer:isComplete(dt) then 
		player.meleeActive = false 
	end
	-- melee end 
	
	
	-- udpate playerProjectiles start 
	for i=#playerProjectiles,1,-1 do 
		-- move playerProjectiles
		playerProjectiles[i].x = playerProjectiles[i].x + (playerProjectiles[i].vx * dt)
		playerProjectiles[i].y = playerProjectiles[i].y + (playerProjectiles[i].vy * dt)
		--remove out of bounds playerProjectiles 
		if  playerProjectiles[i].x - playerProjectiles[i].radius > screenWidth or playerProjectiles[i].x + playerProjectiles[i].radius < 0 or 
			playerProjectiles[i].y - playerProjectiles[i].radius > screenHeight or playerProjectiles[i].y + playerProjectiles[i].radius < 0 then  			
			table.remove(playerProjectiles, i)
		end
	end
	-- update playerProjectiles end 
	
	
	
	-- udpate playerMissiles start 
	for i=#playerMissiles,1,-1 do 
	
		if playerMissiles[i].explosionTimer:isComplete(dt) then 
			addParticleExplosion(playerMissiles[i].x, playerMissiles[i].y)
			table.remove(playerMissiles, i)
		else 	
			-- get target position 
			local targetX = 0 
			local targetY = 0 
			for j=#enemies,1,-1 do  
				if enemies[j].id == playerMissiles[i].targetID then 
					targetX = enemies[j].x 
					targetY = enemies[j].y
					break
				end 
			end 
			
			local vecX = (targetX - playerMissiles[i].x) 
			local vecY = (targetY - playerMissiles[i].y) 
			
			local destX = vecX / magnitude(vecX, vecY)
			local destY = vecY / magnitude(vecX, vecY)
			
			-- move 
			if playerMissiles[i].missileTimer:isComplete(dt) then 
				playerMissiles[i].vx = (destX*magnitude(playerMissiles[i].vx, playerMissiles[i].vy))
				playerMissiles[i].vy = (destY*magnitude(playerMissiles[i].vx, playerMissiles[i].vy))
			end 
			playerMissiles[i].vx = playerMissiles[i].vx+(destX*50)
			playerMissiles[i].vy = playerMissiles[i].vy+(destY*50)
			playerMissiles[i].x = playerMissiles[i].x + (playerMissiles[i].vx * dt)
			playerMissiles[i].y = playerMissiles[i].y + (playerMissiles[i].vy * dt)
			--remove out of bounds  
			--[[if  playerMissiles[i].x - playerMissiles[i].radius > screenWidth or playerMissiles[i].x + playerMissiles[i].radius < 0 or 
				playerMissiles[i].y - playerMissiles[i].radius > screenHeight or playerMissiles[i].y + playerMissiles[i].radius < 0 then  			
				table.remove(playerMissiles, i)
			end]]
		end 
	end
	-- update player missiles end 
	
	
	
	-- bullet enemy collision start 
	for j=#enemies,1,-1 do 
		for i=#playerProjectiles,1,-1 do 
	
			-- instead of randomly dodging left or right, it should assess how much space it has 
			-- if left/right isn't an option, dodge forward.
			-- when melee-ing player it should also be able to dodge back 
			
			-- took out invincibility frames for now as that makes it completely op for now 
			-- could mess with chance to dodge and balance
			
			if circleCircleCollision(playerProjectiles[i].x, playerProjectiles[i].y, playerProjectiles[i].radius, 
				enemies[j].x, enemies[j].y, enemies[j].dodgeRadius) then 
				
				
				local centreLine = lineCircleIntersection(
				playerProjectiles[i].x, playerProjectiles[i].y, 
				playerProjectiles[i].vx, playerProjectiles[i].vy, 
				enemies[j].x, enemies[j].y, enemies[j].radius)
				
				
				local normalX = playerProjectiles[i].vy / magnitude(playerProjectiles[i].vx, playerProjectiles[i].vy)
				local normalY = -playerProjectiles[i].vx / magnitude(playerProjectiles[i].vx, playerProjectiles[i].vy)	
				local shiftX = normalX * playerProjectiles[i].radius 
				local shiftY = normalY * playerProjectiles[i].radius 
				
				local normal1 = lineCircleIntersection(
				shiftX+playerProjectiles[i].x, shiftY+playerProjectiles[i].y, 
				shiftX+playerProjectiles[i].vx, shiftY+playerProjectiles[i].vy, 
				enemies[j].x, enemies[j].y, enemies[j].radius)
				
				
				normalX = -playerProjectiles[i].vy / magnitude(playerProjectiles[i].vx, playerProjectiles[i].vy)
				normalY = playerProjectiles[i].vx / magnitude(playerProjectiles[i].vx, playerProjectiles[i].vy)	
				shiftX = normalX * playerProjectiles[i].radius 
				shiftY = normalY * playerProjectiles[i].radius 
				
				local normal2 = lineCircleIntersection(
				shiftX+playerProjectiles[i].x, shiftY+playerProjectiles[i].y, 
				shiftX+playerProjectiles[i].vx, shiftY+playerProjectiles[i].vy, 
				enemies[j].x, enemies[j].y, enemies[j].radius)
				

				local dodgeChance = math.random(0,100)
				
				if not enemies[j].dodgeInvincibility and (centreLine or normal1 or normal2) and dodgeChance>75 then 
					enemies[j].dodgeInvincibility = true 
					enemies[j].dodgeTimer = Timer:new(0.1, TimerModes.single)
					
					
					-- so to change this it should be 
					-- if normal 1 hit, dodge based on that 
					-- if normal 2 hit, dodge based on that 
					-- if centreline hit, random 
					
					if math.random(1,2) == 1 then 
						enemies[j].vx = playerProjectiles[i].vy / magnitude(playerProjectiles[i].vx, playerProjectiles[i].vy) * 20
						enemies[j].vy = -playerProjectiles[i].vx / magnitude(playerProjectiles[i].vx, playerProjectiles[i].vy) * 20
					else 
						enemies[j].vx = -playerProjectiles[i].vy / magnitude(playerProjectiles[i].vx, playerProjectiles[i].vy) * 20
						enemies[j].vy = playerProjectiles[i].vx / magnitude(playerProjectiles[i].vx, playerProjectiles[i].vy) * 20
					end 
				end 
			end 	


			-- if a bullet hits an enemy 
			if not enemies[j].dodgeInvincibility and 
				circleCircleCollision(playerProjectiles[i].x, playerProjectiles[i].y, playerProjectiles[i].radius, 
				enemies[j].x, enemies[j].y, enemies[j].radius) then 
				
				enemies[j].vx = enemies[j].vx + playerProjectiles[i].vx * dt 
				enemies[j].vy = enemies[j].vy + playerProjectiles[i].vy * dt
				enemies[j].currentHealth = enemies[j].currentHealth - 5 
				if enemies[j].currentHealth < 0 then enemies[j].currentHealth = 0 end 
				table.remove(playerProjectiles, i)
			end 

			
		end
		
		
		
		for i=#playerMissiles,1,-1 do 
			if circleCircleCollision(playerMissiles[i].x, playerMissiles[i].y, playerMissiles[i].radius, 
				enemies[j].x, enemies[j].y, enemies[j].radius) then 
				
				enemies[j].vx = enemies[j].vx + playerMissiles[i].vx * dt 
				enemies[j].vy = enemies[j].vy + playerMissiles[i].vy * dt
				enemies[j].currentHealth = enemies[j].currentHealth - 5 
				if enemies[j].currentHealth < 0 then enemies[j].currentHealth = 0 end 
				addParticleExplosion(playerMissiles[i].x, playerMissiles[i].y)
				table.remove(playerMissiles, i)
			end 
		end
		
		
		
	end 
	-- bullet enemy collision end 
	
	
	-- enemy update start
	for i=#enemies,1,-1 do 
		-- enemy velocity update start 
		enemies[i].vx = enemies[i].vx - (friction * enemies[i].vx)
		enemies[i].vy = enemies[i].vy - (friction * enemies[i].vy)
		
		enemies[i].x = enemies[i].x + enemies[i].vx
		enemies[i].y = enemies[i].y + enemies[i].vy
		-- enemy velocity update end 
		
		-- update enemy invincibility start 
		if enemies[i].dodgeInvincibility and enemies[i].dodgeTimer ~= nil and enemies[i].dodgeTimer:isComplete(dt) then 
			enemies[i].dodgeInvincibility = false 
		end 
		-- update enemy invincibility end
		
		
		-- enemy wall collision start 
		local collisionResult = circleWallCollision(enemies[i].x, enemies[i].y, enemies[i].radius, enemies[i].vx, enemies[i].vy)
		enemies[i].x = enemies[i].x + collisionResult.x 
		enemies[i].y = enemies[i].y + collisionResult.y
		enemies[i].vx = enemies[i].vx * collisionResult.vx 
		enemies[i].vy = enemies[i].vy * collisionResult.vy
		-- enemy wall collision end 	
		
		-- enemy player melee collision start
		if player.meleeActive then 
			local mag = math.sqrt(math.pow(mx - player.x, 2) + math.pow(my - player.y, 2))
			local xv = ((mx - player.x)/mag) * player.radius*2
			local xy = ((my - player.y)/mag) * player.radius*2
			if circleCircleCollision(player.x + xv, player.y + xy, player.radius, enemies[i].x, enemies[i].y, enemies[i].radius) then 
				
				local canHit = true  
				for j=1,#player.meleeHitList do 
					if player.meleeHitList[j] == enemies[i].id then 
						canHit = false  
					end 
				end 
				
				if canHit then 
					enemies[i].vx = enemies[i].vx + xv
					enemies[i].vy = enemies[i].vy + xy
					table.insert(player.meleeHitList, enemies[i].id)
					if enemies[i].currentHealth <= 0 then 
						enemies[i].alterCurrentHealth = enemies[i].alterCurrentHealth - 10
						if enemies[i].alterCurrentHealth <= 0 then 
							addParticleExplosion(enemies[i].x, enemies[i].y)
							table.remove(enemies, i)
						end 
					end
				end 

			end
		end 
		-- enemy player melee collision end	
	end
	-- enemy update end
	
	
	-- update particles start 
	for i=#particles,1,-1 do 
		-- move particles
		particles[i].x = particles[i].x + (particles[i].vx * dt)
		particles[i].y = particles[i].y + (particles[i].vy * dt)
		-- lower particle alpha and remove if no longer visible 
		particles[i].alpha = particles[i].alpha - 2 
		--remove out of bounds particles 
		if  particles[i].x - particles[i].radius > screenWidth or particles[i].x + particles[i].radius < 0 or 
			particles[i].y - particles[i].radius > screenHeight or particles[i].y + particles[i].radius < 0 then  			
			table.remove(particles, i)
		elseif particles[i].alpha <= 0 then -- remove invisible particles 
			table.remove(particles,i) 
		end 
		
	end 
	-- update particles end 
	
	
end

function resetColor()
love.graphics.setColor(255,255,255)
end

function drawGame()
	love.graphics.circle("line", player.x, player.y, player.radius, 10)
	love.graphics.line(player.x, player.y, mx, my)
	
	-- this is all debug information
	for i=1,#playerProjectiles do 
		love.graphics.circle("fill", playerProjectiles[i].x, playerProjectiles[i].y, playerProjectiles[i].radius, 32)
		love.graphics.line(
		playerProjectiles[i].x, 
		playerProjectiles[i].y, 
		playerProjectiles[i].x+playerProjectiles[i].vx, 
		playerProjectiles[i].y+playerProjectiles[i].vy)
		
		local normalX = playerProjectiles[i].vy / magnitude(playerProjectiles[i].vx, playerProjectiles[i].vy)
		local normalY = -playerProjectiles[i].vx / magnitude(playerProjectiles[i].vx, playerProjectiles[i].vy)	
		local shiftX = normalX * playerProjectiles[i].radius 
		local shiftY = normalY * playerProjectiles[i].radius 
				
		love.graphics.setColor(0,0,255)
		love.graphics.line(
		shiftX+(playerProjectiles[i].x), 
		shiftY+(playerProjectiles[i].y), 
		shiftX+(playerProjectiles[i].x+playerProjectiles[i].vx), 
		shiftY+(playerProjectiles[i].y+playerProjectiles[i].vy))
		resetColor()
		
		normalX = -playerProjectiles[i].vy / magnitude(playerProjectiles[i].vx, playerProjectiles[i].vy)
		normalY = playerProjectiles[i].vx / magnitude(playerProjectiles[i].vx, playerProjectiles[i].vy)	
		shiftX = normalX * playerProjectiles[i].radius 
		shiftY = normalY * playerProjectiles[i].radius 
				
		love.graphics.setColor(0,0,150)
		love.graphics.line(
		shiftX+(playerProjectiles[i].x), 
		shiftY+(playerProjectiles[i].y), 
		shiftX+(playerProjectiles[i].x+playerProjectiles[i].vx), 
		shiftY+(playerProjectiles[i].y+playerProjectiles[i].vy))
		resetColor()
		
	end

	
	-- visualizing the projections needed to check if an enemy is going to be hit by a bullet 
	-- this is all debug information
	for j=#enemies,1,-1 do 
		love.graphics.circle("line", enemies[j].x, enemies[j].y, enemies[j].dodgeRadius, 32)
		for i=#playerProjectiles,1,-1 do 
			
			-- if an enemy can dodge a bullet 
			-- http://stackoverflow.com/questions/1073336/circle-line-segment-collision-detection-algorithm
			if circleCircleCollision(playerProjectiles[i].x, playerProjectiles[i].y, playerProjectiles[i].radius, 
				enemies[j].x, enemies[j].y, enemies[j].dodgeRadius) then 
				
				
				bulletToCircleX = enemies[j].x - playerProjectiles[i].x
				bulletToCircleY = enemies[j].y - playerProjectiles[i].y
				love.graphics.setColor(255,0,0)
				love.graphics.line(playerProjectiles[i].x, playerProjectiles[i].y, enemies[j].x, enemies[j].y)
				resetColor()
				
				local planeX = playerProjectiles[i].vx
				local planeY = playerProjectiles[i].vy
				
				-- project the vector of the distance from the bullet to the enemy 
				-- onto the bullet's velocity 
				local dot = (bulletToCircleX * planeX) + (bulletToCircleY * planeY)			
				local proj = dot / ((planeX*planeX) + (planeY*planeY))
				local projX = playerProjectiles[i].x + (planeX * proj )
				local projY = playerProjectiles[i].y + (planeY * proj )
				
				love.graphics.setColor(255,255,0)
				love.graphics.line(projX, projY, enemies[j].x, enemies[j].y)
				
				love.graphics.setColor(0,255,0)
				love.graphics.line(projX, projY, playerProjectiles[i].x , playerProjectiles[i].y)
				resetColor()
				

			end 	
		end
	end 
	
	
	
	for i=1,#enemies do 
		if enemies[i].dodgeInvincibility then 
			love.graphics.setColor(255,255,0)
		end 
		love.graphics.circle("fill", enemies[i].x, enemies[i].y, enemies[i].radius, 32)
		resetColor()
			
		if enemies[i].currentHealth > 0 then 
			love.graphics.rectangle("fill", enemies[i].x, enemies[i].y - enemies[i].radius - 15, enemies[i].currentHealth / enemies[i].maxHealth * 100, 10)
		else 
			love.graphics.setColor(255,0,0)
			love.graphics.rectangle("fill", enemies[i].x, enemies[i].y - enemies[i].radius - 15, enemies[i].alterCurrentHealth / enemies[i].alterMaxHealth * 100, 10)
			love.graphics.setColor(255,255,255)
		end 
		love.graphics.rectangle("line", enemies[i].x, enemies[i].y - enemies[i].radius - 15, 100, 10)
	end

	if player.meleeActive then 
		local mag = math.sqrt(math.pow(mx - player.x, 2) + math.pow(my - player.y, 2))
		local xv = ((mx - player.x)/mag) * player.radius*2
		local xy = ((my - player.y)/mag) * player.radius*2
		love.graphics.setColor(255,0,0)
		love.graphics.circle("fill", player.x + xv, player.y + xy, player.radius, 23)
		love.graphics.setColor(255,255,255)
		--love.graphics.circle("fill", player.x + (player.radius * math.cos(angle)), player.y + (player.radius * math.sin(angle)), player.radius, 23)
	end
	
	
	
	
	for i=1,#playerMissiles do 
		love.graphics.circle("fill", playerMissiles[i].x, playerMissiles[i].y, playerMissiles[i].radius, 32)
		
		for j=#enemies,1,-1 do 	
			if enemies[j].id == playerMissiles[i].targetID then 
				love.graphics.setColor(255,50,50)
				love.graphics.circle("line", enemies[j].x, enemies[j].y, enemies[j].radius, 32)
				love.graphics.line(enemies[j].x - enemies[j].radius, enemies[j].y, enemies[j].x + enemies[j].radius, enemies[j].y)
				love.graphics.line(enemies[j].x, enemies[j].y - enemies[j].radius, enemies[j].x, enemies[j].y + enemies[j].radius)
				resetColor()
			end 
		end
		
	end 
	
	for i=1,#particles do 
		love.graphics.setColor(200, 200, 200, particles[i].alpha)
		love.graphics.circle("fill", particles[i].x, particles[i].y, particles[i].radius, 5)
		love.graphics.setColor(255,255,255)
	end 
	
	
	
	
	
	--love.graphics.print(angle, 0, 10)
	--love.graphics.print("active player projectile count: "..tostring(#playerProjectiles), 0, 10)
	-- love.graphics.print("particle count: "..tostring(#particles), 0, 10)
end























