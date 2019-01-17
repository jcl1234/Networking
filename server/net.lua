local net = {}
net.host = nil
net.sendData = {}
net.timeout = 0

net.lastSend = 0
net.lastReceive = 0

--Time without communication until disconnect
net.maxTime = 10

net.localClient = nil
net.server = nil
net.clients = {}

--Packages sent/received per second
net.tickRate = 14

--[[ Server messages
	id = __id,
	disconnect = __disconnect,
	connect = __connect,
]]
-------------------
local CLIENT = false
local SERVER = false

--Client class
local client = {}
client.mt = {__index = client}
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
	setmetatable(cl, client.mt)
	return cl
end

function client:setId(id)
	if id then
		net.clients[self.id] = nil
		self.id = id
		net.clients[id] = self
	end
end

function client:send(data)
	self.peer:send(data)
end

function client:disconnect()
	if net.onDisconnect then
		net.onDisconnect(self)
	end
	if CLIENT and self.id == net.localClient.id then
		net.localClient.peer:disconnect()
	end
	net.clients[self.id] = nil
	if SERVER then
		self.peer:disconnect()
		net.send({__disconnect={self.id}})
	end
end

function client.get(id)
	return net.clients[id]
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
				cl:send(s.pack(pushTab))
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
net.defaultPort = "2212"
function net.connect(ip, port)
	if not ip and not port then
		ip , port = net.localIp, net.localPort
	end
	port = port or net.defaultPort
	if not net.host then
		net.host = enet.host_create()
	end
	net.server = net.host:connect(toIp(ip, port))
	CLIENT = true
	return net.server, net.host
end

function net.disconnect()
	if not CLIENT then return end
	if net.server then
		for k, cl in pairs(net.clients) do
			cl:disconnect()
		end
		net.server:disconnect()
		net.localClient = nil
		net.server = nil
	end
end

--Server
function net.create(ip, port)
	if not ip and not port then
		ip , port = net.localIp, net.localPort
	end
	port = port or net.defaultPort
	net.host = enet.host_create(toIp(ip, port))
	net.server = net.host
	SERVER = true
	return net.server, net.host
end

--BOTH--------------------
--Add send data to be sent, blank id to broadcast to all clients
function net.send(t, id)
	if CLIENT then
		for k, v in pairs(t) do
			net.sendData[k] = v
		end
		net.sendData["id"]=net.id
	elseif SERVER then
		if type(id) == "table" then id = id.id end
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
		local cl
		for k, client in pairs(net.clients) do
			if event.peer == client.peer then cl = client end
		end
		if event.type == "receive" then
			local data = s.unpack(event.data)
			-- print("Got message: ", event.data, event.peer)
			if CLIENT then
				--Receive id from server and create local client
				if data.__id then
					net.localClient = client.new(event.peer)
					net.localClient:setId(data.__id)
					if net.onJoin then net.onJoin(data.__id) end
				end
				--Create new client from connected player
				if data.__connect then
					for k, id in pairs(data.__connect) do
						if not (net.localClient and net.localClient.id == id) then
							local cl = client.new()
							cl:setId(id)
							if net.onConnect then net.onConnect(cl) end
							print("client "..cl.id.." connected")
						end
					end
				end
				--Disconnect client
				if data.__disconnect then
					for k, id in pairs(data.__disconnect) do
						print("id")
						local cl = net.clients[id]
						if cl then
							cl:disconnect()
						end
						print("client "..id.." disconnected")
					end
				end
				net.lastReceive = 0
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
				cl:disconnect()
			end
		end
		event = net.host:service()
	end
	if CLIENT then
		if net.lastReceive >= net.maxTime then
			net.disconnect()
		end
		net.lastReceive = net.lastReceive + dt
	end

	if SERVER then
		--Update client timeouts and disconnect if no pings
		for k, cl in pairs(net.clients) do
			if cl.lastSend >= net.maxTime then
				cl:disconnect()
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