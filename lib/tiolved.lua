tiolved={}

tiolved.x=0
tiolved.y=0
tiolved.width=0 --number of tile to draw in width
tiolved.height=0 -- in height
tiolved.tileWidth=0 
tiolved.tileHeight=0

-- position of point center of what will be drawn
function tiolved.setPosition(x,y)
	tiolved.x=x
	tiolved.y=y
end

-- resolution of the screen
function tiolved.setResolution(x,y)
	tiolved.width=x/tiolved.tileWidth
	tiolved.height=y/tiolved.tileHeight
end

-- array of table that contain
-- canvas of the tile
-- properties
-- identifiers ( absolute like noted in layers )
-- animation : array of {tileid,duration}
-- I use it locally to gather information
function tiolved.gid(map,rep)
	-- affectation of global tiolved attribute 
	tiolved.width=tonumber(map.width)
	tiolved.height=tonumber(map.height)
	tiolved.tileWidth=tonumber(map.tilewidth)
	tiolved.tileHeight=tonumber(map.tileheight)
	tiolved.setPosition(tiolved.width*tiolved.tileWidth/2,tiolved.height*tiolved.tileHeight/2)
	-- save the previous blendmode because tile are drawned in "replace" mode in orderto keep alpha and note having a mixe with black
	local previousblendmode=love.graphics.getBlendMode()
	love.graphics.setBlendMode("replace")
	local gid={}
	-- counter counts the tile in gid 
	-- identical to absolute identifier
	local counter=1
--	for _,m in ipairs(map) do
--		if m.je=="tileset" then
	for _,tileset in ipairs(map.tilesets) do
		-- import the image of the tileset in the repertory indicated
		tileset.image=love.graphics.newImage(contentFile(rep..tileset.image))
		-- number of tile in width and in height, used to loop on them
		local tileinwidth=math.floor(tileset.imagewidth/tileset.tilewidth)
		local tileinheight=math.floor(tileset.imageheight/tileset.tileheight)
		for n = 1,tileinheight do
			for m = 1,tileinwidth do
				-- the information of each tile are going in this table
				gid[counter]={id=counter}
				-- the quad of the part of the image correspondant to the tile
				local quad = love.graphics.newQuad((m-1)*tileset.tilewidth,(n-1)*tileset.tileheight,tileset.tilewidth,tileset.tileheight,tileset.imagewidth,tileset.imageheight)
				-- create the canvas that will contain the tile
				local canvas = love.graphics.newCanvas(tileset.tilewidth,tileset.tileheight)
				-- draw the quad of the image into the canvas
				love.graphics.setCanvas (canvas)
				love.graphics.draw(tileset.image,quad)
				love.graphics.setCanvas()
				
				gid[counter].canvas=canvas
				counter=counter+1
			end
		end

		-- parse properties and aniation
		for _,tile in ipairs(tileset.tiles) do
			-- calculation of the identifier of the tile
			local l=tile.id+tileset.firstgid
			-- animation
			if tile.animation then
				gid[l].animation={}
				for _,a in ipairs(tile.animation) do
					table.insert(gid[l].animation,{tileid=tonumber(a.tileid)+tonumber(tileset.firstgid),duration=tonumber(a.duration)})
				end
			end
			-- properties
			if tile.properties then
				for i,p in pairs(tile.properties) do
					gid[l][i]=p
				end
			end
		end
	end
	-- set the previous blend mode
	love.graphics.setBlendMode(previousblendmode)
	return gid
end

