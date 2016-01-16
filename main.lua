--require('camera')

function love.load()
	bg = love.graphics.newImage("dirt.jpg");
	dogimg = love.graphics.newImage("dog.png");
	dog = {}
	dog.sprite = dogimg
	dog.worldX = 300
	dog.worldY = 450
	dog.acc = 40
	dog.dx = 0
	dog.dy = 0
	dog.angle = 0

	sheepList = {}
	sheepImg = love.graphics.newImage("sheep.png");


	newSheep1 = {x=100, y=100, dx=0, dy=0, angle=0.2, sprite = sheepImg, ai = "idle"}
	newSheep2 = {x=150, y=120, dx=0, dy=0, angle=4.4, sprite = sheepImg, ai = "idle"}
	newSheep3 = {x=120, y=300, dx=0, dy=0, angle=0.1, sprite = sheepImg, ai = "idle"}
	newSheep4 = {x=300, y=120, dx=0, dy=0, angle=3, sprite = sheepImg, ai = "idle"}
	newSheep5 = {x=200, y=500, dx=0, dy=0, angle=0, sprite = sheepImg, ai = "idle"}
	table.insert(sheepList, newSheep1)
	table.insert(sheepList, newSheep2)
	table.insert(sheepList, newSheep3)
	table.insert(sheepList, newSheep4)
	table.insert(sheepList, newSheep5)

	local fragmentcode = [[
		extern number dogX;
		extern number dogY;
		extern number lightdist;
		vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
		  vec4 pixel = Texel(texture, texture_coords ); //This is the current pixel color
		  number brightness = pixel.r*pixel.r+pixel.b*pixel.b+pixel.g*pixel.g;
		  number xdist = (screen_coords.x-dogX);
		  number ydist = (screen_coords.y-dogY);
		  number dist = sqrt(xdist*xdist+ydist*ydist);

		  number factor = (lightdist-dist)/lightdist; // amount to reduce light by
		  if(factor < 0){
		  	factor = 0;
		  }
		  factor = factor * factor;

		  pixel.r = pixel.r * factor;
		  pixel.g = pixel.g * factor;
		  pixel.b = pixel.b * factor;

		  return pixel;
		}
	]]
    local vertexcode = [[
        vec4 position( mat4 transform_projection, vec4 vertex_position )
        {
            return transform_projection * vertex_position;
        }
    ]]
  myShader = love.graphics.newShader(fragmentcode)

	myShader:send("dogX",300)  
	myShader:send("dogY",450)  
	myShader:send("lightdist",520)  

end

