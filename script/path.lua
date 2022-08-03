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

            local dist = AutoVecDist(prev.pos,t.pos)*10
            local middle = dist/10/2
            local XML = [[
                <body pos="0 0 0" dynamic="false">
                    <voxbox pos="-3 -0.25 ]]..middle..[[" rot="0" size="60 5 ]]..dist..[["/>
                </body>
            ]]
            Spawn(XML,t,true)
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
