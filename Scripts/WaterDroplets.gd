extends Node2D
var gravity = 150
var ballSize = 5
var ParticleSpacing = 1
var noOfBalls = 50
var damping = 0.99
var Position = []
var Velocity = []
var Acceleration = []
var Box = Vector2(1000,500)
var SmoothingRadius = 100
var Hex = []
var forceDist = 1
var forceMag = 10
var mass = 10
var particle_properties = []
var densities: Array[float]
@export var targetDensity = 0.001
@export var PressureMultiplier = 1

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
		#var x = (c % particlesPerRow - particlesPerCol / 2 + 0.5) * spacing
		#var y = (c / particlesPerRow - particlesPerCol / 2 + 0.5) * spacing
		Velocity.append(Vector2.ZERO)
		Position.append(Vector2(randf_range(-Box.x/2, Box.x/2),randf_range(-Box.y/2, Box.y/2)))
		Acceleration.append(Vector2(0,0))
		c+=1
		particle_properties.append(1)
		densities.append(1)

	_draw() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$TextEdit.text = str(Performance.get_monitor(Performance.TIME_FPS))
	queue_redraw()
	
	
func _physics_process(delta):
	for c in range(noOfBalls):
		densities[c] = CalculateDensity(Position[c])
		Position_handeling(c)

func Position_handeling(c):
	var pos = Position[c]
	var vel = Velocity[c]
	
	Acceleration[c] += calculateForce(c)/ densities[c] - (vel/mass)
	
	Position[c] += vel * get_process_delta_time()
	Velocity[c] += Acceleration[c] * get_process_delta_time()
	
	if pos.y + vel.y * get_process_delta_time() > Box.y /2 - ballSize:
		Velocity[c].y *= -1 * damping
	if pos.y + vel.y * get_process_delta_time() < -Box.y /2 + ballSize:
		Velocity[c].y *= -1 * damping
	if pos.x + vel.x * get_process_delta_time() > Box.x /2 - ballSize:
		Velocity[c].x *= -1 * damping
	if pos.x + vel.x * get_process_delta_time() < -Box.x /2 + ballSize:
		Velocity[c].x *= -1 * damping
	
func calculateForce(particleIndex: int) -> Vector2:
	var force = Vector2.ZERO
	
	for i in range(noOfBalls):
		if(particleIndex == i):
			continue
		else:
			var offset = Position[i] - Position[particleIndex]
			var dst = offset.length()
			var dir
			if dst == 0:
				dir = Vector2(0,1)
			else:
				dir = offset/dst
			var slope = smoothing_kernel_derivative(dst, SmoothingRadius)
			var density = densities[i]
			var sharedPressure = sharedPressure(density, densities[i])
			force += -sharedPressure * dir * slope * mass / density
	
	return force

#func calculate_property(sample_point: Vector2) -> float:
	#var property: float = 0
#
	#for i in range(noOfBalls):
		#var dist = (Position[i] - sample_point).length() * SmoothingRadius
		#var influence = smoothing_kernel(dist, SmoothingRadius)
		#var densisty = densities[i]
		#property += particle_properties[i] * influence * mass
#
	#return property

#func calculate_property_gradient(samplePoint:Vector2) -> Vector2:
	#var propertyGradient: Vector2 = Vector2.ZERO
	#for i in range(noOfBalls):
		#var pos = Position[i]
		#var dst = (pos - samplePoint).length()
		#var dir = (pos - samplePoint)/dst
		#var slope = smoothing_kernel_derivative(dst, SmoothingRadius)
		#var density = densities[i]
		#
		#propertyGradient += - particle_properties[i] * dir * slope * mass / density
		#
	#return propertyGradient

func smoothing_kernel(dst: float, radius: float) -> float:
	if dst >= radius:
		return 0
	return (radius - dst) * (radius - dst) / (PI * pow(radius, 4) / 6)

func smoothing_kernel_derivative(dst: float, radius: float) -> float:
	if dst >= radius:
		return 0
	var scale = 12 / (pow(radius, 4) * PI)
	return (dst - radius) * scale

func update_densities():
	for i in range(noOfBalls):
		densities[i] = CalculateDensity(Position[i])

func converDensityToPressure(density:float) -> float:
	var densityError = density - targetDensity
	var pressure = densityError * PressureMultiplier
	return pressure

func sharedPressure(denA, denB) -> float:
	var sharedPressure = converDensityToPressure(denA) + converDensityToPressure(denB) /2
	return sharedPressure
func CalculateDensity(samplepoint) -> float:
	var density: float = 0
	for pos in Position:
		var dst = (pos - samplepoint).length()
		var influence = smoothing_kernel(dst, SmoothingRadius)
		density += mass * influence
		
	return density
	
