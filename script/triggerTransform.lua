function init()
    body = FindBody("triggerparent")
    foundTriggers = FindTriggers("gravityfield")

    triggers = {}
    local bt = GetBodyTransform(body)

    for i=1, #foundTriggers do 
        local trigger = {}
        trigger.trigger = foundTriggers[i]
        local tt = GetTriggerTransform(foundTriggers[i])
        trigger.localTransform = TransformToLocalTransform(bt, tt)
        triggers[i] = trigger
    end
end

function tick()
    local bt = GetBodyTransform(body)

    for i=1,#triggers do 
        local trigger = triggers[i]
        SetTriggerTransform(trigger.trigger, TransformToParentTransform(bt, trigger.localTransform))
       -- DebugLine(GetTriggerTransform(trigger.trigger).pos,TransformToParentPoint(GetTriggerTransform(trigger.trigger),Vec(0,5,0)),1,1,1,1)
    end
end