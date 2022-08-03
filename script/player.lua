#include helper.lua


function init()

    scroll = 10 
    vehicleCamera = Quat()
    vehicleCamYaw = 0

    planets = {}
    gravityFields = {}
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
    tool.flashTimer = 5
end

-- Super jank player contact point generator
function playerContactPoint()
    local hit, dist, normal, shape = QueryRaycast(TransformToParentPoint(player.transform,Vec(0.2,0.4,-0.2)),TransformToParentVec(player.headTransform,Vec(0,-1,0)),0.4,0,false)
    point1 = VecAdd(TransformToParentPoint(player.transform,Vec(0.2,0.4,-0.2)),VecScale(TransformToParentVec(player.headTransform,Vec(0,-1,0)),dist))
    local hit, dist, normal, shape = QueryRaycast(TransformToParentPoint(player.transform,Vec(-0.2,0.4,-0.2)),TransformToParentVec(player.headTransform,Vec(0,-1,0)),0.4,0,false)
    point2 = VecAdd(TransformToParentPoint(player.transform,Vec(-0.2,0.4,-0.2)),VecScale(TransformToParentVec(player.headTransform,Vec(0,-1,0)),dist))
    local hit, dist, normal, shape = QueryRaycast(TransformToParentPoint(player.transform,Vec(-0.2,0.4,0.2)),TransformToParentVec(player.headTransform,Vec(0,-1,0)),0.4,0,false)
    point3 = VecAdd(TransformToParentPoint(player.transform,Vec(-0.2,0.4,0.2)),VecScale(TransformToParentVec(player.headTransform,Vec(0,-1,0)),dist))
    local hit, dist, normal, shape = QueryRaycast(TransformToParentPoint(player.transform,Vec(0.2,0.4,0.2)),TransformToParentVec(player.headTransform,Vec(0,-1,0)),0.4,0,false)
    point4 = VecAdd(TransformToParentPoint(player.transform,Vec(0.2,0.4,0.2)),VecScale(TransformToParentVec(player.headTransform,Vec(0,-1,0)),dist))

    return VecLerp(VecLerp(point1,point2,0.5),VecLerp(point3,point4,0.5),0.5)
end

function playerInit()
    player = {}
    player.vel = 0
    player.body = FindBody('player')
    player.transform = GetBodyTransform(player.body)
    player.pos = player.transform.pos
    player.rot = player.transform.rot
    
    player.headTransform = Transform(TransformToParentPoint(player.transform,(Vec(0,1.8,0))),player.rot)
    player.headPos = player.headTransform.pos
    player.headRot = player.headTransform.rot

    player.pitch = 0
    local min, max GetBodyBounds(player.body)
    player.center = TransformToParentPoint(player.transform, VecLerp(min,max,0.5))
    
    player.parent = 0 
    player.camera = true
    local hit, shape, point = IsPlayerOnGround()
    player.onGroud = hit
    player.contactPoint = point
    player.onPlanetTransform = -1

    local shapes = GetBodyShapes(player.body)
    for i=1,#shapes do 
        Delete(shapes[i])
    end
    player.camera = "player" 
    player.vehicleBody = GetVehicleBody(GetPlayerVehicle())

    player.inputDown = false
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
        if HasTag(planet.body,'type') then planet.type = GetTagValue(planet.body, 'type') else planet.type = "attract" end -- can be either attract(default) or repel
        planets[num] = planet 
    end 
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

function playerUpdate(dt)

    -------------------------------------------------- Player State --------------------------------------------------
    player.transform = GetBodyTransform(player.body)
    player.pos = player.transform.pos
    player.rot = player.transform.rot
    player.headTransform = Transform(TransformToParentPoint(player.transform,(Vec(0,1.8,0))),player.rot)
    player.headPos = player.headTransform.pos
    player.headRot = player.headTransform.rot
    --DebugLine(player.pos,player.headPos,1,1,1,1)
    player.center = TransformToParentPoint(player.transform, GetBodyCenterOfMass(player.body))
    local vel = GetBodyVelocity(player.body)
    player.vel = VecAdd(vel,Vec(0, 10*dt, 0))-- kind of counteract gravity
    local cameray = InputValue('cameray')*-40 
    player.pitch = player.pitch + cameray
    player.pitch = Clamp(player.pitch, -90, 90)
    -- Clamp pitch between 80 and -80

    local hit, shape, point = IsPlayerOnGround()
    player.onGround = hit
    player.contactPoint = playerContactPoint()
    player.vehicleBody = GetVehicleBody(GetPlayerVehicle())
    player.inGravity = "planet"
    player.strongestGravity = 0

