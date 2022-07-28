----------------------------------------------------------------------------------------------------
-- Arithmetic
----------------------------------------------------------------------------------------------------

function clamp(val, min, max)
	if val < min then
		return min
	elseif val > max then
		return max
	else
		return val
	end
end

function big(a, b)
	if math.abs( a ) > math.abs( b ) then
		return a
	else
		return b
	end
end

function small(a, b)
	if math.abs( a ) < math.abs( b ) then
		return a
	else
		return b
	end
end

function logistic(v, max, steep, offset)
	return max / (1 + math.exp((v - offset) * steep))
end

function snorm(v)
	if v == veczero then
		return 0
	end
	return VecNormalize(v)
end

function rndVec(length)
	local v = VecNormalize(Vec(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
	return VecScale(v, length)	
end

function Lerp(a, b, t)
	return (1-t)*a + t*b
end

function Move(a, b, t)
	output = a
    if a == b then
		return a
	end

	if a > b then
		output = math.max(a - t, b)
	else
		output = math.min(a + t, b)
	end

	return output
end

function VecDist(a, b)
	return math.sqrt( (a[1] - b[1])^2 + (a[2] - b[2])^2 + (a[3] - b[3])^2 )
end

function dist(a, b)
	return math.abs(a - b)
end


-- Challenge by @TallTim and @1ssnl to make the smallest rounding function
function Round(n,d)x=1/d return math.floor(n*x+.5)/x end

----------------------------------------------------------------------------------------------------
-- Getters
----------------------------------------------------------------------------------------------------

function jointdata(name)
    local t = {}
    local j = FindJoint(name, false)
    local min, max = GetJointLimits(j)
	local lockangle = 0 
    t = {joint = j, min = min, max = max, lockangle = lockangle}

    return t
end

function jointsdata(name)
    local t = {}
    for k, v in ipairs(FindJoints(name, false)) do
		-- DebugPrint(k.." : "..v)
        local min, max = GetJointLimits(v)
        t[k] = {joint = v, min = min, max = max} 
    end

    return t
end

function GetBodyWorldCOM(body)
	local out = TransformToParentPoint(GetBodyTransform(body), GetBodyCenterOfMass(body))
	return out
end

function GetKeyWithDefault(type, path, default)
	if not HasKey(path) then
		if type == 'float' then
			SetFloat(path, value)
		elseif type == 'int' then
			SetInt(path, value)
		elseif type == 'bool' then
			SetBool(path, value)
		elseif type == 'string' then
			SetString(path, value)
		else
			DebugPrint('GetKeyWithDefault: Invalid type ['..type..']')
		end
		
		return default
	end

	if type == 'float' then
		local value = GetFloat(path)
		-- DebugWatch(path, 'is a float, value is '..value)
		return value
	elseif type == 'int' then
		local value = GetInt(path)
		-- DebugWatch(path, 'is an int, value is '..value)
		return value
	elseif type == 'bool' then
		local value = GetBool(path)
		-- DebugWatch(path, 'is a bool, value is '..(value and 'true' or 'false'))
		return value
	elseif type == 'string' then
		local value = GetString(path)
		-- DebugWatch(path, 'is a string, value is '..value)
		return value
	else
		DebugPrint('GetKeyWithDefault: Invalid type ['..type..']')
	end
end

----------------------------------------------------------------------------------------------------
-- Debugging
----------------------------------------------------------------------------------------------------

function WatchTable(Table, prefix)
	prefix = prefix or 'Table'
	
	for k,v in pairs(Table) do
		if type(v) == 'table' then
			WatchTable(v, prefix..'.')
		else
			DebugWatch(prefix.."."..k, v)
		end
	end
end

----------------------------------------------------------------------------------------------------
-- Other
----------------------------------------------------------------------------------------------------

function NoGrav(body, dt)
	local nograv = VecScale(Vec(0, 10, 0), dt)
	local com = TransformToParentPoint(GetBodyTransform(body), GetBodyCenterOfMass(body))
	DebugCross(com)
	ApplyBodyImpulse(body, com, VecScale(nograv, GetBodyMass(body)))
end

----------------------------------------------------------------------------------------------------
-- User Interface
----------------------------------------------------------------------------------------------------

function UiGetSliderDot()
	local width, height = UiGetImageSize("ui/common/dot.png")
	return { path = "ui/common/dot.png", rect = {w = width, h = height}}
end

function UiSpacing()
	-- Predifined spacing
	return {a = 256, b = 42, c = 32, d = 24, e = 16, f = 8, wrapping = math.min(512, UiWidth())}
end

function UiSimpleContainer(width, height, color, pop)
	width = width or 300
	height = height or 400
	color = color or {0, 0, 0, 0.55}
	pop = pop or false

	if pop then UiPush() end
		UiAlign('left top')
		UiColor(color[1], color[2], color[3], color[4])
		UiImageBox("ui/common/box-solid-10.png", width, height, 10, 10)
		UiWindow(width, height, false)

		hover = UiIsMouseInRect(width, height)
	if pop then UiPop() end

	return {rect = {w = width, h = height}, hover = hover}
end

function UiSimpleSlider(pathorvalue, name, default, min, max, lockincrement)
	min = min or 0
	max = max or 1
	lockincrement = lockincrement or 0
	width = UiWidth() - UiSpacing().b * 2

	local value = nil
	if pathorvalue == nil or type(pathorvalue) == "number" then
		if pathorvalue ~= nil then
			value = pathorvalue
		else
			value = default
		end
	else
		value = GetKeyWithDefault("float", pathorvalue, default)
	end

	value = Round(value, lockincrement) * width / max - (min * width / max)

	local elapsedheight = 0

	UiPush()
		UiColor(1,1,1)
		UiWordWrap(width)
		UiFont("regular.ttf", 26)
		UiAlign('left top')
		
		UiTranslate(UiSpacing().b, 0)
		
		UiPush()
			UiTranslate(width / 2, 0)
			UiAlign('center top')
			local rw, rh = UiText(name)
			hover = UiIsMouseInRect(rw, rh)
			elapsedheight = elapsedheight + rh
		UiPop()
		
		UiColor(1,1,0.5)
		UiTranslate(0, rh + UiSpacing().f)
		elapsedheight = elapsedheight + UiSpacing().f

		UiPush()
			UiTranslate(0, -1)
			UiRect(width, 2)
			UiTranslate(0, 1)
			UiTranslate(0, -UiGetSliderDot().rect.h / 2)
			hoverslider = UiIsMouseInRect(width, UiGetSliderDot().rect.h)
		UiPop()

		UiTranslate(-UiGetSliderDot().rect.w / 2, -UiGetSliderDot().rect.h / 2)
		elapsedheight = elapsedheight + UiGetSliderDot().rect.h / 2

		value = UiSlider("ui/common/dot.png", "x", value, 0, width)

		value = (value / width) * max + min
		value = Round(value, lockincrement)
		value = math.max(value, min)
		value = math.min(value, max)

		if type(pathorvalue) == "string" then
			SetFloat(pathorvalue, value)
		end
	UiPop()

	return {value = value, hover = hover, slider = hoverslider, rect = {w = rw, h = elapsedheight}}
end

function UiSimpleTrueFalse (pathorvalue, name, default, enabletext, disabletext)
	enabletext = enabletext or "Enabled"
	disabletext = disabletext or "Disabled"

	local value = nil
	if pathorvalue == nil or type(pathorvalue) ~= "string" then
		if pathorvalue ~= nil then
			value = pathorvalue
		else
			value = default
		end

		value = value
	else
		value = GetKeyWithDefault("bool", pathorvalue, default)
	end

	local text = value and enabletext or disabletext
	
	UiPush()
		local width = UiWidth() - UiSpacing().b * 2
		UiWordWrap(width / 2)
		UiFont("regular.ttf", 24)
		
		UiPush()
			UiAlign('left top')
			UiTranslate(UiSpacing().b, 0)
			UiColor(1,1,1)
			local rw, rh = UiText(name)
			
			hover = UiIsMouseInRect(rw, rh)
		UiPop()
			
		UiPush()
			UiAlign('center top')
			UiTranslate(width, 0 )
			UiColor(1,1,0.5)
			
			
			local srw, srh = UiText(text)
			hoveroption = UiIsMouseInRect(srw, srh)
			
			if hover then UiColor(1,1,0.65) UiText(text) end
			if UiBlankButton(srw, srh) then value = not value end
		UiPop()
	UiPop()

	if type(pathorvalue) == "string" then
		SetBool(pathorvalue, value)
	end

	return {value = value, hover = hover, hoveroption = hoveroption, rect = {w = rw, h = rh}}
end

function UiSimpleButton(func, name, selfalign)
	selfalign = selfalign or false
	
	UiPush()
		local width = UiWidth()
		UiWordWrap(width)

		if not selfalign then
			UiTranslate(width / 2, 0)
			UiAlign('center middle')
		else
			UiAlign('left top')
		end

		UiFont("regular.ttf", 26)
		UiColor(1, 1, 1, 1)
		local rw, rh = UiText(name)
		UiButtonImageBox("ui/common/box-outline-6.png", 8, 8)
		bool = UiBlankButton(rw+12, rh+12)
		UiText(name)

		hover = UiIsMouseInRect(rw, rh)
	UiPop()

	if bool then
		if func then loadstring(func)() end
	end

	return {value = bool, hover = hover, rect = {w = rw, h = rh}}
end

function UiSimpleLabel(name, color, highlighonhover, funcOnClick)
	color = color or {1, 1, 1, 0.6}
	highlighonhover = highlighonhover or false

	UiPush()
		UiAlign('center top')
		local width = UiWidth()
		UiTranslate(width / 2, 0)
		UiWordWrap(width)
		UiFont("regular.ttf", 24)
		UiColor(color[1], color[2], color[3], color[4])
		local rw, rh = UiText(name)
		
		local hover = UiIsMouseInRect(rw, rh)
		local clicked = UiBlankButton(rw, rh)
		if hover and highlightonhover then UiPush() UiColor(1,1,1,0.4) UiText(name) UiPop() end

		output = {value = clicked, hover = hover, rect = {w = rw, h = rh}}
	UiPop()

	if clicked and funcOnClick then
		if funcOnClick then loadstring(funcOnClick)() end
	end

	return output
end

function UiTooltip(text, scale, side, location, alpha, blur, fontsize)
	scale = scale or 1
	fontsize = fontsize or 24
	side = side or ''
	if location then
		x, y = unpack(location)
	else
		x, y = UiGetMousePos()
	end
	alpha = alpha or 0.9
	blur = blur or 0

	UiPush()
		if blur ~= 0 then UiBlur(blur) end
		
		if side == '' then
			distleft = dist(x, 0)
			distright = dist(x, UiWidth())

			side = distleft > distright and 'left' or 'right'
		end

		if side == 'right' then
			UiAlign('left middle')
			UiTranslate(x + UiSpacing().d, y)
			UiWordWrap(UiSpacing().wrapping)
		elseif side == 'left' then
			UiAlign('right middle')
			UiTranslate(x - UiSpacing().d, y)
			UiWordWrap(UiSpacing().wrapping)
		elseif side == 'center' then
			UiAlign('center middle')
			UiTranslate(x, y)
			UiWordWrap(UiSpacing().wrapping)
		else
			DebugPrint('UiTooltip: Invalid side')
		end

		UiScale(scale)

		UiFont("regular.ttf", fontsize)
		UiColor(0,0,0,0)
		local x, y = UiText(text)
		UiColor(0,0,0,alpha)
		UiRect(x,y)
		
		UiColor(1,1,1,alpha + 0.1)
		UiText(text)
	UiPop()
end

function ImageSize(path)
	UiPush()
		UiColor(0,0,0,0)
		local rectw, recth = UiImage(path)
	UiPop()

	return {w = rectw, h = recth}
end