-- tileset is an object that contain the canvas of each tile, a table of animated tile and a table of tile to draw (batch)
-- it has 3 mathods : update, draw, and add
-- update changes the canvas of tile that are animated
-- add adds a tile to draw at a certain height
-- draw draws tiles and clean the batch
--
--
-- tileset is a complex table :
-- {
-- 	animated={
-- 		nexttime
-- 		current
-- 		1={canvas,duration}
-- 		2={canvas,duration}
-- 	}
-- 	batch={}
-- 	batch[12]={}
-- 	batch[12][16]=spritebatch <-- the tile 16 must be drawn at height z=12
-- 	z={
-- 		5, <-- the z height ordered ( used for drawing in order)
-- 		125,
-- 		...
-- 	}
--	1=canvas-of-first-tile
--	2=canvas-of-second-tile
--	last=canvas-of-last-tile
--}
-- with 3 methods :
-- update(dt) : change the canvas of animated tile
-- add( z, id, x, y, z, .. , kx, ky) : add a sprite in batch[z][id]
-- addEffect
-- draw() : draw and clear all spritebatch
function tiolved.tileset(gid,map)
	local tileset={
		animated={},
		batch={},
		z={},
		effect={},
		relation={}
	}
	for i,g in ipairs(gid) do
		if g.animation then
			local anim={
				id=i,
				current=1
			}
			for k,v in ipairs(g.animation) do
				if v.duration ~=0 then
					table.insert(anim,{canvas=gid[v.tileid].canvas,duration=v.duration/1000})
				end
			end
			if anim[1] then
				anim.nexttime=anim[1].duration
				table.insert(tileset.animated,anim)
				tileset.relation[i]=table.getn(tileset.animated)
				tileset[i]=anim[1].canvas
			else
				tileset[i]=g.canvas
			end
		else
			tileset[i]=g.canvas
		end
	end
	tileset.time=0
	function tileset:update(dt)
		self.time=self.time+dt
		for _,t in ipairs(self.animated) do
			while self.time >= t.nexttime do
				t.nexttime=t.nexttime+t[t.current].duration
				t.current=t.current % table.getn(t) + 1
				t.canvas=t[t.current].canvas
				for _,v in pairs(self.batch) do
					if v[t.id] then 
						v[t.id]:setTexture(t.canvas)
					end
				end
			end
		end
		for _,v in pairs(self.effect) do
			for i,t in pairs(v) do
				while self.time >= t.nexttime do
					t.current=t.current + 1
					if t.current>table.getn(self.animated[t.anim]) then
						v[i]=nil
						break
					else
						t.nexttime=t.nexttime+self.animated[t.anim][t.current].duration
					end
				end
			end
		end

	end
	local nbr=0
	function tileset:addEffect(z,id,x,y,r,sx,sy,ox,oy,kx,ky)
		if self.relation[id] then
			if not self.effect[z] then
				self.effect[z]={}
				self.batch[z]={}
				table.insert(self.z,z)
				table.sort(self.z)
			end
			nbr=nbr+1
			self.effect[z][nbr]={
				nbr=nbr,
				z=z,id=id,r=r,x=x,y=y,sx=sx,sy=sy,ox=ox,oy=oy,kx=kx,ky=ky,
				current=1,
				anim=self.relation[id]
			}
			local s=self.effect[z][nbr]
			s.nexttime=self.animated[s.anim][1].duration+self.time
		end
	end

	local size=map.width*map.height
	function tileset:add(z,id,x, y, r, sx, sy, ox, oy, kx, ky )
		if not self.batch[z] then 
			self.effect[z]={}
			self.batch[z]={} 
			table.insert(self.z,z)
			table.sort(self.z)
		end
		if not self.batch[z][id] then self.batch[z][id]=love.graphics.newSpriteBatch(self[id],size/1.5) end
		self.batch[z][id]:add(x, y, r, sx, sy, ox, oy, kx, ky )
	end
	function tileset:draw()
		for _,v in ipairs(self.z) do
			for _,k in pairs(self.batch[v]) do
				love.graphics.draw(k,0,0)
				k:clear()
			end
			for _,k in pairs(self.effect[v]) do
				love.graphics.draw(self.animated[k.anim].canvas,k.x,k.y,k.r,k.sx,k.sy,k.ox,k.oy,k.kx,k.ky)
			end
		end
	end
	return tileset
end

-- layers is a table with :
-- 	an array of layer
-- 	draw : function that call all layer.draw
-- layer is a table with :
-- 	name 
-- 	number ( order in tiled )
-- 	tile = { 	
-- 		{id,x,y} 
-- 		{id,x,y}
-- 	}
-- 	property1=value1
-- 	property2=value2
-- 	draw ( function that add tile in tileset batch )
function tiolved.layers(map,tileset)
	local layers={}
	local number=1
	if map.orientation=="orthogonal" then
		for _,v in ipairs(map.layers) do
			local layer={
				name=v.name,
				number=number,
				tile={}
			}
			-- properties
			if v.properties then
				for i,k in ipairs(v.properties) do
					layer[i]=k
				end
			end

			-- interpration of z property
			if not layer.z then layer.z=number 
			else layer.z=tonumber(layer.z)
			end
			
			-- data
			for k,l in ipairs(v.data) do
				if l~=0 then
					local id=l
					local tileheight=tileset[id]:getHeight()
					local pos={x=(k-1)%map.width*map.tilewidth,y=(math.ceil(k/map.width))*map.tileheight-tileheight}
					tileset:add(layer.z,id,pos.x,pos.y)
					table.insert(layer.tile,{id=id,x=pos.x,y=pos.y})
				else
					table.insert(layer.tile,false)
				end
			end

			-- function to insert tiles of the layer in tileset.batch
			function layer.draw()
				local cx,cy=tiolved.x,tiolved.y
				for j=math.floor(cy-tiolved.height/2),math.ceil(cy+tiolved.height/2) do
					for i=math.floor(cx-tiolved.width/2),math.ceil(cx+tiolved.width/2) do
						local v=layer.tile[i+j*map.width]
						if v then
							tileset:add(layer.z,v.id,v.x,v.y)
						end
					end
				end
			end
			-- insertion in a global table named layers
			table.insert(layers,layer)
			number=number+1
		end
	end
	function layers:draw()
		for _,v in ipairs(self) do
			v.draw()
		end
	end
	return layers
end

-- two functions : toMap and toRender
-- map coordinate are : 1 tile measure 1*1
-- render coordinate are : 1 tile measure Xpixel*Ypixel
function tiolved.usefulfunc(map)
	local toMap,toRender

	if map.orientation=="orthogonal" then
		function toMap(x,y)
			return x/map.tilewidth,y/map.tileheight
		end
		function toRender(x,y)
			return x*map.tilewidth,y*map.tileheight
		end
	end
	return toMap,toRender
end
