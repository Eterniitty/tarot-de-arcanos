extends Node
## Conexión online. Con GodotSteam instalado usa salas de Steam (invitar amigos desde la superposición);
## sin él, ENet por IP (LAN o pruebas en el mismo PC). El anfitrión manda: simula y reparte el estado.

signal connected
signal failed(msg: String)
signal peer_joined(id: int)
signal peer_left(id: int)
signal steam_join_requested(lobby_id: int)

const PORT := 7777

var mode := "off"  # off, lan, steam
var steam_ok := false
var steam: Object
var lobby_id := 0
var my_name := "JUGADOR"
var _quick := false  # buscando partida rápida (sala pública con gente al azar)
var _public := false
var partida := "tarot"  # a qué se juega en la partida rápida: tarot, bj o 7m


func _ready() -> void:
	multiplayer.peer_connected.connect(func(id): peer_joined.emit(id))
	multiplayer.peer_disconnected.connect(func(id): peer_left.emit(id))
	multiplayer.connected_to_server.connect(func(): connected.emit())
	multiplayer.connection_failed.connect(func(): close(); failed.emit("NO SE PUDO CONECTAR"))
	multiplayer.server_disconnected.connect(func(): close(); failed.emit("EL ANFITRION SE FUE"))
	if Engine.has_singleton("Steam"):
		steam = Engine.get_singleton("Steam")
		var r = steam.call("steamInitEx", 480, false)
		steam_ok = r is Dictionary and int(r.get("status", 1)) == 0
		if not steam_ok:  # ya iniciado por otro lado: vale si Steam responde con nuestra cuenta
			steam_ok = bool(steam.call("isSteamRunning")) and int(steam.call("getSteamID")) != 0
		if steam_ok:
			my_name = Pix.safe_name(str(steam.call("getPersonaName")), "JUGADOR", 10)
			steam.connect("lobby_created", _on_lobby_created)
			steam.connect("lobby_joined", _on_lobby_joined)
			steam.connect("lobby_match_list", _on_lobby_list)
			steam.connect("join_requested", func(lobby, _friend): steam_join_requested.emit(int(lobby)))
			# Invitación aceptada con el juego cerrado: Steam la pasa por la línea de comandos.
			for i in OS.get_cmdline_args().size():
				if OS.get_cmdline_args()[i] == "+connect_lobby" and i + 1 < OS.get_cmdline_args().size():
					steam_join_requested.emit.call_deferred(int(OS.get_cmdline_args()[i + 1]))


func _process(_d: float) -> void:
	if steam_ok:
		steam.call("run_callbacks")


## Steam abierto pero sin conexión con sus servidores (modo desconectado): no hay salas posibles.
func steam_offline() -> bool:
	return steam_ok and not bool(steam.call("loggedOn"))


func online() -> bool:
	return mode != "off"


func is_host() -> bool:
	return mode == "off" or multiplayer.is_server()


func host_lan() -> bool:
	var p := ENetMultiplayerPeer.new()
	if p.create_server(PORT, 4) != OK:
		failed.emit("EL PUERTO %d ESTA OCUPADO" % PORT)
		return false
	multiplayer.multiplayer_peer = p
	mode = "lan"
	return true


func join_lan(ip: String) -> bool:
	var p := ENetMultiplayerPeer.new()
	if p.create_client(ip, PORT) != OK:
		failed.emit("NO SE PUDO CONECTAR")
		return false
	multiplayer.multiplayer_peer = p
	mode = "lan"
	return true


## Crea una sala de Steam: de amigos (se entra por invitación) o pública para la partida rápida.
func host_steam(public: bool) -> void:
	mode = "steam"
	_public = public
	steam.call("createLobby", 2 if public else 1, 4)  # 2 = pública, 1 = solo amigos


