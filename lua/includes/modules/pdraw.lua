--[[LICENSE:
_p_modules\lua\includes\modules\pdraw.luasrc

Copyright 08/24/2014 thelastpenguin
]]
-- DRAW QUAD
do
	local q = {{},{},{},{}};
	function surface.DrawQuad( x1, y1, x2, y2, x3, y3, x4, y4 )
		q[1].x, q[1].y = x1, y1;
		q[2].x, q[2].y = x2, y2;
		q[3].x, q[3].y = x3, y3;
		q[4].x, q[4].y = x4, y4;
		surface.DrawPoly( q );
	end
end

do
	local cos, sin = math.cos, math.sin ;
	local ang2rad = 3.141592653589/180
	local drawquad = surface.DrawQuad ;
	function surface.DrawArc( _x, _y, r1, r2, aStart, aFinish, steps )
		aStart, aFinish = aStart*ang2rad, aFinish*ang2rad ;
		local step = (( aFinish - aStart ) / steps);
		local c = steps;
		
		local a, c1, s1, c2, s2 ;
		
		c2, s2 = cos(aStart), sin(aStart);
		for _a = 0, steps - 1 do
			a = _a*step + aStart;
			c1, s1 = c2, s2;
			c2, s2 = cos(a+step), sin(a+step);
			
			drawquad( _x+c1*r1, _y+s1*r1, 
						 _x+c1*r2, _y+s1*r2, 
						 _x+c2*r2, _y+s2*r2,
						 _x+c2*r1, _y+s2*r1 );
			c = c - 1;
			if c < 0 then break end
		end
	end
end

do
	local cos, sin = math.cos, math.sin ;
	local ang2rad = 3.141592653589/180
	local drawline = surface.DrawLine ;
	function surface.DrawArcOutline( _x, _y, r1, r2, aStart, aFinish, steps )
		aStart, aFinish = aStart*ang2rad, aFinish*ang2rad ;
		local step = (( aFinish - aStart ) / steps);
		local c = steps;
		
		local a, c1, s1, c2, s2 ;
		
		c2, s2 = cos(aStart), sin(aStart);
		drawline( _x+c2*r1, _y+s2*r1, _x+c2*r2, _y+s2*r2 );
		for _a = 0, steps - 1 do
			a = _a*step + aStart;
			c1, s1 = c2, s2;
			c2, s2 = cos(a+step), sin(a+step);
			
			
			drawline( _x+c1*r2, _y+s1*r2, 
												_x+c2*r2, _y+s2*r2 );
			drawline( _x+c1*r1, _y+s1*r1,
												_x+c2*r1, _y+s2*r1 );
			c = c - 1;
			if c < 0 then break end
		end
		drawline( _x+c2*r1, _y+s2*r1, _x+c2*r2, _y+s2*r2 );
	end
end

--
-- DRAW TEXT ROTATED
--
do
  local surface_SetFont, surface_SetTextColor, surface_SetTextPos, surface_GetTextSize, surface_DrawText
  do
    local _obj_0 = surface
    surface_SetFont, surface_SetTextColor, surface_SetTextPos, surface_GetTextSize, surface_DrawText = _obj_0.SetFont, _obj_0.SetTextColor, _obj_0.SetTextPos, _obj_0.GetTextSize, _obj_0.DrawText
  end
  local TEXFILTER_ANISOTROPIC
  do
    local _obj_0 = TEXFILTER
    TEXFILTER_ANISOTROPIC = _obj_0.ANISOTROPIC
  end
  local math_rad, math_sin, math_cos
  do
    local _obj_0 = math
    math_rad, math_sin, math_cos = _obj_0.rad, _obj_0.sin, _obj_0.cos
  end
  local cam_PushModelMatrix, cam_PopModelMatrix
  do
    local _obj_0 = cam
    cam_PushModelMatrix, cam_PopModelMatrix = _obj_0.PushModelMatrix, _obj_0.PopModelMatrix
  end
  local render_PopFilterMag, render_PopFilterMin, render_PushFilterMag, render_PushFilterMin
  do
    local _obj_0 = render
    render_PopFilterMag, render_PopFilterMin, render_PushFilterMag, render_PushFilterMin = _obj_0.PopFilterMag, _obj_0.PopFilterMin, _obj_0.PushFilterMag, _obj_0.PushFilterMin
  end
  local pi_2 = math.pi / 2
  local matrix = Matrix()
  local angle = Angle(0, 0, 0)
  local vector = Vector(0, 0, 0)
  local drawfunc
  drawfunc = function(text, x, y, color, font, ang)
    surface_SetFont(font)
    surface_SetTextColor(color)
    surface_SetTextPos(0, 0)
    local textW, textH = surface_GetTextSize(font)
    angle.y = ang
    vector.x, vector.y = x, y
    matrix:SetTranslation(vector)
    matrix:SetAngles(angle)
    cam_PushModelMatrix(matrix)
    surface_DrawText(text)
    return cam_PopModelMatrix()
  end
  draw.TextRotated = function(...)
    render_PushFilterMag(TEXFILTER_ANISOTROPIC)
    render_PushFilterMin(TEXFILTER_ANISOTROPIC)
    pcall(drawfunc, ...)
    render_PopFilterMag()
    return render_PopFilterMin()
  end
end
