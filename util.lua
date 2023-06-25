function Trace(str)
    game.players[1].print(str)
end

function Logging(message)
	 game.write_file("IC2_Reactor.log","\r\n[" .. game.tick .. "] " .. message,true)
end

local unite = { " W", " kW", " MW", " GW", " TW" }
function Convertion(valeur)
    if valeur ~= 0 then
        local vlog = math.floor(math.log(valeur, 10) / 3)
        valeur = valeur * 10 ^ (-3 * vlog)
        local aron = math.floor(math.log(valeur, 10)) + 1
        return string.format("%0." .. tostring(4 - aron) .. "f", valeur) .. unite[vlog + 1]
    else
        return "0 W"
    end
end

---@param x number
function ColorMix(x)
    local green = math.max(1 - (x * (1 - 0.498) * 2), 0)
    local red = math.max(math.min(5 * math.pow(x, 2) + x - 0.75, 1), 0)
    return { red, green, 0, 1 }
end
