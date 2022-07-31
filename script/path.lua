#include ./Automatic-Framework/Automatic.lua


function init()


    totalSegments = GetIntParam("totalsegments", 100)

    bez = {}

    segments = FindBodies("segment")
    for i=1, #segments do 
        table.insert(bez,GetBodyTransform(segments[i]))

    end


    local t = Transform()
    local prev = Transform()

    for i=1, totalSegments do 
        if i == 1 then 
            prev = bezier(bez,i/totalSegments)
        else 
            t = bezier(bez,i/totalSegments)

            local dist = math.ceil(AutoVecDist(prev.pos,t.pos)*10)
            local xAxis = VecNormalize(VecSub(t.pos, prev.pos))
            local zAxis = VecNormalize(VecSub(VecLerp(t.pos,prev.pos,0.5), TransformToParentPoint(t, VecAdd(TransformToLocalPoint(t,VecLerp(t.pos,prev.pos,0.5)),Vec(0, -1,0)))))
            local rot = QuatAlignXZ(xAxis, zAxis)

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

    segments = FindBodies("segment")

    for nums,_ in ipairs(segments) do
        for num,segment in ipairs(segments) do
            if tonumber(GetTagValue(segment,"segment")) == nums then 
                table.insert(bez,GetBodyTransform(segment))
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

            local n = VecNormalize(VecSub(VecLerp(t.pos,prev.pos,0.5), TransformToParentPoint(t, VecAdd(TransformToLocalPoint(t,VecLerp(t.pos,prev.pos,0.5)),Vec(0, -1,0)))))
            DebugLine(VecLerp(t.pos,prev.pos,0.5),VecAdd(t.pos,n),0.1,0.1,0.1,1)

            DebugLine(t.pos,TransformToParentPoint(t, Vec(0, 1,0)),1,0,1,1)
            DebugLine(prev.pos,t.pos,0,0,0,1)
            prev = TransformCopy(t)
        end
    end
end
