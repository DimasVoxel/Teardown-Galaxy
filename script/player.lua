#include helper.lua

function init()
    planets = {}
    playerInit()
    toolInit()
end

function toolInit()
	RegisterTool("grapple_loaded", "Grappling Hook", "MOD/vox/tool/grapple.vox",1)
    SetBool("game.tool.grapple_loaded.enabled", true)
    RegisterTool("grapple_shot", "Grappling Hook", "MOD/vox/tool/grappleBody.vox",1)
    SetBool("game.tool.grapple_shot.enabled", false)
    
    tool = {}
    tool.hookBody = 0 
    tool.hookTransform = Transform()
    tool.hookEngaged = false
    tool.hookPoint = Vec()
    tool.hookBody = 0

end

function playerInit()
    player = {}
    player.vel = 0
    player.body = FindBody('player')
    player.transform = GetBodyTransform(player.body)
    player.pos = player.transform.pos
    player.rot = player.transform.rot
    
    player.HeadTransform = Transform(TransformToParentPoint(player.transform,(Vec(0,1.8,0))),player.rot)
    player.HeadPos = player.HeadTransform.pos
    player.HeadRot = player.HeadTransform.rot

    player.pitch = 0
    local min, max GetBodyBounds(player.body)
    player.center = TransformToParentPoint(player.transform, VecLerp(min,max,0.5))
    player.planetParent = 0 
    player.camera = true
    local hit, shape, point = IsPlayerOnGround()
    player.contactPoint = point

    local shapes = GetBodyShapes(player.body)
    for i=1,#shapes do 
        SetShapeCollisionFilter(shapes[i], 2,0)
    end
    player.camera = "player" 
    player.vehicleBody = GetVehicleBody(GetPlayerVehicle())
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
    player.HeadTransform = Transform(TransformToParentPoint(player.transform,(Vec(0,1.8,0))),player.rot)
    player.HeadPos = player.HeadTransform.pos
    player.HeadRot = player.HeadTransform.rot
    --DebugLine(player.pos,player.HeadPos,1,1,1,1)
    player.center = TransformToParentPoint(player.transform, GetBodyCenterOfMass(player.body))
    local vel = GetBodyVelocity(player.body)
    player.vel = VecAdd(vel,Vec(0, 10*dt, 0))-- kind of counteract gravity
    local cameray = InputValue('cameray')*-40 
    player.pitch = player.pitch + cameray
    player.pitch = clamp(player.pitch, -80, 80)
    -- clamp pitch between 80 and -80

    local hit, shape, point = IsPlayerOnGround()
    player.contactPoint = point
    player.vehicleBody = GetVehicleBody(GetPlayerVehicle())
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

    local x,y,z = GetQuatEuler(player.rot)
    DebugWatch("player.rot.x",Vec(x,y,z))

 
    DebugCross(player.contactPoint,1,1,1,1)
    DebugLine(player.HeadPos,TransformToParentPoint(player.HeadTransform,Vec(0,-1,0)))
    DebugLine(player.HeadPos,TransformToParentPoint(player.HeadTransform,Vec(0,0,-1)),0,1,1,1)
end


function playerController()
    if player.camera ~= "independent" then
        if InputDown("w") and IsPlayerOnGround() then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,-0.25)))
        elseif InputDown("w") and IsPlayerOnGround() == false then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,-0.05)))
        end

        if InputDown("s") and IsPlayerOnGround() then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,0.25)))
        elseif InputDown("s") and IsPlayerOnGround() == false then
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,0.05)))
        end

        if InputDown("a") and IsPlayerOnGround() then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(-0.25,0,0)))
        elseif InputDown("a") and IsPlayerOnGround() == false then
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(-0.05,0,0)))
        end

        if InputDown("d") and IsPlayerOnGround() then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0.25,0,0)))
        elseif InputDown("d") and IsPlayerOnGround() == false then
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0.05,0,0)))
        end

        if InputDown("space") and IsPlayerOnGround() then 
            ConstrainVelocity(player.body,0,player.center,TransformToParentVec(player.transform,Vec(0,1,0)),10)
        end
    end
end

