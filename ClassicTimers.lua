------------------------------------- Classic Timers library for DOTA 2 Created by Goshante, 2020 -------------------------------------
--------------------------------------------------------------- v1.2 ------------------------------------------------------------------
--
-- What the hell is this?
--      This is recreation of classic timers Warcraft III JASS system for DOTA 2 lua scripting with 
--      some improvements. Library is not object-oriented. Only procedure functional calls.
-- 
-- But why?
--      There are many Warcraft map developers who switched to DOTA 2. Here we have very poor and 
--      super complicated timing feature with entity thinkers. The only popular timers lib looks
--      too different comparing to classic timer system and not so convinient. This timer system
--      is very close to original JASS timers with huge improvements. Super easy to use!
--
-- How to include into my project?
--       1. Include with require()
--       2. In addon_game_mode.lua remove GameRules:GetGameModeEntity():SetThink line and remove related OnThink function
--       3. In function CAddonTemplateGameMode:InitGameMode() call InitClassicTimers() function
--
-- How to use it? Lol, easy!
--      1. Create timer: local timer = CreateTimer()
--      2. Start it with TimerStart()!
--
--      ?. Explaining CreateTimer argument: CreateTimer(selfDestruct)
--          selfDestruct (bool)      - Optional. Can be nil or ignored. Destroy timer automatically after it's done.
--                                     Timers is non-self-destructive by default and required to be destroyed by DestroyTimer(timer)
--
--      ?. Explaining TimerStart arguments: TimerStart(timer, period, maxTime, isPeriodic, func, firstDelay)
--          timer (handle)           - timer handle returned by CreateTimer() 
--
--          period (float)           - Timer tick interval (for non-periodic mode this is full timer delay)
--
--          maxTime (float)          - ignored when non-periodic, required when periodic. Maximum amount of time for full timer run
--
--          isPeriodic (bool)        - if true - timer is periodic, if false - non-periodic. Non-periodic timer will trigger once
--          after 'period' amount of time and stop. Periodic will trigger every 'period' and end after maxTime elapsed.
--
--          func (function or table) - timer callback function. There is 2 ways of using this argument: only function - just pass function to it.
--          And function + arguments. Use it like this: {fn = myCallback, args = myArgs}
--          In this case fn is callback and args is arguments. If you don't care about arguments just pass function or lambda
--          in func without any {} table.
--          
--          firstDelay (float)       - optional, can be nil or ignored. Delay before first timer run. Not counted in total timer elapsed time. 
--
-- Additional information:
--          Timer callback arguments:
--              cbArgs (table)  - Contains all information about timer.
--                  cbArgs.timer (handle)       - Current timer 
--                  cbArgs.period (float)       - Time interval for current timer 
--                  cbArgs.elapsed (float)      - Total elapsed time for this timer run 
--                  cbArgs.maxTime (float)      - Max time for this timer
--                  cbArgs.isLastTick (bool)    - Does this iteration of timer is last
--
--              args (anything) - Optional, nil if you don't use func.args in TimerStart() call. Represents anything passed in func.args.
--
-- Examples of usage:
--
--                      -- 1. Prints Hello World! every 0.3 seconds for 3 seconds. First print will be after 0.3 seconds (not just after calling TimerStart())
--                      local timer = CreateTimer(true)
--                      TimerStart( timer, 0.5, 3, true, function()
--                          print("Hello World!")
--                       end)
--
--                      -- 2. Same as #1, but first tick runs instantly after TimerStart()
--                      local timer = CreateTimer(true)
--                      TimerStart( timer, 0.5, 3, true, function()
--                          print("Hello World!")
--                       end, 0)
--
--                      -- 3. Prints Hello World! every 0.3 seconds for 3 seconds, but with 5 seconds delay before first run.
--                      local timer = CreateTimer(true)
--                      TimerStart( timer, 0.5, 3, true, function()
--                          print("Hello World!")
--                       end, 5)
--
--                      -- 4. Prints Hello World! after 40 seconds.
--                      local timer = CreateTimer(true)
--                      TimerStart( timer, 40, nil, false, function()
--                          print("Hello World!")
--                       end)
--
--                      -- 5. Prints elapsed timer's time every 1 second for 10 seconds.
--                      local timer = CreateTimer(true)
--                      TimerStart( timer, 1, 10, false, function(cbArgs)
--                          print(cbArgs.elapsed)
--                       end)
--
--                      -- 6. Same as example #1, but timer without automatic destroy.
--                      local timer = CreateTimer()
--                      TimerStart( timer, 0.5, 3, true, function(cbArgs)
--                          print("Hello World!")
--                          if cbArgs.isLastTick then
--                              DestroyTimer(cbArgs.timer)
--                          end
--                       end)
--
--                      -- 7. Prints an argument (123) every 1 second for 10 seconds and also prints elapsed time on last timer tick.
--                      local timer = CreateTimer(true)
--                      local callback = function(cbArgs, arg)
--                              print(arg)
--                              if cbArgs.isLastTick then
--                                  print(cbArgs.elapsed)
--                              end
--                          end
--                      local myArg = 123
--
--                      TimerStart( timer, 1, 10, true, { fn = callback, args = myArg } )
--
--
--
--
-- Extra timer functions:
--                          DestroyTimer(timer)         - Destroy a timer.
--                          GetTimerInterval(timer)     - Get timer interval. This is second argument of TimerStart function.
--                          GetTimerMaxTime(timer)      - Get timer max time.
--                          GetTimerElapsedTime(timer)  - Get timer elapsed time.
--                          IsTimerActive(timer)        - Check is timer active. Returns true if timer was started and not finished. Returns false if wasn't started or finished.
--                          IsTimerPaused(timer)        - Check is timer paused now. If timer not active - returns false.
--                          StopTimer(timer)            - Stops timer. After this it cannot be resumed. Not dying after being stopped, must be destroyed with DestroyTimer().
--                          PauseTimer(timer, isPaused) - Pauses timer if isPaused is true. Resumes if false.
--                          GetExpiredTimer()           - Returns last runned timer (valid on every timer tick). Returns current timer inside of timer callback. This function is for legacy code.
--
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------

