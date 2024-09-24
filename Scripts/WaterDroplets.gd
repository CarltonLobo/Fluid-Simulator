extends Node2D
var gravity = 150
var ballSize = 5
var ParticleSpacing = 1
var noOfBalls = 2
var damping = 0.99
var Position = []
var Velocity = []
var Acceleration = []
var Box = Vector2(1000,500)
var dx = 10
var dy = 3
var Hex = []
var forceDist = 1
var forceMag = 10
var Mass = 1

func _draw():
	for dropPos in Position:
		draw_circle(dropPos, ballSize, Color.ROYAL_BLUE)
		draw_line(Box/2, Vector2(-Box.x/2, Box.y/2), Color.CHARTREUSE, 3 )
		draw_line(Vector2(-Box.x/2, Box.y/2),Vector2(-Box.x/2, -Box.y/2), Color.CHARTREUSE, 3 )
		draw_line(Vector2(Box.x/2, -Box.y/2),Vector2(Box.x/2, Box.y/2), Color.CHARTREUSE, 3 )
		draw_line(Vector2(-Box.x/2, -Box.y/2),Vector2(Box.x/2, -Box.y/2), Color.CHARTREUSE, 3 )
	
	
# Called when the node enters the scene tree for the first time.
func _ready():
	var c=0
	var particlesPerRow = int(sqrt(noOfBalls))
	var particlesPerCol = (noOfBalls-1) / particlesPerRow + 1
	var spacing = ballSize *2 +  ParticleSpacing
	var j = 0
	var temp = []
	while (c<noOfBalls):
		var x = (c % particlesPerRow - particlesPerCol / 2 + 0.5) * spacing
		var y = (c / particlesPerRow - particlesPerCol / 2 + 0.5) * spacing
		Velocity.append(Vector2.ZERO)
		Position.append(Vector2(x,y))
		Acceleration.append(Vector2(0,gravity))
		c+=1
	while (j< dy):
		temp.append([])
		j+=1
	var i = 0
	while (i<dx):
		Hex.append(temp)
		i+=1
	_draw() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$TextEdit.text = str(Performance.get_monitor(Performance.TIME_FPS))
	var c = 0
	while c < noOfBalls:
		Position[c] += Velocity[c] * delta 
		Velocity[c] += Acceleration * delta
		AssignHex(Position[c].x, Position[c].y, c)
		c+=1
	queue_redraw()
	
	
func _physics_process(delta):
	var c=0
	while c<noOfBalls:
		Position_handeling(c)
		c+=1

func Position_handeling(c):
	if Position[c].y + Velocity[c].y * get_process_delta_time() > Box.y /2 - ballSize:
		Velocity[c].y *= -1 * damping
	if Position[c].y + Velocity[c].y * get_process_delta_time() < -Box.y /2 + ballSize:
		Velocity[c].y *= -1 * damping
	if Position[c].x + Velocity[c].x * get_process_delta_time() > Box.x /2 - ballSize:
		Velocity[c].x *= -1 * damping
	if Position[c].x + Velocity[c].x * get_process_delta_time() < -Box.x /2 + ballSize:
		Velocity[c].x *= -1 * damping
	for i in Hex:
		for j in Hex[i]:
			for point in Hex[i][j]:
				for otherCast in Hex[i][j]:
					if otherCast == point:
						continue
					else:
						var dist = (Position[point] - Position[otherCast])
						var distMag = (dist.x^2 + dist.y^2)^1/2
						var mag = (distMag^2-forceDist^2)^4
						Acceleration[point] = - mag * dist / distMag
						Acceleration[otherCast] = mag * dist / distMag
	
	
func AssignHex(x,y,c):
	var i = floor((x+Box.x/2)*dx/Box.x)
	var j = floor((y+Box.y/2)*dy/Box.y)
	Hex[i][j].append(c)
