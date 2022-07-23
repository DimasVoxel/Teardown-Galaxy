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
    local min,max = GetBodyCenterOfMass(player.body)
    player.center = VecLerp(min,max,0.5)
    player.planetParent = 0 
end

function planetsUpdate()
    local planetBodies = FindBodies('planet',true) 
    for num,planetBody in pairs(planetBodies) do
        local planet = {}
        planet.body = planetBody
        local min, max = GetBodyCenterOfMass(planet)
        planet.center = VecLerp(min,max,0.5)
        planet.strength = GetTagValue(planetBody, 'gravity')
        planet.transform = GetBodyTransform(planetBody)
        planets[num] = planet 
    end 
end

function playerUpdate()
    -------------------------------------------------- Player State --------------------------------------------------
    player.transform = GetBodyTransform(player.body)
    player.pos = player.transform.pos
    player.rot = player.transform.rot
    local min,max = GetBodyCenterOfMass(player.body)
    player.center = VecLerp(min,max,0.5)
    local vel = GetBodyVelocity(player.body)
    player.vel = VecAdd(vel,Vec(0,0.165,0)) -- kind of counteract gravity

    local cameray = InputValue('cameray')*-40
    player.pitch = player.pitch + cameray
    player.pitch = clamp(player.pitch, -80, 80)
    -- clamp pitch between 80 and -80
end

function planetGravity(dt)
    local prevStr = 0
    for i=1,#planets do
        local planet = planets[i]
        local dir = VecNormalize(VecSub(planet.center,player.pos))
        local dist = VecDist(planet.center,player.pos)
        local strength = planet.strength/(dist*dist)
        DebugPrint(strength)
        player.vel = VecAdd(player.vel,VecScale(dir,strength))
        if prevStr > strength then 
            player.planetParent = planet.body
        end
    end
end

function debugPlayer(dt)
    DebugWatch("vel",VecLength(player.vel))
    DebugWatch("player.pitch",player.pitch)

        
    --DebugLine(player.pos,TransformToParentPoint(player.transform,Vec(0,-1,0)))
   -- DebugLine(player.pos,TransformToParentPoint(player.transform,Vec(0,0,-1)),0,1,1,1)
end

function playerCameraUpdate()
    local pos = TransformToParentPoint(player.transform,Vec(0,0,-0.2))
    local rot = QuatRotateQuat(player.rot,QuatEuler(player.pitch,0,0))
    local t = Transform(pos,rot)

   
   --SetPlayerTransform(t,true)
   DebugLine(GetPlayerTransform().pos,player.pos)
   SetCameraTransform(t)
end

function playerController()

    if InputDown("w") and IsPlayerOnGround() then 
        player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,-0.2)))
    end
    if InputDown("s") and IsPlayerOnGround() then 
        player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,0.2)))
    end
    if InputDown("a") and IsPlayerOnGround() then 
        player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(-0.2,0,0)))
    end
    if InputDown("d") and IsPlayerOnGround() then 
        player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0.2,0,0)))
    end
    if InputDown("space") and IsPlayerOnGround() then 
        ConstrainVelocity(player.body,0,player.pos,TransformToParentVec(player.transform,Vec(0,1,0)),1,10)
    end
end

function  update(dt)
    --debugPlayer()
    playerUpdate(dt)
    planetsUpdate(dt)
    planetGravity(dt)
    playerController(dt)
    playerPhysicsUpdate(dt)
end

function playerPhysicsUpdate()
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
    local x,y,z = GetQuatEuler(player.rot)
    QueryRejectBody(player.body)
    DebugWatch('player.rot',Vec(x,y,z))
    local hit, dist, normal, shape = QueryRaycast(player.pos,TransformToParentVec(player.transform,Vec(0,-1,0)),1.8,0)

    if hit then 
        --ConstrainPosition(player.body,0,player.pos,TransformToParentPoint(player.transform,Vec(0,1.8-dist,0)),3,100)
        ConstrainVelocity(player.body,0,player.pos,TransformToParentVec(player.transform,Vec(0,1,0)),1.8-dist)
    end
    -------------------------------------------------- Air Resistance --------------------------------------------------

    player.vel = VecScale(player.vel,0.97)

    -------------------------------------------------- Gravity --------------------------------------------------
    SetBodyVelocity(player.body,player.vel)
end

----------------------------------------------------- Helper Functions -----------------------------------------------------

function IsPlayerOnGround()
    QueryRejectBody(player.body)
    local hit, dist, normal, shape = QueryRaycast(player.pos,TransformToParentVec(player.transform,Vec(0,-1,0)),2,0,false)
    DebugPrint(hit)
    return hit
end

function clamp(value, mi, ma)
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end

function VecDist(a, b)
	return VecLength(VecSub(a, b))
end

function strongestGrav()

end

function tick()
      playerCameraUpdate(dt)


    --SetPlayerVelocity(VecAdd(vel,VecScale(dir,1)))
    --SetPlayerTransform(Transform(GetPlayerTransform().pos,QuatEuler(-180,0,0)),true)
end