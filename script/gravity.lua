function init()
    planets = {}
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
        planets[num] = planet 
    end 
end


function gravityUpdate(dt)
    local bodies = FindBodies("",true) 
    for num,body in pairs(bodies) do
        if not HasTag(body,"nograv") and IsBodyDynamic(body) == true and not HasTag(body,"player") then
            local vel = GetBodyVelocity(body)
            vel = VecAdd(Vec(0,10*dt,0),vel)
            for i=1,#planets do
                local planet = planets[i]
                
                local t = GetBodyTransform(body)
                local com = TransformToParentPoint(t,GetBodyCenterOfMass(body))
                if VecDist(planet.center, com) > 0.1 then 
                    local mass = GetBodyMass(body)
                    local dir = VecNormalize(VecSub(planet.center,com))
                    local dist = VecDist(planet.center,com)
                    local coef = 7200/mass
                    local gravConst = 0.00015
                    local strength = dt*(gravConst*planet.mass*((mass*coef)-100) / (dist * dist))
                    vel = VecAdd(vel,VecScale(dir,strength))
                end
            end         
            SetBodyVelocity(body,vel)
        end
    end
end


function update(dt)
    planetsUpdate(dt)
    gravityUpdate(dt)
end

function VecDist(a, b)
	return VecLength(VecSub(a, b))
end