function love.update(dt)
	myShader:send("dogX",dog.worldX)  
	myShader:send("dogY",dog.worldY)  

	if love.keyboard.isDown("1") then
		barkcome()
	elseif love.keyboard.isDown("2") then
		barkstay()
	end

	if love.keyboard.isDown("right") then
		dog.dx = dog.dx + dog.acc
	elseif love.keyboard.isDown("left") then
		dog.dx = dog.dx - dog.acc
	end
	if love.keyboard.isDown("up") then
		dog.dy = dog.dy - dog.acc
	elseif love.keyboard.isDown("down") then
		dog.dy = dog.dy + dog.acc
	end
	dog.worldX = dog.worldX + dog.dx*dt
	dog.worldY = dog.worldY + dog.dy*dt
	dog.dx = dog.dx * 0.84
	dog.dy = dog.dy * 0.84
	if(math.abs(dog.dx) > 0.01 and math.abs(dog.dy) > 0.01) then
		--local dogDir = math.atan2(dog.dy,dog.dx)
		--if(dog.angle - 0.01 > dogDir or dog.angle + 0.01 < dogDir) then

		dog.angle = math.atan2(dog.dy,dog.dx)
	end

	-- update sheep
	for i, sheep in ipairs(sheepList) do
		if sheep.ai == "idle" then
			sheep.angle = sheep.angle + 0.01
			if sheep.angle > 6.283185 then
				sheep.angle = sheep.angle - 6.283185
			end
		elseif sheep.ai == "follow" then
			sheep.ai = "followBump"
			local sheepDistX = (dog.worldX - sheep.x)
			local sheepDistY = (dog.worldY - sheep.y)
			local sheepDistSqr = math.sqrt(sheepDistX*sheepDistX+sheepDistY*sheepDistY)
			if sheepDistSqr > 110 then
				sheep.dx = (sheepDistX/sheepDistSqr)*dt*80
				sheep.dy = (sheepDistY/sheepDistSqr)*dt*80
			else
				sheep.ai = "followIdle"
			end
		elseif sheep.ai == "followIdle" then
			sheep.ai = "followBumpIdle"
			local sheepDistXAbs = math.abs(dog.worldX - sheep.x)
			local sheepDistYAbs = math.abs(dog.worldY - sheep.y)
			sheep.angle = sheep.angle + 0.01
			if sheep.angle > 6.283185 then
				sheep.angle = sheep.angle - 6.283185
			end
			if sheepDistXAbs > 113 or sheepDistYAbs > 113 then
				-- there is a possibility that sheep is outside
				local sheepDistSqr = math.sqrt(sheepDistXAbs*sheepDistXAbs+sheepDistYAbs*sheepDistYAbs)
				if sheepDistSqr > 160 then
					sheep.ai = "follow"
				end
			end
		elseif sheep.ai == "followBump" then
			sheep.ai = "follow"
			-- don't clump up with other sheep
			for j = (i+1), 5 do
				--sheep.x = sheepList[j].x
				local SheepToSheepDistX = sheep.x - sheepList[j].x
				local SheepToSheepDistY = sheep.y - sheepList[j].y
				local SheepToSheepDistSqrt = math.sqrt(SheepToSheepDistX*SheepToSheepDistX+SheepToSheepDistY*SheepToSheepDistY)
				if SheepToSheepDistSqrt < 30 then
					local bumpAwayX = (SheepToSheepDistX/SheepToSheepDistSqrt)*dt*60
					local bumpAwayY = (SheepToSheepDistY/SheepToSheepDistSqrt)*dt*60
					sheep.dx = sheep.dx*0.7 + bumpAwayX
					sheep.dy = sheep.dy*0.7 + bumpAwayY
					sheepList[j].dx = sheepList[j].dx*0.7 - bumpAwayX
					sheepList[j].dy = sheepList[j].dy*0.7 - bumpAwayY
				end
			end
		elseif sheep.ai == "followBumpIdle" then
			sheep.ai = "followIdle"
			-- don't clump up with other sheep
			for j = (i+1), 5 do
				--sheep.x = sheepList[j].x
				local SheepToSheepDistX = sheep.x - sheepList[j].x
				local SheepToSheepDistY = sheep.y - sheepList[j].y
				local SheepToSheepDistSqrt = math.sqrt(SheepToSheepDistX*SheepToSheepDistX+SheepToSheepDistY*SheepToSheepDistY)
				if SheepToSheepDistSqrt < 30 then
					local bumpAwayX = (SheepToSheepDistX/SheepToSheepDistSqrt)*dt*50
					local bumpAwayY = (SheepToSheepDistY/SheepToSheepDistSqrt)*dt*50
					sheep.dx = sheep.dx + bumpAwayX
					sheep.dy = sheep.dy + bumpAwayY
					sheepList[j].dx = sheepList[j].dx - bumpAwayX
					sheepList[j].dy = sheepList[j].dy - bumpAwayY
				end
			end
		end
		sheep.dx = sheep.dx * 0.97
		sheep.dy = sheep.dy * 0.97
		sheep.x = sheep.x + sheep.dx
		sheep.y = sheep.y + sheep.dy

		if sheep.x < 0 then
			sheep.x = 0
			sheep.dx = -sheep.dx + 1
		end
		if sheep.y < 0 then
			sheep.y = 0
			sheep.dy = -sheep.dy + 1
		end
		if sheep.x > 800 then
			sheep.x = 800
			sheep.dx = -sheep.dx - 1
		end
		if sheep.y > 600 then
			sheep.y = 600
			sheep.dy = -sheep.dy - 1
		end

		if(math.abs(sheep.dx) > 0.01 and math.abs(sheep.dy) > 0.01) then
			sheep.angle = math.atan2(sheep.dy,sheep.dx)
		end
	end
end

function love.draw()
	-- dog

	love.graphics.setShader(myShader) --draw something here
	love.graphics.draw(bg);
	for i, sheep in ipairs(sheepList) do
		love.graphics.draw(sheep.sprite, sheep.x, sheep.y, sheep.angle, 1, 1, 15, 15)
	end
	love.graphics.draw(dog.sprite, WorldToScreenX(dog.worldX), WorldToScreenY(dog.worldY), dog.angle, 1, 1, 15, 20)
	--love.graphics.setColor(255,0,0,255)
	--love.graphics.rectangle("fill",dog.worldX,dog.y,30,30)
	--love.graphics.setShader()
end

function WorldToScreenX(x)
	return x
end

function WorldToScreenY(y)
	return y
end

function barkcome()
	for i, sheep in ipairs(sheepList) do
		local sheepDistX = math.abs(sheep.x - dog.worldX)
		local sheepDistY = math.abs(sheep.y - dog.worldY)
		if sheepDistX < 250 and sheepDistY < 250 then
			if sheepDistX*sheepDistX+sheepDistY*sheepDistY < 62500 then
				sheep.ai = "follow"
			end
		end
		love.graphics.draw(sheep.sprite, sheep.x, sheep.y, sheep.angle, 1, 1, 15, 15)
	end
end

function barkstay()
	for i, sheep in ipairs(sheepList) do
		if sheep.ai == "follow" or sheep.ai == "followBump" or sheep.ai == "followIdle" then
			sheep.ai = "idle"
		end
		love.graphics.draw(sheep.sprite, sheep.x, sheep.y, sheep.angle, 1, 1, 15, 15)
	end
end