end

function planetGravity(dt)
    local prevStr = 0
    for i=1,#planets do
        local planet = planets[i]
        local dir = VecNormalize(VecSub(planet.center,player.center))
        local dist = VecDist(planet.center,player.pos)
        local gravConst = 1
        local strength = dt*(gravConst*planet.mass / (dist * dist))
        if player.strongestGravity < strength then  
            player.parent = planet.body
            player.inGravity = "planet"
            player.strongestGravity = strength
        end
        if planet.type == "repel" then
            strength = strength* -1
        end
        player.vel = VecAdd(player.vel,VecScale(dir,strength))
    end
end

function attractorGravity(dt)
    for i=1,#gravityFields do
        local field = gravityFields[i] 
        local pCenter = VecLerp(player.pos,player.headPos,0.5)
        local closestPoint = GetTriggerClosestPoint(field.trigger, pCenter)
        local dist = Clamp(VecDist(closestPoint,pCenter),12,10000000000)
        local dir = Vec()
        local gravConst = 1
        local strength = 0

        if field.type == "global" then
            if IsPointInTrigger(field.trigger, pCenter) then 
                dir = VecCopy(field.pullDir)
            else
                dir = VecNormalize(VecSub(closestPoint,pCenter))
            end
            strength = dt*(gravConst*field.strength / (dist * dist))
            if field.exclusive == true then 
                player.vel = VecAdd(Vec(0,10*dt,0),GetBodyVelocity(player.body))
                player.vel = VecAdd(player.vel,VecScale(dir,strength))
                player.parent = field
                player.inGravity = "attractor"
                player.strongestGravity = strength
                break
            end
            if player.strongestGravity < strength then  
                player.parent = field
                player.inGravity = "attractor"
                player.strongestGravity = strength
            end

            player.vel = VecAdd(player.vel,VecScale(dir,strength))
        elseif field.type == "local" then
            if IsPointInTrigger(field.trigger, pCenter) then
                dir = VecCopy(field.pullDir)
                strength = dt*(gravConst*field.strength / (dist * dist))
                if field.exclusive == true then 
                    player.vel = VecAdd(Vec(0,10*dt,0),GetBodyVelocity(player.body))
                    player.vel = VecAdd(player.vel,VecScale(field.pullDir,strength))
                    player.parent = field
                    player.inGravity = "attractor"
                    player.strongestGravity = strength
                    break
                end 
                if player.strongestGravity < strength then 
                    player.parent = field
                    player.inGravity = "attractor"
                    player.strongestGravity = strength
                end
                player.vel = VecAdd(player.vel,VecScale(field.pullDir,strength))
            end
        end
    end
end

function debugPlayer(dt)
    DebugWatch("vel",VecLength(player.vel))
    DebugWatch("player.pitch",player.pitch)

    local x,y,z = GetQuatEuler(player.rot)
    DebugWatch("player.rot.x",Vec(x,y,z))

 
    DebugLine(player.headPos,TransformToParentPoint(player.headTransform,Vec(0,-1,0)))
    DebugLine(player.headPos,TransformToParentPoint(player.headTransform,Vec(0,0,-1)),0,1,1,1)
end


function playerController()
    if player.camera ~= "independent" then
        player.inputDown = false
        if InputDown("up") and player.onGround then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,-0.25)))
            player.inputDown = true
        elseif InputDown("up") and player.onGround == false then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,-0.05)))
            player.inputDown = true
        end

        if InputDown("down") and player.onGround then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,0.25)))
            player.inputDown = true
        elseif InputDown("down") and player.onGround == false then
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0,0,0.05)))
            player.inputDown = true
        end

        if InputDown("left") and player.onGround then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(-0.25,0,0)))
            player.inputDown = true
        elseif InputDown("left") and player.onGround == false then
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(-0.05,0,0)))
            player.inputDown = true
        end

        if InputDown("right") and player.onGround then 
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0.25,0,0)))
            player.inputDown = true
        elseif InputDown("right") and player.onGround == false then
            player.vel = VecAdd(player.vel,TransformToParentVec(player.transform, Vec(0.05,0,0)))
            player.inputDown = true
        end

        if InputDown("space") and player.onGround then 
            ConstrainVelocity(player.body,0,player.center,TransformToParentVec(player.transform,Vec(0,1,0)),10)
            player.inputDown = true
        end
    end
