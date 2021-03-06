extends "res://character/Character.gd"

## ATTRIBUTES ##
export var fire_speed = 1.0
export var hook_speed = 200.0
# use the ray itself to define the maximum distance

## PRIVATES ##
var _fire_timer = 0
var _hook_point = null # Vector3
var _jump_count = 0

## NODES ##
onready var _hook_ray = $Head/Hook

## SCENES ##
onready var _arrow_projectile = load("res://character/rogue/Arrow.tscn")


## TO OVERRIDE ##

func is_class(type): return type == "Archer" or .is_class(type)
func get_class():    return         "Archer"


## NETWORKING ##


## ENGINE ##

#func _ready():
#	._ready()


# regular update function
func _process(delta):
	if is_controlled():
		if _fire_timer > 0:
			_fire_timer -= delta
		
		# tells the user if he can fire the grappling-hook
		# (keep the ray always enabled so that we can see 
		# next hook anchor even when already hooked)
		if _hook_ray.is_colliding():
			pass
		
		# fire an arrow
		if Input.is_action_just_pressed('attack'):
			if _fire_timer <= 0:
				var arrow = _arrow_projectile.instance()
				arrow.initialize(self)
				_fire_timer = fire_speed
		
		# use grappling hook
		if Input.is_action_just_pressed('secondary'):
			# if the ray is in range then we can hook
			if _hook_ray.is_colliding(): _hook_begin()
			
		elif Input.is_action_just_released('secondary'): _hook_end()
		
		# if the hook is anchored, move toward it
		if _hook_point != null:
			# velocity is proportional to distance from hook point
			var pos   = global_transform.origin
			var diff  = _hook_point - pos
			_velocity = diff * (hook_speed * delta)
		
		# allow multiple jumps
		if is_grounded(): _jump_count = 0
		elif Input.is_action_just_pressed('jump'):
			_jump_count += 1
			if _jump_count < 2: _velocity.y = jump_speed
	
	._process(delta)


## PRIVATES ##

# hook and unhook
func _hook_begin():
	can_move_body = false
	_hook_point   = _hook_ray.get_collision_point()

func _hook_end():
	# when stopping hook, do a little jump
	if _hook_point != null: _velocity = Vector3(0, jump_speed, 0)
	can_move_body = true
	_hook_point   = null
	_jump_count   = 0
	
