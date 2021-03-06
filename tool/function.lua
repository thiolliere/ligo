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

function initsource(source)
	source:setAttenuationDistances(6,60)
	source:setRolloff(2)
	return source
end



function math.round(val, decimal)
	decimal=decimal or 1
	local exp = decimal and 10^decimal or 1
	return math.ceil(val * exp - 0.5) / exp
end


function contentFile(name)
	if love.filesystem.exists(userDir.."/"..name) then
		return userDir.."/"..name
	end
	return name
end

function closeSound(source)
	xs,ys=source:getPosition()
	x,y=love.audio.getPosition()
	d=math.max(camera.tileinwidth,camera.tileinheight)*3/4
	return norme(xs-x,ys-y) < d
end