end

function playerTool(dt)
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
            local hit, point, normal , shape = QueryClosestPoint(tool.hookTransform.pos,1.5)

            if hit and tool.hookEngaged == false and VecDist(player.pos,tool.hookTransform.pos) > 5 then 
                tool.hookEngaged = true
                tool.hookedBody = GetShapeBody(shape)
                local bt = GetBodyTransform(tool.hookedBody)
                tool.hookLocalTransform = TransformToLocalTransform(bt,tool.hookTransform)
            end

            if tool.hookEngaged == true then
                if tool.flashTimer > 0 then 
                    tool.flashTimer = tool.flashTimer - dt
                    DrawOutlineBlink(tool.hookedBody,1,2,1,1,1,1)
                end

                ConstrainPosition(tool.hookBody,tool.hookedBody,tool.hookTransform.pos,TransformToParentTransform(GetBodyTransform(tool.hookedBody),tool.hookLocalTransform).pos)
                if InputDown("usetool") and VecDist(player.pos,tool.hookTransform.pos) > 1 then 
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

function DrawOutlineBlink(entity, speed, time, red, green, blue, alphamulti)
    speed = speed or 1
    time = GetTime()
    red = red or 1
    green = green or 1
    blue = blue or 1
    alphamulti = alphamulti or 1

    local t = (time * speed) % 2
    local alpha = logistic(t, 1, -15, 0.4) * logistic(t, 1, 15, 1.4)

    local type = GetEntityType(entity)
    if type == 'body' then
        DrawBodyHighlight(entity, alpha * alphamulti)
        DrawBodyOutline(entity, red, green, blue, alpha * alphamulti)
    elseif type == 'shape' then
        DrawBodyHighlight(entity, alpha * alphamulti)
        DrawShapeOutline(entity, red, green, blue, alpha * alphamulti)
    end
end


function  update(dt)

    playerUpdate(dt)
    planetsUpdate(dt)
    planetGravity(dt)
    attractorsUpdate()
    attractorGravity(dt)
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
   local alignWith = Vec()
   local planetShape = 0
    if player.inGravity == "planet" then
        local shapes = GetBodyShapes(player.parent)
        for i=1, #shapes do 
            if HasTag(shapes[i],"planet") then 
                planetShape = shapes[i]
                break
            end
        end
        local min, max = GetShapeBounds(planetShape)
        alignWith = VecLerp(min,max,0.5)
    elseif player.inGravity == "attractor" then
        alignWith = TransformToParentPoint(player.parent.transform,VecAdd(TransformToLocalPoint(player.parent.transform,player.pos),Vec(0,-1,0)))
    end
    local xAxis = VecNormalize(VecSub(player.headPos,alignWith))
    local zAxis = VecNormalize(VecSub(alignWith,TransformToParentPoint(player.headTransform,Vec(0,0,-1))))
    local down = QuatRotateQuat(QuatAlignXZ(xAxis, zAxis),QuatEuler(0,0,-90))
    if GetTagValue(GetShapeBody(planetShape),"type") == "repel" then 
        down = QuatRotateQuat(QuatAlignXZ(xAxis, zAxis),QuatEuler(0,0,90))
    end
    
    local camerax = InputValue("camerax")*-50
    player.rot = QuatRotateQuat(down,QuatEuler(0,camerax,0))



    
    
    SetBodyTransform(player.body,Transform(player.pos,player.rot))
 
    
    -------------------------------------------------- Player Standing on Surface --------------------------------------------------
    QueryRejectBody(player.body)
    local hit, dist, normal, shape = QueryRaycast(TransformToParentPoint(player.transform,Vec(0,0.4,0)),TransformToParentVec(player.headTransform,Vec(0,-1,0)),0.5,0,false)

    if hit then 
        local t = Transform(VecLerp(player.contactPoint,GetBodyTransform(player.body).pos,0.7),player.rot)
        SetBodyTransform(player.body,t)
        local onPlanetVel = TransformToLocalVec(player.transform,player.vel)
        player.vel = TransformToParentVec(player.transform,Vec(onPlanetVel[1],0,onPlanetVel[3]))

    end


