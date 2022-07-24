#include helper.lua

function init()
    planets = {}
    playerInit()
end

function playerInit()
    player = {}
    player.vel = 0
    player.body = FindBody('player')
    player.transform = GetBodyTransform(player.body)
    player.pos = player.transform.pos
    player.rot = player.transform.rot
    player.pitch = 0
    local min, max GetBodyBounds(player.body)
    player.center = TransformToParentPoint(player.transform, VecLerp(min,max,0.5))
    player.planetParent = 0 
    player.camera = true
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

function playerUpdate(dt)
    -------------------------------------------------- Player State --------------------------------------------------
    player.transform = GetBodyTransform(player.body)
    player.pos = player.transform.pos
    player.rot = player.transform.rot
    player.center = TransformToParentPoint(player.transform, GetBodyCenterOfMass(player.body))
    local vel = GetBodyVelocity(player.body)
    player.vel = VecAdd(vel,Vec(0, 10*dt, 0))-- kind of counteract gravity
    local cameray = InputValue('cameray')*-40 
    player.pitch = player.pitch + cameray
    player.pitch = clamp(player.pitch, -80, 80)
    -- clamp pitch between 80 and -80
    if InputPressed("h") then 
        if player.camera == false then 
            player.camera = true
        else
            player.camera = false
        end
    end
end

function planetGravity(dt)
    local prevStr = 0
    for i=1,#planets do
        local planet = planets[i]
        local dir = VecNormalize(VecSub(planet.center,player.center))
        local dist = VecDist(planet.center,player.pos)
        local gravConst = 1
        local strength = dt*(gravConst*planet.mass / (dist * dist))
        player.vel = VecAdd(player.vel,VecScale(dir,strength))

        if prevStr < strength then  
            player.planetParent = planet.body
            prevStr = strength
        end
  
    end
end

function debugPlayer(dt)
    DebugWatch("vel",VecLength(player.vel))
    DebugWatch("player.pitch",player.pitch)

    DebugLine(player.pos,VecAdd(player.pos,player.vel),1,0,1,1)
        
    --DebugLine(player.pos,TransformToParentPoint(player.transform,Vec(0,-1,0)))
   -- DebugLine(player.pos,TransformToParentPoint(player.transform,Vec(0,0,-1)),0,1,1,1)
end


function playerController()
    if player.camera then
        if InputDown("w") and IsPlayerOnGround() then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,-0.2)))
        elseif InputDown("w") and IsPlayerOnGround() == false then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,-0.05)))
        end

        if InputDown("s") and IsPlayerOnGround() then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,0.2)))
        elseif InputDown("s") and IsPlayerOnGround() == false then
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,0.05)))
        end

        if InputDown("a") and IsPlayerOnGround() then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(-0.2,0,0)))
        elseif InputDown("a") and IsPlayerOnGround() == false then
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(-0.05,0,0)))
        end

        if InputDown("d") and IsPlayerOnGround() then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0.2,0,0)))
        elseif InputDown("d") and IsPlayerOnGround() == false then
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0.05,0,0)))
        end

        if InputDown("space") and IsPlayerOnGround() then 
            ConstrainVelocity(player.body,0,player.pos,TransformToParentVec(player.transform,Vec(0,1,0)),2,10)
        end
    end
end

function  update(dt)
    playerUpdate(dt)
    planetsUpdate(dt)
    planetGravity(dt)
    playerController(dt)
    playerPhysicsUpdate(dt)
   -- debugPlayer()
end

function playerPhysicsUpdate(dt)

    -------------------------------------------------- Player Gravity Align --------------------------------------------------
    local min, max = GetBodyBounds(player.planetParent)
    local center = VecLerp(min,max,0.5)
	local xAxis = VecNormalize(VecSub(player.pos,center))
	local zAxis = VecNormalize(VecSub(center,TransformToParentPoint(player.transform,Vec(0,0,-1))))
    local down = QuatRotateQuat(QuatAlignXZ(xAxis, zAxis),QuatEuler(0,0,-90))
    local camerax = InputValue("camerax")*-60
    local targetRot = QuatRotateQuat(down,QuatEuler(0,camerax,0))

    ConstrainOrientation(player.body,0,player.rot,targetRot,5,100)
    -------------------------------------------------- Player Standing on Surface --------------------------------------------------
    QueryRejectBody(player.body)
    local hit, dist, normal, shape = QueryRaycast(player.pos,TransformToParentVec(player.transform,Vec(0,-1,0)),1.8,0)
    if hit then 
        --ConstrainPosition(player.body,0,player.pos,TransformToParentPoint(player.transform,Vec(0,1.8-dist,0)),3,100)
        ConstrainVelocity(player.body,0,player.pos,TransformToParentVec(player.transform,Vec(0,1,0)),1.8-dist)
    end
    -------------------------------------------------- Air Resistance --------------------------------------------------

    player.vel = VecScale(player.vel,0.99)

    -------------------------------------------------- Player Planet Friction --------------------------------------------------
--   local hit, shape, point = IsPlayerOnGround()
--   local planetBody = GetShapeBody(shape)
--   local bodyShapes = GetBodyShapes(planetBody)
--   if hit and HasTag(planetBody,"planet") then 
--       for i=1, #bodyShapes do 
--           local shape = bodyShapes[i]
--           if HasTag(shape,"planet") then 
--               local planetAngular = GetBodyAngularVelocity(planetBody)
--               local min, max = GetShapeBounds(shape)
--               local center = VecLerp(min,max,0.5)
--               local distance = VecDist(center,point)
--               player.vel = VecAdd(player.vel,VecScale(planetAngular,distance))
--           end
--       end
--   end
    -------------------------------------------------- Gravity --------------------------------------------------

     --SetPlayerTransform(t,true)
    SetBodyVelocity(player.body,player.vel)
end

----------------------------------------------------- Helper Functions -----------------------------------------------------

function IsPlayerOnGround()
    QueryRejectBody(player.body)
    local hit, dist, normal, shape = QueryRaycast(player.pos,TransformToParentVec(player.transform,Vec(0,-1,0)),2,0,false)
    return hit,shape, VecAdd(player.pos,VecScale(TransformToParentVec(player.transform,Vec(0,-1,0)),dist))
end

function clamp(value, mi, ma)
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end

function VecDist(a, b)
	return VecLength(VecSub(a, b))
end

function updatePlayerCamera(dt)
        -------------------------------------------------- Player Camera --------------------------------------------------
    local pos = TransformToParentPoint(player.transform,Vec(0,0,-1))
    local rot = QuatRotateQuat(player.rot,QuatEuler(player.pitch,0,0))
    local t = Transform(pos,rot)
    if player.camera then
        SetCameraTransform(t)
        --SetPlayerTransform(t,true)
    else
        DebugLine(GetPlayerTransform().pos,player.pos)
    end
    
end

function tick(dt)
    updatePlayerCamera(dt)
    --SetPlayerVelocity(VecAdd(vel,VecScale(dir,1)))
    --SetPlayerTransform(Transform(GetPlayerTransform().pos,QuatEuler(-180,0,0)),true)
end

function draw(dt)
    local prevStr = 0
    for i=1,#planets do
        local planet = planets[i]
        local dist = VecDist(planet.center,player.pos)
        local gravConst = 1
        local strength = dt*(gravConst*planet.mass / (dist * dist))
        local x, y = UiWorldToPixel(planet.center)
        if IsBodyVisible(planet.body,200) then
            UiTooltip(strength,2,"center",{x,y},5)
        end
    end
end