## Partida rápida: busca una sala pública de este juego con sitio; si no hay ninguna, crea una y espera.
func quick_steam() -> void:
	mode = "steam"
	_quick = true
	steam.call("addRequestLobbyListStringFilter", "juego", "tarot", 0)
	steam.call("addRequestLobbyListStringFilter", "modo", "rapida", 0)
	steam.call("addRequestLobbyListStringFilter", "partida", partida, 0)
	steam.call("addRequestLobbyListFilterSlotsAvailable", 1)
	steam.call("addRequestLobbyListDistanceFilter", 3)  # todo el mundo
	steam.call("requestLobbyList")


func _on_lobby_list(lobbies: Array) -> void:
	if not _quick:
		return
	_quick = false
	if lobbies.is_empty():
		host_steam(true)
	else:
		join_steam(int(lobbies[0]))


## Partida rápida sin Steam (pruebas en el mismo PC): el primero abre el puerto y el segundo se une.
func quick_lan() -> bool:
	var p := ENetMultiplayerPeer.new()
	if p.create_server(PORT, 4) == OK:
		multiplayer.multiplayer_peer = p
		mode = "lan"
		return true
	join_lan("127.0.0.1")
	return false


## Al empezar la partida la sala deja de aceptar gente (y de salir en la búsqueda).
func lock() -> void:
	if steam_ok and mode == "steam" and lobby_id != 0 and is_host():
		steam.call("setLobbyJoinable", lobby_id, false)


func join_steam(id: int) -> void:
	mode = "steam"
	steam.call("joinLobby", id)


## Amigos conectados ahora. Con only_lobby, solo los que están en una sala de este juego (para unirse).
func friends(only_lobby: bool) -> Array:
	var out := []
	if not steam_ok:
		return out
	var n: int = steam.call("getFriendCount", 4)  # 4 = amigos directos
	for i in maxi(n, 0):
		var fid: int = steam.call("getFriendByIndex", i, 4)
		if int(steam.call("getFriendPersonaState", fid)) == 0:
			continue  # desconectado
		var g: Dictionary = steam.call("getFriendGamePlayed", fid)
		var lobby := int(g.get("lobby", 0)) if int(g.get("id", 0)) == 480 else 0
		if only_lobby and lobby == 0:
			continue
		out.append({"id": fid, "name": Pix.safe_name(str(steam.call("getFriendPersonaName", fid)), "AMIGO", 14), "lobby": lobby})
	return out


func invite(friend_id: int) -> void:
	if steam_ok and lobby_id != 0:
		steam.call("inviteUserToLobby", lobby_id, friend_id)


func _on_lobby_created(result: int, id: int) -> void:
	if result != 1:
		close()
		failed.emit("STEAM NO PUDO CREAR LA SALA (CODIGO %d)" % result)
		return
	lobby_id = id
	steam.call("setLobbyJoinable", id, true)
	steam.call("setLobbyData", id, "juego", "tarot")
	steam.call("setLobbyData", id, "modo", "rapida" if _public else "sala")
	steam.call("setLobbyData", id, "partida", partida)
	var p: MultiplayerPeer = ClassDB.instantiate("SteamMultiplayerPeer")
	p.call("create_host", 0)
	multiplayer.multiplayer_peer = p
	connected.emit()


func _on_lobby_joined(id: int, _perms: int, _locked: bool, response: int) -> void:
	if response != 1:
		close()
		failed.emit("NO SE PUDO ENTRAR EN LA SALA")
		return
	lobby_id = id
	var owner_id: int = steam.call("getLobbyOwner", id)
	if owner_id == steam.call("getSteamID"):
		return  # somos el anfitrión: ya está montado en _on_lobby_created
	var p: MultiplayerPeer = ClassDB.instantiate("SteamMultiplayerPeer")
	p.call("create_client", owner_id, 0)
	multiplayer.multiplayer_peer = p


func close() -> void:
	if steam_ok and lobby_id != 0:
		steam.call("leaveLobby", lobby_id)
	lobby_id = 0
	_quick = false
	_public = false
	partida = "tarot"
	if multiplayer.multiplayer_peer and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	mode = "off"
