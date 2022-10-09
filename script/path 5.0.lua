#include ./Automatic-Framework/Automatic.lua

function init()
    roadPieces = 3*GetIntParam("totalsegments", 20)

    points = FindBodies("segment")
    segments = {}
    local list = {}
    local loopCount = 1
    for i=1, #points do
        local segment = {}
        list = {}

        for j=loopCount, loopCount+2 do 
            list[#list+1] = GetBodyTransform(points[j])
            loopCount = loopCount + 1
            if #points < loopCount  then 
                break 
            end
        end
    
        loopCount = loopCount - 2
        for j=1, roadPieces do 
            local data = {}
            data.t = bezier(list,j/roadPieces)
            segment[#segment+1] = data
        end
        segments[i] = segment

        if #points < loopCount  then 
            break 
        end
    end

    curve = {}

    for i=1,#segments do 
        if i ~= 1 then 
            local segment = segments[i-1]
            local nextSegment = segments[i]
            for j=1, (roadPieces/3)+(roadPieces/3) do
                local data = {}
                local segmentData = segment[j]
                data.t = TransformCopy(segmentData.t)
                curve[#curve+1] = data
            end
            for j=1, roadPieces/3 do
                local data = {}
                local segmentData = segment[roadPieces-(roadPieces/3-j)]
                local nextSegmentData = nextSegment[j]

                data.t = TransformLerp(segmentData.t,nextSegmentData.t,0.5)
                curve[#curve+1] = data
            end
        end
    end
end


    function tick()

        for i=1,#curve do 
         local data = curve[i] 

         DebugLine(data.t.pos,TransformToParentPoint(data.t,Vec(0,3,0)),0,0,0,1)
    
         end
    end

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
    if #lerparray == 1 then 
        return lerparray[1]
    end
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

function TransformToLocalQuat(parentT,quat) 
    local childT = Transform(Vec(),quat)
    local t = TransformToLocalTransform(parentT,childT)
    return t.rot
end

function TransformToParentQuat(parentT,quat)
    local childT = Transform(Vec(),quat)
    local t = TransformToParentTransform(parentT,childT)
    return t.rot
end




--[[
<script pos="0.0" rot="00 0.0 0.0" file="MOD/script/triggerTransform.lua">
    <body tags="triggerparent" pos="0.0 0.0 0.0" dynamic="false">
        <voxbox pos="0.0 0.0 0.0" size="70 15 90" brush="MOD/vox/road.vox">
            <trigger tags="gravityfield mass=1000 type=local exclusive" pos="3.5 0.0 4.5" type="box" size="7 8 9"/> --pos is half of the size of the road and devided by 10
        </voxbox>
    </body>
</script>
]]