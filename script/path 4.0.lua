#include ./Automatic-Framework/Automatic.lua

function init()
    roadPiece = 3*GetIntParam("totalsegments", 20)

    bez = {}

    segments = FindBodies("segment")

    for i=1, #segments do 
        table.insert(bez,GetBodyTransform(segments[i]))
    end
  
    
    curve = {}
    local smooth = {}
    local i = 1
    while (i < #bez) do
        local newList = {}
        local segment = {}

        for j=1, 3 do
            if i > #bez then 
                i = i + 1
                break
            end
            newList[#newList+1] = TransformCopy(bez[i])
            i = i + 1
        end

        local c = #newList/3
        local roadPieces = roadPiece*c
        DebugPrint(#smooth)
        if #smooth ~= 0 then 
            for j=1, #smooth do 
                local smoothInfo = smooth[j]
                local info = {}
                info.t = TransformLerp(bezier(newList,j/roadPieces),smoothInfo.t,0.5)
                segment[#segment+1] = info 
            end

            for j=#smooth, roadPieces do
                local info = {}
                info.t = bezier(newList,j/roadPieces)
                segment[#segment+1] = info 
            end
        else 
            for j=1 , roadPieces do
                local info = {}
                info.t = bezier(newList,j/roadPieces)
                segment[#segment+1] = info
            end
        end
        
        smooth = {}
        for j=(#segment-#segment/3)+1, #segment do 
            local info = segment[j]
            smooth[#smooth+1] = info
        end
        for j=1, (#segment-(#segment/3)) do 
            curve[#curve+1] = segment[j]
        end


        i = i - 2
    end
end

function tick()
    for i=1, #curve do 
        local info = curve[i]
        DebugLine(info.t.pos,TransformToParentPoint(info.t,Vec(0,3,0)),0,0,0,1)
    end

    local prev = Transform()
    for i=1, #bez do 
        local t = bez[i]
        if i ~= 1 then 
            DebugLine(t.pos,prev.pos,1,1,1,1)
        end
        prev = TransformCopy(t)
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