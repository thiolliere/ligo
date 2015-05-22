require "lib.tiolved"
require "tool.function"

-- physic value :
-- configurable value :
character={
	velocity=15, -- max velocity
	stop=0.1, -- time to stop
	walkfactor=1.5,
	shape="circle", 
	radius=0.3,
	lifemax=2,
	density=1,
	lifespeed=0
	--angularDamping=10
}

character.distance=character.radius*1.2

-- value that are function of those above :
character.mass=math.pi*math.pow(character.radius,2)*character.density
character.linearDamping=-math.log(0.05)/character.stop
character.moveForce=character.linearDamping*character.velocity*character.mass

function character.closer(x,y)
	local imin=false
	local normMin=false
	for i,v in ipairs(character) do
		if not v.killed then
			local xc,yc=v.body:getPosition()
			if normMin then
				local normTmp=norme(x-xc,y-yc)
				if normTmp<normMin then
					imin=i
					normMin=normTmp
				end
			else
				normMin=norme(x-xc,y-yc)
				imin=i
			end
		end
	end
	return imin
end



function create.character( world, x, y, gid)
	local p=tonumber(gid.player) or 1

	character[p]={}
	character[p].name="character"
	character[p].nbr=p

	character[p].life = character.lifemax
	character[p].newlife=0
	character[p].walk=false
	character[p].linkedWith={}

	character[p].body = love.physics.newBody(world, x-1/2, y-1/2, "dynamic")
	character[p].shape = love.physics.newCircleShape(character.radius)
	character[p].fixture = love.physics.newFixture( character[p].body, character[p].shape, 1)
	character[p].fixture:setUserData(character[p])
	character[p].body:setLinearDamping(character.linearDamping)
	--character.body:setAngularDamping(character.angularDamping)
	setGroup(character[p].fixture,"hero")

	character[p].draw=function ()
		local x,y=toRender( character[p].body:getX(), character[p].body:getY())
		local o=character[p].body:getAngle()
		if norme(character[p].body:getLinearVelocity())<character.velocity*0.05 then
			tileset:add( 30, gid.animation[1].tileid, x, y, o, 1, 1, toRender(1/2,1/2))
		else
			tileset:add( 30, gid.animation[2].tileid, x, y, o, 1, 1, toRender(1/2,1/2))
		end
	end

	character[p].makeDamage=function(num)
		character[p].life=character[p].life-num
	end
	character[p].kill=function()
		character[p].body:setPosition(x-1/2,y-1/2)
		character[p].body:setAngularVelocity(0)
		character[p].body:setLinearVelocity(0,0)
		setGroup(character[p].fixture,"hero")
		character[p].life= character.lifemax
		character[p].newlife=0
		character[p].killed=false
	end

	local input=function()
	end
	character[p].killed=false
	character[p].beginContact={}
	character[p].update=function ()
		for _,v in ipairs(character[p].beginContact) do
			if v.other.name=="character" then
				v.other.life=character.lifemax
				v.other.killed=false
				setGroup(v.other.fixture,"hero")
				local nl=character[p].linkedWith[v.other.nbr]
				if nl then
					nl.unlink()
					nl.link()
				end
			end
		end
		character[p].beginContact={}
		if character[p].life<=0 and not character[p].killed then
			character[p].killed=true
			setGroup(character[p].fixture,"phantom")
			local k=true
			for i,v in ipairs(character) do
				k=k and v.killed
				local nl=character[p].linkedWith[i]
				if nl then
					nl.unlink()
				end
			end
			if k then
				for _,v in ipairs(character) do
					v.kill()
				end
			end
		elseif character[p].life~=character.lifemax then
			if character[p].newlife >= 1 then 
				character[p].life = character[p].life%character.lifemax+1
				character[p].newlife = 0
			else
				character[p].newlife = character[p].newlife + character.lifespeed*character[p].life
			end
		end

		local cx=character[p].body:getX()
		local cy=character[p].body:getY()
		love.audio.setPosition(cx,cy)

		input()
	end

	if keymap[p].type=="keyboard" then
		input=function()
			if love.keyboard.isDown(keymap[p].up) then
				character[p].body:applyForce(0,-character.moveForce)
			end
			if love.keyboard.isDown(keymap[p].down) then
				character[p].body:applyForce(0,character.moveForce)
			end
			if love.keyboard.isDown(keymap[p].right) then
				character[p].body:applyForce(character.moveForce,0)
			end
			if love.keyboard.isDown(keymap[p].left) then
				character[p].body:applyForce(-character.moveForce,0)
			end
		end
	elseif keymap[p].type=="hat"  then
		local joysticks=love.joystick.getJoysticks()
		local joystick=false
		for i,v in ipairs(joysticks) do
			if v:getName()==keymap[p].joystick then
				joystick=v
			end
		end
		if joystick then
			input=function()
				local dir=joystick:getHat(keymap[p].hat)
				if dir=="u" or dir=="ru" or dir=="lu" then
					character[p].body:applyForce(0,-character.moveForce)
				end
				if dir=="d" or dir=="rd" or dir=="ld" then
					character[p].body:applyForce(0,character.moveForce)
				end
				if dir=="r" or dir=="rd" or dir=="ru" then
					character[p].body:applyForce(character.moveForce,0)
				end
				if dir=="l" or dir=="ld" or dir=="lu" then
					character[p].body:applyForce(-character.moveForce,0)
				end
			end
		end
	elseif keymap[p].type=="axis" then
		local joysticks=love.joystick.getJoysticks()
		local joystick=false
		for i,v in ipairs(joysticks) do
			if v:getName()==keymap[p].joystick then
				joystick=v
			end
		end
		if joystick then
			input=function()
				local x=joystick:getAxis(keymap[p].hAxis)*keymap[p].hAxisDirection*character.moveForce
				local y=joystick:getAxis(keymap[p].vAxis)*keymap[p].vAxisDirection*character.moveForce
				character[p].body:applyForce(x,y)
			end
		end
	end

	object[character[p].name..character[p].nbr]=character[p]
end

function character.keypressed(key,unicode)
	for p,_ in ipairs(character) do
		if key == keymap[p].walk and character[p].walk==false then
			character[p].body:setLinearDamping(character.linearDamping*character.walkfactor)
			character[p].walk=true
		end
	end
end

function character.keyreleased (key,unicode)
	for p,_ in ipairs(character) do
		if key == keymap[p].walk and character[p].walk==true then
			character[p].body:setLinearDamping(character.linearDamping)
			character[p].walk=false
		end
	end
end

function character.joystickpressed(joystick,button)
	for p,_ in ipairs(character) do
		if button == keymap[p].button and joystick:getName()==keymap[p].joystick and character[p].walk==false then
			character[p].body:setLinearDamping(character.linearDamping*character.walkfactor)
			character[p].walk=true
		end
	end
end

function character.joystickreleased (joystick,button)
	for p,_ in ipairs(character) do
		if button == keymap[p].button and joystick:getName()==keymap[p].joystick and character[p].walk==true then
			character[p].body:setLinearDamping(character.linearDamping)
			character[p].walk=false
		end
	end
end