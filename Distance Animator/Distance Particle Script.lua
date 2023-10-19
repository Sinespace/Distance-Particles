
myObj = Space.Host.ExecutingObject
myPlayer = Space.Scene.PlayerAvatar

maxDist = maxDist or 1.0
speed = speed or 0.5
maxSpeed = maxSpeed or 1.0
deltaSpeed = deltaSpeed or 3
dieOff = dieOff or true
mobile = mobile or false

particleObj = myObj
if Space.Host.ReferenceExistsAndNotEmpty("Particles") then
    particleObj = Space.Host.GetReference("Particles")
end

baseSpeed = 0

lastDist = 0
curDist = 0
curPos = myPlayer.GameObject.WorldPosition
myPos = particleObj.WorldPosition
myLastPos = particleObj.WorldPosition
lastPos = myPlayer.GameObject.WorldPosition
distanceMoved = 0.0

simSpeed = 0.0
targetSpeed = 0.0

isDormant = true
isAnimated = false

systems = {}
systemCount = 0
systemIterator = 0

findChildrenCount = 0
function findParticlesInChildren(object)
    if object.ParticleSystem ~= nil then
        table.insert(systems, object.ParticleSystem)
        systemCount = systemCount + 1
        local children = object.children
        for c=1, #children, 1 do
            if children[c].Active then
                findParticlesInChildren(children[c])
            end
            findChildrenCount = findChildrenCount + 1
            if findChildrenCount % 10 == 0 then
                coroutine.yield(0.01)
            end
        end
    end
    return false
end

particleIterator = 0
function setPlaybackSpeedForAll(newSpeed)
    for systemIterator = 1, systemCount do
        systems[systemIterator].PlaybackSpeed = newSpeed
    end
end

function stopAllParticles()
    for systemIterator = 1, systemCount do
        systems[systemIterator].Stop()
    end
end

function startAllParticles()
    for systemIterator = 1, systemCount do
        systems[systemIterator].Play()
    end
end

function pauseAllParticles()
    for systemIterator = 1, systemCount do
        systems[systemIterator].Pause()
    end
end

function onUpdate()
    curPos = myPlayer.GameObject.WorldPosition
    myPos = particleObj.WorldPosition
    curDist = myPos.Distance(curPos)
    if lastPos ~= nil and lastDist ~= curDist then
        distanceMoved = lastPos.Distance(curPos)
        if mobile and distanceMoved <= 0 then
            distanceMoved = myLastPos.Distance(myPos)
        end
    else
        distanceMoved = 0
    end
    lastDist = curDist
    lastPos = curPos
    myLastPos = myPos
    if curDist <= maxDist then
        if isDormant then
            isDormant = false
            startAllParticles()
            pauseAllParticles()
        end
        if distanceMoved > 0 then
            targetSpeed = distanceMoved / speed
            if targetSpeed > maxSpeed then
                targetSpeed = maxSpeed
            end
        else
            targetSpeed = 0
        end
        if targetSpeed ~= simSpeed then
            simSpeed = Space.Math.Lerp(simSpeed, targetSpeed, (Space.DeltaTime * deltaSpeed))
            if simSpeed < 0.01 then
                simSpeed = 0
            end
        end
        if simSpeed > 0 then
            isAnimated = true
            setPlaybackSpeedForAll(simSpeed)
            startAllParticles()
        elseif isAnimated then
            isAnimated = false
            pauseAllParticles()
        end
    else
        if not isDormant then
            isDormant = true
            if dieOff then
                stopAllParticles()
            else
                pauseAllParticles()
            end
        end
    end
end

function init()
    findParticlesInChildren(particleObj)
    startAllParticles()
    pauseAllParticles()

    myObj.OnUpdate(onUpdate)
end

Space.Host.StartCoroutine(init)