--  if hit then
--      DebugCross(point,1,1,1,1)
--     -- ConstrainVelocity(player.body,0,TransformToParentPoint(player.transform, Vec(0,1,0)),VecSub(TransformToParentPoint(player.transform, Vec(0,1,0)),point),10*0.5-VecDist(player.pos,point)*10) 
--      DebugLine(TransformToParentPoint(player.transform, Vec(0,1,0)),VecAdd(TransformToParentPoint(player.transform, Vec(0,1,0)),VecSub(TransformToParentPoint(player.transform, Vec(0,1,0)),point)),1,1,1,1)
--      ConstrainPosition(player.body,0,TransformToParentPoint(player.transform, Vec(0,0,0)),VecAdd(TransformToParentPoint(player.transform, Vec(0,0,0)),VecSub(TransformToParentPoint(player.transform, Vec(0,0,0)),point)),10)
--  end

    -------------------------------------------------- Air Resistance --------------------------------------------------

    player.vel = VecScale(player.vel,0.99)

    -------------------------------------------------- Player Planet Friction --------------------------------------------------

    local hit, shape, point = IsPlayerOnGround()
    local planetBody = GetShapeBody(shape)
    local bt = GetBodyTransform(planetBody)
    if hit and HasTag(planetBody,"planet") then
        local FinalVel = GetBodyVelocityAtPos(planetBody,player.contactPoint)
        local onPlanetVel = TransformToLocalVec(player.transform,player.vel)
        

        if VecLength(FinalVel)+0.02<VecLength(onPlanetVel) and player.onGround then
            dontMove = false
            if player.inputDown == false then 
                local coef = clamp(1+(VecLength(player.vel)-10)/10,0.85,1)
                player.vel = VecScale(player.vel,coef)
            end
        else
            if dontMove == false then
                player.onPlanetTransform = TransformToLocalTransform(bt,player.transform)
                dontMove = true
            end
            local camerax = InputValue("camerax")*-60
            player.onPlanetTransform.rot = QuatRotateQuat(player.onPlanetTransform.rot,QuatEuler(0,camerax,0))
            local newT = TransformToParentTransform(bt,player.onPlanetTransform)
            SetBodyTransform(player.body,Transform(VecLerp(newT.pos,player.pos,0.9),newT.rot))
        end
    else
        dontMove = false
    end

    -------------------------------------------------- Gravity --------------------------------------------------

     --SetPlayerTransform(t,true)

    if VecLength(player.vel) < 0.2 and hit then 
        player.vel = 0
        ConstrainPosition(player.body,0,player.pos,player.pos)
    end

    -------------------------------------------------- Collision --------------------------------------------------

    QueryRejectBody(player.body)
    local hit1, point1, normal1 = QueryClosestPoint(TransformToParentPoint(player.transform, Vec(0.1,0.6,-0.1)), 0.3)
    local hit2, point2, normal2 = QueryClosestPoint(TransformToParentPoint(player.transform, Vec(-0.1,0.6,-0.1)), 0.3)
    local hit3, point3, normal3 = QueryClosestPoint(TransformToParentPoint(player.transform, Vec(-0.1,0.6,0.1)), 0.3)
    local hit4, point4, normal4 = QueryClosestPoint(TransformToParentPoint(player.transform, Vec(0.1,0.6,0.1)), 0.3)
    if hit1 and hit2 then 
        local normal = VecNormalize(VecAdd(normal1,normal2))
        --DebugCross(point1,1,1,1,1)
        --DebugCross(point2,1,1,1,1)
        player.vel = VecLerp(VecSub(player.vel, VecScale(normal, VecDot(normal, player.vel))),player.vel,0.78)
    elseif hit2 and hit3 then
        --DebugCross(point2,1,1,1,1)
        --DebugCross(point3,1,1,1,1)
        local normal = VecNormalize(VecAdd(normal2,normal3))
        player.vel = VecLerp(VecSub(player.vel, VecScale(normal, VecDot(normal, player.vel))),player.vel,0.78)
    elseif hit3 and hit4 then 
        --DebugCross(point3,1,1,1,1)
        --DebugCross(point4,1,1,1,1)
        local normal = VecNormalize(VecAdd(normal3,normal4))
        player.vel = VecLerp(VecSub(player.vel, VecScale(normal, VecDot(normal, player.vel))),player.vel,0.78)
    elseif hit4 and hit1 then 
        --DebugCross(point4,1,1,1,1)
        --DebugCross(point1,1,1,1,1)
        local normal = VecNormalize(VecAdd(normal4,normal1))
        player.vel = VecLerp(VecSub(player.vel, VecScale(normal, VecDot(normal, player.vel))),player.vel,0.78)
    end

    -------------------------------------------------- PlayerMove --------------------------------------------------

    if GetPlayerVehicle() ~= 0 then
        ConstrainPosition(player.body,0,player.pos, GetBodyTransform((GetVehicleBody(GetPlayerVehicle()))).pos)
    else
        SetBodyVelocity(player.body,player.vel)
    end

