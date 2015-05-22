-- returns the degrees between (0,0) and pt (note: 0 degrees is 'east')
function angleOfPoint( pt )
	local x, y = pt.x, pt.y
	local angle = math.atan2(y,x)
	if angle < 0 then angle = 2*math.pi + angle end
	return angle
end
 
-- returns the degrees between two points (note: 0 degrees is 'east')
function angleBetweenPoints( a, b )
	local x, y = b.x - a.x, b.y - a.y
	return angleOfPoint( { x=x, y=y } )
end 

function angleOfVector(x1,y1,x2,y2)
	local x, y = x2-x1, y2-y1
	return angleOfPoint( { x=x, y=y } )
end

function norme(x,y)
	return math.sqrt(math.pow(x,2)+math.pow(y,2))
end

function play(source)
	local xs,ys=source:getPosition()
	local xc,yc=love.audio.getPosition()
	local n = norme(xs-xc,ys-yc) 
	if n<20 then
		source:play()
	elseif n<40 then
		source:setVolume(-n/20+2)
		source:play()
	end
end
