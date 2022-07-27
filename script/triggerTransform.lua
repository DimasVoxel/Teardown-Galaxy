function init()
    body = FindBody("triggerparent")
    trigger = FindTrigger("gravityfield")

    local bt = GetBodyTransform(body)
    local tt = GetTriggerTransform(trigger)
    triggerLocalTransform = TransformToLocalTransform(bt, tt)

    DebugWatch("trigger", trigger)
    DebugWatch("body",body)
end

function tick()
    local bt = GetBodyTransform(body)
    SetTriggerTransform(trigger, TransformToParentTransform(bt, triggerLocalTransform))
end