extends Node2D
var gravity = 150
var dropPos = Vector2.ZERO
var dropVel = Vector2.ZERO
var damping = 0.99



func _draw():
	draw_circle(dropPos, 25, Color.ROYAL_BLUE)
	
	
# Called when the node enters the scene tree for the first time.
func _ready():
	_draw() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	dropPos += dropVel * delta 
	dropVel.y += gravity * delta
	queue_redraw()
	
func _physics_process(delta):
	Position_handeling()

func Position_handeling():
	if dropPos.y > 250:
		dropVel.y *=-1 * damping
	if dropPos.y < -250:
		dropVel .y *= -1 * damping
	if dropPos.x > 250:
		dropVel.x *=-1 * damping
	if dropPos.x < -250:
		dropVel .x *= -1 * damping
	
