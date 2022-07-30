#include ./Automatic-Framework/Automatic.lua


function init()


    totalSegments = GetIntParam("totalsegments", 100)

    bez = {}

    locations = FindLocations("location",false)

    for nums,locs in ipairs(locations) do
        for num,loc in ipairs(locations) do
            if tonumber(GetTagValue(loc,"location")) == nums then 
                table.insert(bez,GetLocationTransform(loc))
                
            end
        end
    end

    local t = Transform()
    local prev = Transform()

    for i=1, totalSegments do 
        if i == 1 then 
            prev = bezier(bez,i/totalSegments)
        else 
            t = bezier(bez,i/totalSegments)
            
            local dist = math.ceil(AutoVecDist(prev.pos,t.pos)*10)
            local rot = QuatRotateQuat(t.rot,QuatLookAt(prev.pos,t.pos))

            local XML = [[
            	<body pos="0 0 0" dynamic="false">
                    <voxbox pos="-3.0 0.0 0.0" rot="0" size="60 5 ]]..dist..[["/>
                </body>
            ]]
            Spawn(XML,Transform(t.pos,rot),true)
            prev = TransformCopy(t)
        end
    end
end

function TransformLerp(a,b,t)
    return Transform(VecLerp(a.pos,b.pos,t),QuatSlerp(a.rot,b.rot,t))
end

function bezier(lerparray, frame)
    local newlerparray = {}
    while #lerparray > 1 do 
        for i=1, #lerparray-1 do
            table.insert(newlerparray,TransformLerp(lerparray[i],lerparray[i+1],frame))
        end
        if #newlerparray == 1 then
            return newlerparray[1]
        else 
            lerparray = AutoTableDeepCopy(newlerparray)
            newlerparray = {}
        end
    end
end

function tick()


    totalSegments = GetIntParam("totalsegments", 100)

    bez = {}

    locations = FindLocations("location",false)

    for nums,locs in ipairs(locations) do
        for num,loc in ipairs(locations) do
            if tonumber(GetTagValue(loc,"location")) == nums then 
                table.insert(bez,GetLocationTransform(loc))
            end
        end
    end

    local t = Transform()
    local prev = Transform()

    for i=1, totalSegments do 
        if i == 1 then 
            prev = bezier(bez,i/totalSegments)
        else 
            t = bezier(bez,i/totalSegments)

            DebugLine(prev.pos,t.pos,0,0,0,1)
            prev = TransformCopy(t)
        end
    end
end
