function trace(str)
    game.players[1].print(str)
end

function logging(message)
	 game.write_file("IC2_Reactor.log","\r\n[" .. game.tick .. "] " .. message,true)
end