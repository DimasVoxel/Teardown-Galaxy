function init()
    local planetShape = FindShape('planet')
    planet = {}
    planet.shape = planetShape
    planet.body = GetShapeBody(planetShape)
    planet.transform = GetBodyTransform(planet.body)
    local min, max = GetShapeBounds(planet.shape)
    planet.center = VecLerp(min,max,0.5)
    planet.originalTransform = planet.transform

    planet.mass = tonumber(GetTagValue(planetBody, 'mass'))
    local vel = GetBodyVelocity(planet.body)
end

function planetUpdate(dt)
    -------------------------------------------------- planet State --------------------------------------------------
    planet.transform = GetBodyTransform(planet.body)
    planet.center = TransformToParentPoint(planet.transform, GetBodyCenterOfMass(planet.body))
    local vel = GetBodyVelocity(planet.body)
    planet.vel = VecAdd(vel,Vec(0, 10*dt, 0))-- kind of counteract gravity
end

function planetPhysics()
    ConstrainPosition(planet.body, 0, planet.center,planet.originalTransform.pos)
    ConstrainAngularVelocity(planet.body, 0, Vec(0,0,-1),0.2)
end

function update(dt)
    planetUpdate(dt)
    planetPhysics(dt)
    
end