function InitClassicTimers()
    print ( '[ClassicTimers] creating ClassicTimers' )
    ClassicTimers = {}
    ClassicTimers.container = {}
    ClassicTimers.containerLastIndex = -1
    ClassicTimers.expiredTimer = -1
    GameRules:GetGameModeEntity():SetThink(___GlobalTimerThinker)
end

function ___GlobalTimerThinker()
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
        return nil
    end

    local i = 0
    local time = GameRules:GetGameTime()
    local prevTime, period, isLastTick, elapsedTime, firstDelay, cbArgs
    local destroyQueue = {}
    local dsqSize = 0

    while i <= ClassicTimers.containerLastIndex do
        if ClassicTimers.container[i] ~= nil then
            if ClassicTimers.container[i].die then
                destroyQueue[dsqSize] = i
                dsqSize = dsqSize + 1
            else
                if ClassicTimers.container[i].running then
                    prevTime = ClassicTimers.container[i].lastEmitTime
                    period = ClassicTimers.container[i].interval
                    firstDelay = ClassicTimers.container[i].firstDelay

                    if firstDelay >= 0 then
                        period = firstDelay
                    end

                    if time - prevTime >= period and not ClassicTimers.container[i].paused then
                        ClassicTimers.container[i].elapsedTime = ClassicTimers.container[i].elapsedTime + ClassicTimers.container[i].interval
                        elapsedTime = ClassicTimers.container[i].elapsedTime
                        isLastTick = (ClassicTimers.container[i].elapsedTime >= ClassicTimers.container[i].maxTime and ClassicTimers.container[i].maxTime ~= 0)

                        cbArgs = {}
                        cbArgs.timer = i
                        cbArgs.period = period
                        cbArgs.elapsed = elapsedTime
                        cbArgs.maxTime = ClassicTimers.container[i].maxTime
                        cbArgs.isLastTick = isLastTick

                        ClassicTimers.expiredTimer = i
                        ClassicTimers.container[i].callback(cbArgs, ClassicTimers.container[i].args)

                        if ClassicTimers.container[i].die then
                            destroyQueue[dsqSize] = i
                            dsqSize = dsqSize + 1
                        else
                            ClassicTimers.container[i].lastEmitTime = time
                            if firstDelay >= 0 then
                                ClassicTimers.container[i].firstDelay = -1
                            end

                            if not ClassicTimers.container[i].periodic or isLastTick then
                                StopTimer(i)
                                if ClassicTimers.container[i].autodie then
                                    destroyQueue[dsqSize] = i
                                    dsqSize = dsqSize + 1
                                end
                            end
                        end
                    end
                end
            end
        end
        i = i + 1
    end

    i = 0
    while i < dsqSize do
        DestroyTimer_unsafe_kill(destroyQueue[i])
        i = i + 1
    end

    return 0
end