function playerTool()
    if GetString("game.player.tool") == "grapple_loaded" or GetString("game.player.tool") == "grapple_shot" then 
        ToolTransform = Transform()
        ToolTransform.pos = Vec(0.725,-0.425, -1)
        ToolTransform.rot = QuatEuler(10,89, 14)
        SetToolTransform(ToolTransform,1.2)
        --show points compared to tool
        local LocalTr = Transform(Vec(0.175,0.25,0))
        local PointOnTool = TransformToParentPoint(GetBodyTransform(GetToolBody()),LocalTr.pos)
        local ToolOrigin = TransformToParentPoint(GetBodyTransform(GetToolBody()),Vec(0,0,0))
        --PointOnTool = TransformToParentTransform(GetCameraTransform(),PointOnTool)
        if InputDown("usetool") and GetBool("game.tool.grapple_loaded.enabled") == true then
            SetBool("game.tool.grapple_loaded.enabled", false)
            SetBool("game.tool.grapple_shot.enabled", true)
            SetString("game.player.tool", "grapple_shot")

            local rot = QuatRotateQuat(player.rot,QuatEuler(player.pitch,0,0))
            local t = Transform(PointOnTool,rot)
            local vox = Spawn("MOD/vox/tool/hook.xml",t)

            SetBodyAngularVelocity(vox[1],Vec())
            SetBodyVelocity(vox[1],VecScale(TransformToParentVec(t,Vec(0,0,-1)),30))
            tool.hookBody = FindBody('hookBody',true)
        end

        if GetBool("game.tool.grapple_shot.enabled") == true then 
            tool.hookTransform = GetBodyTransform(tool.hookBody)
            DrawLine(PointOnTool,tool.hookTransform.pos,0,0,0,1)

            QueryRequire("physical large")
            QueryRejectBody(tool.hookBody)
            local hit, point, normal , shape = QueryClosestPoint(tool.hookTransform.pos,1)

            if hit and tool.hookEngaged == false and VecDist(player.pos,tool.hookTransform.pos) > 5 then 
                tool.hookEngaged = true
                tool.hookedBody = GetShapeBody(shape)
                local bt = GetBodyTransform(tool.hookedBody)
                tool.hookLocalTransform = TransformToLocalTransform(bt,tool.hookTransform)
            end

            if tool.hookEngaged == true then 
                ConstrainPosition(tool.hookBody,tool.hookedBody,tool.hookTransform.pos,TransformToParentTransform(GetBodyTransform(tool.hookedBody),tool.hookLocalTransform).pos)
                if InputDown("usetool") and VecDist(player.pos,tool.hookTransform.pos) > 5 then 
                    --ConstrainPosition(player.body,tool.hookBody,player.pos,TransformToParentTransform(GetBodyTransform(tool.hookedBody),tool.hookLocalTransform).pos,10,5)
                    ConstrainVelocity(player.body,0,player.center,VecSub(tool.hookTransform.pos,player.pos),10,0,10)
                end
            end
            if VecDist(player.pos,tool.hookTransform.pos) > 10 and not tool.hookEngaged then 
                if InputDown("usetool") then 
                    ConstrainVelocity(tool.hookBody,0,tool.hookTransform.pos,VecSub(player.pos,tool.hookTransform.pos),10,0)
                end
            end
        end

        if GetPlayerInteractBody() == tool.hookBody and InputDown("interact") then 
            SetBool("game.tool.grapple_loaded.enabled", true)
            SetBool("game.tool.grapple_shot.enabled", false)
            SetString("game.player.tool", "grapple_loaded")
            Delete(tool.hookBody)
            toolInit() --reset tool
        end
    end
end


function  update(dt)

    playerUpdate(dt)
    planetsUpdate(dt)
    planetGravity(dt)
    playerController(dt)
    playerPhysicsUpdate(dt)
    --debugPlayer()
end


