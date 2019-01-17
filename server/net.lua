-- version 0.1

local net = {}
net.host = nil
net.timeout = 0

net.localClient = nil
net.server = nil
net.clients = {}

net.showMsgs = true

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
	cl.client = true

	local maxId = 0
	--Get max id
	for k, client in pairs(net.clients) do
		maxId = math.max(client.id, maxId)
	end
	cl.id = maxId + 1


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
	if  net.onDisconnect then
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

function client.sendAll(t)
	for k, cl in pairs(net.clients) do
		cl:send(t)
	end
end

local function toIp(num, port)
	return num..":"..port
end
--START------------------
net.localIp, net.localPort = "127.0.0.1", "80"
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
	if not t or t == {} then return end
	local datStr = s.pack(t)
	if CLIENT and net.server then
		net.server:send(datStr)
	elseif SERVER then
		if id then
			if type(id) == "number" then
				client.get(id):send(datStr)
			elseif type(id) == "table" and id.client then
				id:send(datStr)
			end
		else
			client.sendAll(datStr)
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
		--Get client that sent message 

		local cl 
		if SERVER then
			for k, client in pairs(net.clients) do
				if event.peer == client.peer then cl = client end
			end
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
						local cl = net.clients[id]
						if cl then
							cl:disconnect()
						end
						print("client "..id.." disconnected")
					end
				end
			end
			if net.receive then net.receive(data, cl or {}) end

			if net.showMsgs then print(event.data, "" or (cl and "client #"..cl.id)) end

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
end

return net