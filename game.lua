
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

particles = {}
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
	alterCurrentHealth = 30 
	})
end




function circleCircleCollision(x1,y1,r1, x2,y2,r2)
	return (x2-x1)^2 + (y1-y2)^2 <= (r1+r2)^2
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

function loadGame()
	mx, my = love.mouse.getPosition()
	prevMx = mx 
	prevMy = my 

	centreX = screenWidth/2
	centreY = screenHeight/2
	
	newEnemy(400,400)
	
	love.mouse.setVisible(false)
end

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
	
	
	
	-- bullet enemy collision start 
	for j=#enemies,1,-1 do 
		for i=#playerProjectiles,1,-1 do 
			if  circleCircleCollision(playerProjectiles[i].x, playerProjectiles[i].y, playerProjectiles[i].radius, 
				enemies[j].x, enemies[j].y, enemies[j].radius) then 
				enemies[j].vx = enemies[j].vx + playerProjectiles[i].vx * dt 
				enemies[j].vy = enemies[j].vy + playerProjectiles[i].vy * dt
				enemies[j].currentHealth = enemies[j].currentHealth - 5 
				if enemies[j].currentHealth < 0 then enemies[j].currentHealth = 0 end 
				table.remove(playerProjectiles, i)
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


function drawGame()
	love.graphics.circle("line", player.x, player.y, player.radius, 10)
	love.graphics.line(player.x, player.y, mx, my)
	
	for i=1,#playerProjectiles do 
		love.graphics.circle("fill", playerProjectiles[i].x, playerProjectiles[i].y, playerProjectiles[i].radius, 32)
	end
	
	for i=1,#enemies do 
		love.graphics.circle("fill", enemies[i].x, enemies[i].y, enemies[i].radius, 32)
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
	
	for i=1,#particles do 
		love.graphics.setColor(200, 200, 200, particles[i].alpha)
		love.graphics.circle("fill", particles[i].x, particles[i].y, particles[i].radius, 5)
		love.graphics.setColor(255,255,255)
	end 
	
	--love.graphics.print(angle, 0, 10)
	--love.graphics.print("active player projectile count: "..tostring(#playerProjectiles), 0, 10)
	love.graphics.print("particle count: "..tostring(#particles), 0, 10)
end