prevRot = Quat(0,0,0,1)
function playerPhysicsUpdate(dt)

    local hit, shape, point = IsPlayerOnGround()
    local planetBody = GetShapeBody(shape)
    local t = GetBodyTransform(planetBody)

    SetBodyAngularVelocity(player.body,(GetBodyAngularVelocity(planetBody)))

    -------------------------------------------------- Player Gravity Align --------------------------------------------------
    local shapes = GetBodyShapes(player.planetParent)
    local planetShape = 0 
    for i=1, #shapes do 
        if HasTag(shapes[i],"planet") then 
            planetShape = shapes[i]
            break
        end
    end
    local min, max = GetShapeBounds(planetShape)
    local center = VecLerp(min,max,0.5)
	local xAxis = VecNormalize(VecSub(player.HeadPos,center))
	local zAxis = VecNormalize(VecSub(center,TransformToParentPoint(player.HeadTransform,Vec(0,0,-1))))
    local down = QuatRotateQuat(QuatAlignXZ(xAxis, zAxis),QuatEuler(0,0,-90))
    local camerax = InputValue("camerax")*-60
    local targetRot = QuatRotateQuat(down,QuatEuler(0,camerax,0))

    ConstrainOrientation(player.body,0,player.rot,targetRot,5,100)
    -------------------------------------------------- Player Standing on Surface --------------------------------------------------
    QueryRejectBody(player.body)
    local hit, dist, normal, shape = QueryRaycast(player.HeadPos,TransformToParentVec(player.HeadTransform,Vec(0,-1,0)),1.8,0)
    if hit then 
        --ConstrainPosition(player.body,0,player.HeadPos,TransformToParentPoint(player.HeadTransform,Vec(0,1.8-dist,0)),3,100)
        ConstrainVelocity(player.body,0,player.HeadPos,TransformToParentVec(player.HeadTransform,Vec(0,1,0)),1.8-dist,0)
    end
    -------------------------------------------------- Air Resistance --------------------------------------------------

    player.vel = VecScale(player.vel,0.99)

    -------------------------------------------------- Player Planet Friction --------------------------------------------------
   local hit, shape, point = IsPlayerOnGround()
   local planetBody = GetShapeBody(shape)
   if hit and HasTag(planetBody,"planet") then
        local FinalVel = GetBodyVelocityAtPos(planetBody,point)
        local PlayerVel = player.vel
        local MaxAcc = 5*dt
        local VelDiff = VecSub(FinalVel,PlayerVel)
        local l = VecLength(VelDiff)
        if l>MaxAcc then
            VelDiff = VecScale(VecNormalize(VelDiff),MaxAcc)
            player.vel = VecAdd(player.vel,VelDiff)
        else
            player.vel = FinalVel
        end
        --Add to velocity here for moving from inputs
   end
    -------------------------------------------------- Gravity --------------------------------------------------

     --SetPlayerTransform(t,true)

    if VecLength(player.vel) < 0.2 and hit then 
        player.vel = 0
        ConstrainPosition(player.body,0,player.pos,player.pos)
    end

    if GetPlayerVehicle() ~= 0 then
        ConstrainPosition(player.body,0,player.pos, GetBodyTransform((GetVehicleBody(GetPlayerVehicle()))).pos)
    else
        SetBodyVelocity(player.body,player.vel)
    end


end

----------------------------------------------------- Helper Functions -----------------------------------------------------

function IsPlayerOnGround()
    QueryRejectBody(player.body)
    local hit, dist, normal, shape = QueryRaycast(player.HeadPos,TransformToParentVec(player.HeadTransform,Vec(0,-1,0)),2,0,false)
    return hit,shape, VecAdd(player.HeadPos,VecScale(TransformToParentVec(player.HeadTransform,Vec(0,-1,0)),dist))
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

    if player.camera == "camera" then
        local pos = TransformToParentPoint(player.HeadTransform,Vec(0,0,0))
        local rot = QuatRotateQuat(player.rot,QuatEuler(player.pitch,0,0))
        local t = Transform(pos,rot)

        SetCameraTransform(t)
    elseif player.camera == "independent" then
        DebugLine(GetPlayerTransform().pos,player.HeadPos)
    elseif player.camera == "player" then    
        local pos = VecAdd(TransformToParentPoint(player.HeadTransform,Vec(0,0,0)),Vec(0,-1.8,0))
        local rot = QuatRotateQuat(player.rot,QuatEuler(player.pitch,0,0))
        local t = Transform(pos,rot)
        
        SetPlayerTransform(t, true) -- Doesnt work. Well it does, but it has issues
    end

 --This needs way more work 
  if player.vehicleBody ~= 0 then
 
      local pos = TransformToParentPoint(player.HeadTransform,Vec(0,1,3))
      local rot = QuatRotateQuat(player.rot,QuatEuler(player.pitch,0,0))
      local t = Transform(pos,rot)
      SetCameraTransform(t)
  end
end

function tick(dt)
    updatePlayerCamera(dt)
    playerTool(dt)

    if InputPressed("h") then 
        if player.camera == "camera" then 
            player.camera = "player"
        elseif player.camera == "player" then
            player.camera = "independent"
        elseif player.camera == "independent" then
            player.camera = "camera"
        end
    end
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
            --UiTooltip(strength,2,"center",{x,y},5)
        end
    end
end