extends CharacterBody3D

signal healthChanged(health)

@export var Speed: float = 6.75
@export var JumpVel: float = 6.125
@export var Sensitivity: float = 0.005
@export var Health: int = 3
@onready var cam: Camera3D = $Cam
@onready var anim: AnimationPlayer = $Anim
@onready var muzzel_flash: GPUParticles3D = $Cam/Gun/MuzzelFlash
@onready var raycast: RayCast3D = $Cam/Eyes

func _unhandled_input(event: InputEvent) -> void:
	if is_multiplayer_authority():
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * Sensitivity)
			cam.rotate_x(-event.relative.y * Sensitivity)
			cam.rotation.x = clamp(cam.rotation.x, -PI/2, PI/2)
			
		if Input.is_action_just_pressed("Shoot") and not anim.current_animation == "Shoot":
			Shoot.rpc()
			if raycast.is_colliding():
				var hitPlayer = raycast.get_collider()
				hitPlayer.GetDamage.rpc_id(hitPlayer.get_multiplayer_authority())

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	cam.current = is_multiplayer_authority()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		if not is_on_floor():
			velocity += get_gravity() * delta

		if Input.is_action_just_pressed("Jump") and is_on_floor():
			velocity.y = JumpVel

		var input_dir := Input.get_vector("Left", "Right", "Up", "Down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * Speed
			velocity.z = direction.z * Speed
		else:
			velocity.x = move_toward(velocity.x, 0, Speed)
			velocity.z = move_toward(velocity.z, 0, Speed)
			
		if not anim.current_animation == "Shoot":
			if input_dir != Vector2.ZERO:
				anim.play("Move")
				
			else:
				anim.play("Idle")

		move_and_slide()

func Respawn():
	global_position = Vector3.ZERO
	Health = 3

@rpc("call_local")
func Shoot():
	anim.stop()
	anim.play("Shoot")
	muzzel_flash.restart()
	muzzel_flash.emitting = true
	
@rpc("any_peer")
func GetDamage():
	Health -= 1
	if Health <= 0:
		Respawn()
	healthChanged.emit(Health)
