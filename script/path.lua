#include ./Automatic-Framework/Automatic.lua


function init()


    totalSegments = 20--GetIntParam("totalsegments", 100)

    bez = {}

    segments = FindBodies("segment")
    for i=1, #segments do 
        table.insert(bez,GetBodyTransform(segments[i]))
        --table.insert(bez,getGoodTransform(segments[i]))

    end


    blocs = {}
    sizes = {}
    local t = Transform()
    local prev = Transform()

    for i=1, totalSegments do 
        if i == 1 then 
            prev = bezier(bez,i/totalSegments)
        else 
            t = bezier(bez,i/totalSegments)

            local dist = math.ceil(VecLength(VecSub(prev.pos,t.pos))*10)
            local middle = dist/10/2
            local XML = [[
                <body pos="0 0 0" dynamic="false">
                    <voxbox pos="-3 -0.25 ]]..middle..[[" rot="0" size="60 5 ]]..dist..[["/>
                </body>
            ]]
            local st = getGoodTransformT(t, Vec(6, 0.5, dist / 10))
            local rot = QuatLookAt(prev.pos, st.pos)
            st.rot = rot
            local ent = Spawn(XML,st,true)
            prev = TransformCopy(t)
            for i=1, #ent do
                if GetEntityType(ent[i]) == "body" then
                    blocs[#blocs + 1] = ent[i]
                    sizes[#sizes + 1] = Vec(60 / 10, 5 / 10, dist / 10)
                    break
                end
            end
        end
    end
    
end
-- put this in your file
function getGoodTransformT(t, size)
    local dx = size[1]
    local dy = size[2]
    local dz = size[3]
    local b = Vec(0, 0, -dz/2)
    return Transform(TransformToParentPoint(t, b))
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
