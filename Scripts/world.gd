extends Node3D

var playerScene = preload("res://Scenes/player.tscn")
@onready var Addr: LineEdit = $UI/MainMenu/MarginContainer/VBoxContainer/Addr
@onready var MainMenu: PanelContainer = $UI/MainMenu
@onready var health_bar: ProgressBar = $UI/HUD/HealthBar
@onready var hud: Control = $UI/HUD
const PORT = 1832
var ip_address

func _ready() -> void:
	if OS.get_name() == "Windows":
		ip_address = IP.get_local_addresses()[3]
	elif OS.get_name() == "Android":
		ip_address = IP.get_local_addresses()[0]
	else:
		ip_address = IP.get_local_addresses()[3]
	
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") and not ip.ends_with(".1"):
			ip_address = ip

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Quit"):
		get_tree().quit()

func _on_host_pressed() -> void:
	MainMenu.hide()
	hud.show()
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(AddPlayer)
	AddPlayer(multiplayer.get_unique_id())
	print(ip_address)

func _on_join_pressed() -> void:
	MainMenu.hide()
	hud.show()
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(Addr.text, PORT)
	#peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = peer
	
func RemovePlayer(id):
	var player = get_node_or_null(str(id))
	if player:
		player.queue_free()
	
func AddPlayer(id):
	var player = playerScene.instantiate()
	player.name = str(id)
	add_child(player)
	if player.is_multiplayer_authority():
		player.healthChanged.connect(GiveDamage)
	
func GiveDamage(health):
	health_bar.value = 3-health

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node.is_multiplayer_authority():
		node.healthChanged.connect(GiveDamage)