function CreateTimer(selfDestruct)
    local id = 0

    while ClassicTimers.container[id] ~= nil do
        id = id + 1
    end

    ClassicTimers.container[id] = {}
    if selfDestruct == nil then
        ClassicTimers.container[id].autodie = false
    else
        ClassicTimers.container[id].autodie = selfDestruct
    end

    ClassicTimers.container[id].die = false
    ClassicTimers.container[id].running = false
    ClassicTimers.container[id].interval = 0
    ClassicTimers.container[id].paused = false
    ClassicTimers.container[id].periodic = false
    ClassicTimers.container[id].callback = nil
    ClassicTimers.container[id].args = nil
    ClassicTimers.container[id].maxTime = 0
    ClassicTimers.container[id].lastEmitTime = 0.0
    ClassicTimers.container[id].elapsedTime = 0
    ClassicTimers.container[id].firstDelay = -1

    if id > ClassicTimers.containerLastIndex then
        ClassicTimers.containerLastIndex = id
    end
    return id
end

function TimerStart(timer, period, maxTime, isPeriodic, func, firstDelay)
    if timer == nil then
        print("TimerStart() - timer is nil")
        return
    end

    if period == nil then
        print("TimerStart() - period is nil")
        return
    end

    if period == 0.000 or period < 0 then
        print("TimerStart() - period cannot be zero or negative")
        return
    end

    if maxTime ~= nil and maxTime < 0 then
        print("TimerStart() - maxTime cannot be negative")
        return
    end

    if isPeriodic == nil then
        print("TimerStart() - isPeriodic is nil")
        return
    end

    if func == nil then
        print("TimerStart() - func is nil")
        return
    end

    if not isPeriodic then
        maxTime = period
    elseif maxTime ~= nil and maxTime < 0 then
        print("TimerStart() - maxTime cannot be negative or nil when isPeriodic == true")
        return
    end

    if firstDelay == nil or isPeriodic == false then
        ClassicTimers.container[timer].firstDelay = -1
    else
        ClassicTimers.container[timer].firstDelay = firstDelay
    end

    if type(func) == "table" then
        ClassicTimers.container[timer].callback = func.fn
        ClassicTimers.container[timer].args = func.args
    else
        ClassicTimers.container[timer].callback = func
        ClassicTimers.container[timer].args = nil
    end

    ClassicTimers.container[timer].die = false
    ClassicTimers.container[timer].interval = period
    ClassicTimers.container[timer].paused = false
    ClassicTimers.container[timer].periodic = isPeriodic
    ClassicTimers.container[timer].maxTime = maxTime
    ClassicTimers.container[timer].lastEmitTime = GameRules:GetGameTime()
    ClassicTimers.container[timer].elapsedTime = 0
    ClassicTimers.container[timer].running = true
end

function DestroyTimer_unsafe_kill(timer)
    if timer == nil then
        print("DestroyTimer_unsafe_kill() - timer is nil")
        return
    end

    if IsTimerActive(timer) then
        StopTimer(timer)
    end

    if ClassicTimers.container[timer] ~= nil then
        ClassicTimers.container[timer] = nil
        if timer == ClassicTimers.containerLastIndex then
            while ClassicTimers.container[ClassicTimers.containerLastIndex] == nil and ClassicTimers.containerLastIndex >= 0 do
                ClassicTimers.containerLastIndex = ClassicTimers.containerLastIndex - 1
            end
        end
    end
end

function DestroyTimer(timer)
    if timer == nil then
        print("DestroyTimer() - timer is nil")
        return
    end

    ClassicTimers.container[timer].die = true
end

function GetTimerInterval(timer)
    if timer == nil then
        print("GetTimerInterval() - timer is nil")
        return
    end

    return ClassicTimers.container[timer].interval
end

function IsTimerActive(timer)
    if timer == nil then
        print("IsTimerActive() - timer is nil")
        return
    end

    return ClassicTimers.container[timer].running
end

function IsTimerPaused(timer)
    if timer == nil then
        print("IsTimerPaused() - timer is nil")
        return
    end

    return ClassicTimers.container[timer].paused
end

function GetTimerMaxTime(timer)
    if timer == nil then
        print("GetTimerMaxTime() - timer is nil")
        return
    end

    return ClassicTimers.container[timer].maxTime
end

function GetTimerElapsedTime(timer)
    if timer == nil then
        print("GetTimerElapsedTime() - timer is nil")
        return
    end

    return ClassicTimers.container[timer].elapsedTime
end

function StopTimer(timer)
    if timer == nil then
        print("StopTimer() - timer is nil")
        return
    end

    ClassicTimers.container[timer].running = false
end

function PauseTimer(timer, isPaused)
    if timer == nil then
        print("StopTimer() - timer is nil")
        return
    end

    ClassicTimers.container[timer].paused = isPaused
end

function GetExpiredTimer() --Just for better compatibility, this sucks though
    return ClassicTimers.expiredTimer
end

GameRules.ClassicTimers = ClassicTimers