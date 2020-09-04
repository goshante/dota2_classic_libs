
if UnitGroups == nil then
    UnitGroups = {}
    UnitGroups.unitGroups = {}
    UnitGroups.unitGroupsLastIndex = -1
end

function CreateUnitGroup()
    local id = 0

    while UnitGroups.unitGroups[id] ~= nil do
        id = id + 1
    end

    UnitGroups.unitGroups[id] = {}
    UnitGroups.unitGroups[id].size = 0
    UnitGroups.unitGroups[id].units = {}
    if id > UnitGroups.unitGroupsLastIndex then
        UnitGroups.unitGroupsLastIndex = id
    end
    return id
end

function DestroyUnitGroup(grpId)
    if grpId == nil then
        print("DestroyUnitGroup() - grpId is nil")
        return
    end

    if UnitGroups.unitGroups[grpId] ~= nil then
        UnitGroups.unitGroups[grpId] = nil
        if grpId == UnitGroups.unitGroupsLastIndex then
            while UnitGroups.unitGroups[UnitGroups.unitGroupsLastIndex] == nil and UnitGroups.unitGroupsLastIndex >= 0 do
                UnitGroups.unitGroupsLastIndex = UnitGroups.unitGroupsLastIndex - 1
            end
        end
    end
end

function GroupAddUnit(grpId, u)
    if grpId == nil then
        print("GroupAddUnit() - grpId is nil")
        return
    end

    if u == nil then
        print("GroupAddUnit() - unit is nil")
        return
    end

    if IsUnitInGroup(grpId, u) then
        return
    end

    local size = UnitGroups.unitGroups[grpId].size
    UnitGroups.unitGroups[grpId].units[size] = u
    UnitGroups.unitGroups[grpId].size = size + 1
end

function GroupRemoveUnit(grpId, u)
    if grpId == nil then
        print("GroupRemoveUnit() - grpId is nil")
        return
    end

    if u == nil then
        print("GroupRemoveUnit() - unit is nil")
        return
    end

    local i = 0
    local size = UnitGroups.unitGroups[grpId].size
    local removed = false

    while i < size do
        if UnitGroups.unitGroups[grpId].units[i] == u then
            UnitGroups.unitGroups[grpId].units[i] = nil
            removed = true
            break
        end
        i = i + 1
    end

    if removed then
        while i < size do
            if i == size - 1 then
                UnitGroups.unitGroups[grpId].units[i] = nil
                break
            else
                UnitGroups.unitGroups[grpId].units[i] = UnitGroups.unitGroups[grpId].units[i + 1]
            end
            i = i + 1
        end

        UnitGroups.unitGroups[grpId].size = size - 1
    end
end

function IsUnitInGroup(grpId, u)
    if grpId == nil then
        print("IsUnitInGroup() - grpId is nil")
        return false
    end

    if u == nil then
        print("IsUnitInGroup() - unit is nil")
        return false
    end

    local i = 0
    local size = UnitGroups.unitGroups[grpId].size

    while i < size do
        if UnitGroups.unitGroups[grpId].units[i] == u then
            return true
        end
        i = i + 1
    end

    return false
end

function GetUnitGroupSize(grpId)
    if grpId == nil then
        print("GetUnitGroupSize() - grpId is nil")
        return -1
    end

    return UnitGroups.unitGroups[grpId].size
end

function EnumUnitGroup(grpId, callback)
    if grpId == nil then
        print("EnumUnitGroup() - grpId is nil")
        return -1
    end

    if grpId == nil then
        print("EnumUnitGroup() - callback is nil")
        return -1
    end

    local i = 0
    local size = UnitGroups.unitGroups[grpId].size

    while i < size do
        if UnitGroups.unitGroups[grpId].units[i] ~= nil then
            callback(UnitGroups.unitGroups[grpId].units[i])
        else
            print("EnumUnitGroup() - nil unit in unit group")
        end
        i = i + 1
    end
end

function GroupAddGroup(grpDest, grpSrc)
    if grpDest == nil then
        print("GroupAddGroup() - grpDest is nil")
        return
    end

    if grpSrc == nil then
        print("GroupAddGroup() - grpSrc is nil")
        return
    end

    local size = UnitGroups.unitGroups[grpSrc].size
    local i = 0

    while i < size do
        GroupAddUnit(grpDest, UnitGroups.unitGroups[grpSrc].units[i])
        i = i + 1
    end
end

function GroupRemoveGroup(grpDest, grpSrc)
    if grpDest == nil then
        print("GroupRemoveGroup() - grpDest is nil")
        return
    end
    if grpSrc == nil then
        print("GroupRemoveGroup() - grpSrc is nil")
        return
    end

    local size = UnitGroups.unitGroups[grpSrc].size
    local i = 0

    while i < size do
        if IsUnitInGroup(grpDest, UnitGroups.unitGroups[grpSrc].units[i]) then
            GroupRemoveUnit(grpDest, UnitGroups.unitGroups[grpSrc].units[i])
        end
        i = i + 1
    end
end

function GroupIntersecton(grp1, grp2)
    if grp1 == nil then
        print("GroupIntersecton() - grp1 is nil")
        return nil
    end
    if grp2 == nil then
        print("GroupIntersecton() - grp2 is nil")
        return nil
    end

    local grp3 = CreateUnitGroup()

    local size = UnitGroups.unitGroups[grp1].size
    local i = 0

    while i < size do
        if IsUnitInGroup(grp2, UnitGroups.unitGroups[grp1].units[i]) then
            GroupAddUnit(grp3, UnitGroups.unitGroups[grp1].units[i])
        end
        i = i + 1
    end

    return grp3
end

function TableToUnitGroup(table)
    if table == nil then
        print("TableToUnitGroup() - table is nil")
        return nil
    end

    local g = CreateUnitGroup()

    for _,unit in pairs(table) do
        GroupAddUnit(g, unit)
    end

    return g
end

GameRules.UnitGroups = UnitGroups