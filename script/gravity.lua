

function init()
    planets = {}
    gravityFields = {}
end

function attractorsUpdate()
    local triggers = FindTriggers("gravityfield",true)
    for num,trigger in pairs(triggers) do 
        local field = {}
        field.trigger = trigger
        field.transform = GetTriggerTransform(trigger)
        field.strength = GetTagValue(trigger, "mass")
        field.type = GetTagValue(trigger, "type") -- can be either global gravity(like planet but long) or local only apply if in trigegr
        field.exclusive = HasTag(trigger, "exclusive") -- if exclusive then ignore all other gravity fields
        field.pullDir = TransformToParentVec(field.transform, Vec(0,-1,0))
        gravityFields[num] = field
    end
end

function planetsUpdate()
    local planetShapes = FindShapes('planet',true) 
    for num,planetShape in pairs(planetShapes) do
        local planet = {}
        planet.shape = planetShape
        planet.body = GetShapeBody(planetShape)
        planet.transform = GetBodyTransform(planet.body)
        local min, max = GetShapeBounds(planet.shape)
        planet.center = VecLerp(min,max,0.5)
        planet.mass = tonumber(GetTagValue(planet.body, 'mass'))
        if HasTag(planet.body,'type') then planet.type = GetTagValue(planet.body, 'type') else planet.type = "attract" end -- can be either attract(default) or repell
        planets[num] = planet 
    end 
end


function gravityUpdate(dt)
    local bodies = FindBodies("",true) 
    for num,body in pairs(bodies) do
        if not HasTag(body,"nograv") and IsBodyDynamic(body) == true and not HasTag(body,"player") then
            local vel = GetBodyVelocity(body)
            vel = VecAdd(Vec(0,10*dt,0),vel)
            local t = GetBodyTransform(body)
            local com = TransformToParentPoint(t,GetBodyCenterOfMass(body))
            local mass = GetBodyMass(body)
            for i=1,#planets do
                local planet = planets[i]
                if VecDist(planet.center, com) > 0.1 then 
                    local dir = VecNormalize(VecSub(planet.center,com))
                    local dist = VecDist(planet.center,com)
                    local coef = 7200/mass
                    local gravConst = 0.00015
                    local strength = dt*(gravConst*planet.mass*((mass*coef)-100) / (dist * dist))
                    if planet.type == "repel" then
                        strength = strength* -1
                    end
                    vel = VecAdd(vel,VecScale(dir,strength))
                end
            end       
            for i=1,#gravityFields do
                local field = gravityFields[i] 
                local strength = 0
                if field.type == "global" then
                    local closestPoint = GetTriggerClosestPoint(field.trigger, com)
                    local dir = Vec()
                    if VecStr(com) == VecStr(closestPoint) then 
                        dir = VecCopy(field.pullDir)
                    else
                        dir = VecNormalize(VecSub(closestPoint,com))
                    end
                    local dist = Clamp(VecDist(closestPoint,com),8,10000000000)
                    local coef = 7200/mass
                    local gravConst = 0.00015
                    strength = dt*(gravConst*field.strength*((mass*coef)-100) / (dist * dist))
                    if field.exclusive == true then 
                        vel = VecAdd(Vec(0,10*dt,0),GetBodyVelocity(body))
                        vel = VecAdd(vel,VecScale(dir,strength))
                        break
                    end 
                    vel = VecAdd(vel,VecScale(dir,strength))
                elseif field.type == "local" then 
                    if IsPointInTrigger(field.trigger, com) then 
                        local closestPoint = GetTriggerClosestPoint(field.trigger, com)
                        local dist = Clamp(VecDist(closestPoint,com),8,10000000000)
                        local coef = 7200/mass
                        local gravConst = 0.00015
                        local strength = dt*(gravConst*field.strength*((mass*coef)-100) / (dist * dist))
                        if field.exclusive == true then 
                            vel = VecAdd(Vec(0,10*dt,0),GetBodyVelocity(body))
                            vel = VecAdd(vel,VecScale(field.pullDir,strength))
                            break
                        end 
                        vel = VecAdd(vel,VecScale(field.pullDir,strength))
                    end
                end
            end
            if mass > 1000 then 
                vel = VecScale(vel,0.999)
            end
            SetBodyVelocity(body,vel)
        end
    end
end


function update(dt)
    attractorsUpdate(dt)
    planetsUpdate(dt)
    gravityUpdate(dt)
end

function Clamp(value, mi, ma)
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end

function VecDist(a, b)
	return VecLength(VecSub(a, b))
end
