local net = {}
net.host = nil
net.sendData = {}
net.timeout = 0

net.lastSend = 0

--Time without communication until disconnect
net.maxTime = 10

net.localClient = nil
net.server = nil
net.clients = {}

--Packages sent/received per second
net.tickRate = 8

--[[ Server messages
	id = __id,
	disconnect = __disconnect,
	connect = __connect,
	force quit = __forceQuit,
]]
-------------------
local CLIENT = false
local SERVER = false

--Client class
local client = {}
function client.new(peer)
	local cl = {}
	cl.peer = peer

	local maxId = 0
	--Get max id
	for k, client in pairs(net.clients) do
		maxId = math.max(client.id, maxId)
	end
	cl.id = maxId + 1

	cl.lastSend = 0

	net.clients[cl.id] = cl
	return cl
end

function client.setId(cl, id)
	if cl and id then
		net.clients[cl.id] = nil
		cl.id = id
		net.clients[id] = cl
	end
end

function client.get(peer)
	for k, client in pairs(net.clients) do
		if peer == client.peer then return client end
	end
end

function client.send(id, data)
	local cl = net.clients[id]
	if cl then
		cl.peer:send(data)
	end
end

function client.disconnect(id)
	local cl = net.clients[id]
	if cl and net.onDisconnect then
		net.onDisconnect(cl)
	end
	if CLIENT and id == net.localClient.id then
		net.localClient.peer:disconnect()
	end
	net.clients[id] = nil
	if SERVER then
		cl.peer:disconnect()
		net.send({__disconnect={id}})
	end
end

--PUSH TO SERVER/CLIENTS
local function push()
	if CLIENT then
		net.server:send(s.pack(net.sendData))
	elseif SERVER then
		for k, cl in pairs(net.clients) do
			local pushTab = net.sendData["all"] or {}
			--Overwrite pushTab if special client message
			if net.sendData[cl.id] then
				pushTab = copy(pushTab)
				for k, v in pairs(net.sendData[cl.id]) do
					pushTab[k] = v
				end
			end
			if pushTab ~= {} then
				client.send(cl.id, s.pack(pushTab))
			end
		end
	end
	net.sendData = {}
	net.lastSend = 0
end

local function toIp(num, port)
	return num..":"..port
end
--START------------------
net.localIp, net.localPort = "localhost", "80"
function net.connect(ip, port)
	ip , port = net.localIp, net.localPort
	net.host = enet.host_create()
	net.server = net.host:connect(toIp(ip, port))
	CLIENT = true
	return net.server, net.host
end

function net.disconnect()

end

--Server
function net.create(ip, port)
	ip , port = net.localIp, net.localPort
	net.host = enet.host_create(toIp(ip, port))
	net.server = net.host
	SERVER = true
	return net.server, net.host
end

--BOTH--------------------
--Add send data to be sent, no id to broadcast to all clients
function net.send(t, id)
	if CLIENT then
		for k, v in pairs(t) do
			net.sendData[k] = v
		end
		net.sendData["id"]=net.id
	elseif SERVER then
		if not id then id = "all" end
		--Overwrite existing pushtab
		local pushTab = net.sendData[id]
		if pushTab then
			for k, v in pairs(t) do
				pushTab[k] = v
			end
		else
			net.sendData[id] = t
		end
	end
end

function net.receive(t, client)
end

function net.onConnect(client)
end

function net.onDisconnect(client)
end

--Client only
function net.onJoin(id)
end

--------------------------

function net.update(dt)
	local timeout = (SERVER and net.timeout) or 0
	local event = net.host:service(timeout)
	while event do
		local cl = client.get(event.peer)
		if event.type == "receive" then
			local data = s.unpack(event.data)
			-- print("Got message: ", event.data, event.peer)
			if CLIENT then
				--Receive id from server and create local client
				if data.__id then
					net.localClient = client.new(event.peer)
					client.setId(net.localClient, data.__id)
					if net.onJoin then net.onJoin(data.__id) end
				end
				--Create new client from connected player
				if data.__connect then
					for k, id in pairs(data.__connect) do
						if not (net.localClient and net.localClient.id == id) then
							local cl = client.new()
							client.setId(cl, id)
							if net.onConnect then net.onConnect(cl) end
							print("client "..cl.id.." connected")
						end
					end
				end
				--Disconnect client
				if data.__disconnect then
					for k, id in pairs(data.__disconnect) do
						local cl = net.clients[id]
						client.disconnect(id)
						print("client "..id.." disconnected")
					end
				end

			end
			if net.receive then net.receive(data, cl or {}) end

			--Update timeout
			if SERVER then
				cl.lastSend = 0
			end

			--If client then push all data
			if CLIENT then
				push()
			end

		elseif event.type == "connect" and SERVER then
			--Create client on server
			local newClient = client.new(event.peer)
			--Send client its id
			net.send({__id=newClient.id}, newClient.id)
			
			local connectedIds = {}
			--Send new client id  to current clients id
			for k, cl in pairs(net.clients) do
				if cl ~= newClient then
					net.send({__connect={newClient.id}}, cl.id)
					connectedIds[cl.id] = cl.id
				end
			end
			--Send current client ids to new client
			if #connectedIds >= 1 then
				net.send({__connect=connectedIds}, newClient.id)
			end

			if net.onConnect then net.onConnect(newClient) end
			print("client "..newClient.id.." connected")
		elseif event.type == "disconnect" and SERVER then
			if cl then
				print("client "..cl.id.." disconnected")
				client.disconnect(cl.id)
			end
		end
		event = net.host:service()
	end

	if SERVER then
		--Update client timeouts and disconnect if no pings
		for k, cl in pairs(net.clients) do
			if cl.lastSend >= net.maxTime then
				client.disconnect(cl.id)
			end
			cl.lastSend = cl.lastSend + dt
		end
		--Push packets to clients
		net.lastSend = net.lastSend + dt
		if net.lastSend >= 1/net.tickRate then
			push()
		end
	end

end

return net