end

dontMove = false
----------------------------------------------------- Helper Functions -----------------------------------------------------

function IsPlayerOnGround()
    QueryRejectBody(player.body)
    local hit, dist, normal, shape = QueryRaycast(TransformToParentPoint(player.transform,Vec(0,0.4,0)),TransformToParentVec(player.headTransform,Vec(0,-1,0)),0.5,0,false)
    return hit,shape, VecAdd(TransformToParentPoint(player.transform,Vec(0,0.4,0)),VecScale(TransformToParentVec(player.headTransform,Vec(0,-1,0)),dist))
end

function Clamp(value, mi, ma)
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
        local pos = TransformToParentPoint(player.headTransform,Vec(0,0,0))
        local rot = QuatRotateQuat(player.rot,QuatEuler(player.pitch,0,0))
        local t = Transform(pos,rot)

        SetCameraTransform(t)
    elseif player.camera == "independent" then
        DebugLine(GetPlayerTransform().pos,player.headPos)
    elseif player.camera == "player" then    
        local pos = VecAdd(TransformToParentPoint(player.headTransform,Vec(0,0,0)),Vec(0,-1.8,0))
        local rot = QuatRotateQuat(player.rot,QuatEuler(player.pitch,0,0))
        local t = Transform(pos,rot)
        
        SetPlayerTransform(t, true) 
    end

--This needs way more work someone that understands quats shuold take a look 
    if player.vehicleBody ~= 0 then
    local mouse = {
        dx = InputValue("camerax"),
        dy = InputValue("cameray"),
        scroll = InputValue("mousewheel")
    }
    local x, y, z = GetQuatEuler(cam.rot)
    local camX = QuatRotateQuat(QuatEuler(x, 0, 0), QuatEuler(-mouse.dy * 15, 0, 0))
    local camY = QuatRotateQuat(QuatEuler(0, y, 0), QuatEuler(0, -mouse.dx * 15, 0))
    cam.rot = QuatRotateQuat(camY, camX)
    camDist = rebound(camDist - mouse.scroll, 0, 20)
    x, y, z = GetQuatEuler(cam.rot)
    cam.pos = VecAdd(Vec(0, 2.8, 0),VecScale(Vec(math.sin(math.pi * y / 180), -math.sin(math.pi * x / 180), math.cos(math.pi * y / 180)), camDist))
    SetCameraTransform(TransformToParentTransform(GetVehicleTransform(GetPlayerVehicle()), cam))
    end
end
cam = Transform()
camDist = 5

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

function rebound(value, min, max)
    return math.max(min, math.min(max, value))
end

function TransformLerp(a,b,t)
    return Transform(VecLerp(a.pos,b.pos,t),QuatSlerp(a.rot,b.rot,t))
end

function draw(dt)
   -- local prevStr = 0
   -- for i=1,#planets do
   --     local planet = planets[i]
   --     local dist = VecDist(planet.center,player.pos)
   --     local gravConst = 1
   --     local strength = dt*(gravConst*planet.mass / (dist * dist))
   --     local x, y = UiWorldToPixel(planet.center)
   --     if IsBodyVisible(planet.body,200) then
   --         UiTooltip(strength,2,"center",{x,y},5)
   --     end
   -- end
   -- for i=1,#gravityFields do
   --     local field = gravityFields[i] 
   --     local pCenter = VecLerp(player.pos,player.headPos,0.5)
   --     local closestPoint = GetTriggerClosestPoint(field.trigger, pCenter)
   --     local dist = Clamp(VecDist(closestPoint,pCenter),12,10000000000)
   --     local gravConst = 1
   --     strength = dt*(gravConst*field.strength / (dist * dist))
   --     local x, y = UiWorldToPixel(closestPoint)
   --     UiTooltip(strength,2,"center",{x,y},5)
   -- end
end