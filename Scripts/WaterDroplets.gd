extends Node2D
@export var gravity = 0
var ballSize = 10
var ParticleSpacing = 1
var noOfBalls = 75
var damping = 0.99
var Position = []
var Velocity = []
var Acceleration = []
var Box = Vector2(2000,1000)
var SmoothingRadius = 300
var Hex = []
var forceDist = 1
var forceMag = 10
var mass = 10
var viscosity = 15
var particle_properties = []
@export var densities: Array[float]
@export var targetDensity = 1
@export var PressureMultiplier = 100
var spatial_lookup = []
var start_indices = []
var offset = [Vector2(SmoothingRadius,0),Vector2(SmoothingRadius,SmoothingRadius),Vector2(0,SmoothingRadius),Vector2(-SmoothingRadius,SmoothingRadius),Vector2(-SmoothingRadius,0),Vector2(-SmoothingRadius,-SmoothingRadius),Vector2(0,-SmoothingRadius),Vector2(SmoothingRadius,-SmoothingRadius)]

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
		#Position.append(Vector2(randf_range(-Box.x/2, Box.x/2),randf_range(-Box.y/2, Box.y/2)))
		Acceleration.append(Vector2(0,0))
		c+=1
		particle_properties.append(1)
		densities.append(1)

	_draw() # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$TextEdit.text = str(Performance.get_monitor(Performance.TIME_FPS))
	
func _physics_process(delta):
	queue_redraw()
	for c in range(noOfBalls):
		densities[c] = CalculateDensity(Position[c])
		Position_handeling(c)

func Position_handeling(c):
	var pos = Position[c]
	var vel = Velocity[c]
	
	Acceleration[c] = calculateForce(c) / densities[c] - viscosity * (vel/mass) + Vector2(0, gravity)
	
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
	densityError *= 1 if densityError<0 else -1
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
	
# Assuming points is a list of Vector2 and radius is a float
func update_spatial_lookup(points: Array, radius: float) -> void:
	self.points = points
	self.radius = radius



	# Create (unordered) spatial lookup
	for i in range(points.size()):
		var vector= position_to_cell_coord(points[i], radius)
		var cell_x = vector.x
		var cell_y = vector.y
		var cell_key = get_key_from_hash(hash_cell(cell_x, cell_y))
		spatial_lookup.append({"index": i, "cell_key": cell_key})
		start_indices.append(null)  

	# Sort by cell key
	spatial_lookup.sort_custom(SortByCellKey)

	# Calculate start indices of each unique cell key in the spatial lookup
	for i in range(points.size()):
		var key = spatial_lookup[i]["cell_key"]
		var key_prev = spatial_lookup[i - 1]["cell_key"] if i > 0 else null
		if key != key_prev:
			start_indices[key] = i

# Sort function (helper)
func SortByCellKey(a, b):
	return int(a["cell_key"]) - int(b["cell_key"])

# Mock functions to replace undefined methods in the original code
func position_to_cell_coord(point: Vector2, radius: float) -> Vector2:
	var x:int = point.x/radius
	var y:int = point.y/radius
	return Vector2(x,y)

func hash_cell(cell_x: int, cell_y: int) -> int:
	var a:int = cell_x * 15823
	var b:int = cell_y * 9737333
	return int(a + b)

func get_key_from_hash(hash: int) -> int:
	return hash % int(len(spatial_lookup))

func ForeachPointInRadius(samplePoint:Vector2):
	var vec = position_to_cell_coord(samplePoint, SmoothingRadius)
	var center_x = vec.x
	var center_y = vec.y
	var sqrRadius = SmoothingRadius * SmoothingRadius
	
	#loop over all the cells in a 3x3 radius around the current cell
	for vector in offset:
		var key = get_key_from_hash(hash_cell(center_x+vector.x, center_y + vector.y))
		var cellStartIndex = start_indices[key]
		var i = cellStartIndex
		while i < len(spatial_lookup):
			if(spatial_lookup[i].cell_key != key): break
			var particleIndex = spatial_lookup[i].index
			var sqrDist = (Position[particleIndex] - samplePoint).length_squared()
			i+=1
			if sqrDist<=sqrRadius:
					var force = Vector2.ZERO
					
					for p in range(noOfBalls):
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
					
