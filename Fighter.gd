extends RigidBody3D

#var particle_scene = preload("res://Particle.tscn")

var direction = Vector3(0,0,0)
var timer = 0
var randx = 0
var randz = 0
var state = Etat.Exploring

enum Etat{
	Exploring,
	Fighting,
}

#Stats d'un combattant
var speed:float = 0.5
var hp:int
var dmg:int
var team:int
var detectZoneRadius:float
var type:int
var fireRate:float = 2 # Nombre de coups par seconde
var distToFire:int # Distance minimal à laquelle le combattant peut tirer

var target = null # cible du combattant
var targeted = [] # les ennemis ciblant le combattant
var inArea = [] # Tous les combattants ennemis dans la zone

var isPlaying = false
var particle = preload("res://Particle.tscn")

signal dead(team) #Signal pour dire à Simulation.gd qu'un combattant est mort
signal inZoneChanged() #Signal appelé à chaque fois qu'un combattant entre ou sort de la zone de détection

# Au premier chargement de la scène
func _ready():
	#Définir le skin du perso en fonction de son équipe et son type
	setSkin()
	#Taille d'area de détection mise à jour
	var collisionShapeArea = self.get_node("Area3D/CollisionShape3D").shape.duplicate()
	collisionShapeArea.radius = detectZoneRadius
	self.get_node("Area3D/CollisionShape3D").shape = collisionShapeArea
	var meshShapeArea = self.get_node("Area3D/MeshInstance3D").mesh.duplicate()
	meshShapeArea.top_radius = detectZoneRadius
	self.get_node("Area3D/MeshInstance3D").mesh = meshShapeArea

func setSkin():
	var mesh = get_node("MeshInstance3D")
	#Selon son type, on choisit un skin différent
	if type == 1:
		if randi()%2 == 0:
			mesh.mesh = preload("res://assets/characters/Worker_Female.obj")
		else:
			mesh.mesh = preload("res://assets/characters/Worker_Male.obj")
		
		"""
		var newMat = mesh.get_surface_material(0).duplicate()#Couleur de peau
		newMat.albedo_color = Color(1,0.729,0.729)
		mesh.set_surface_override_material(0, newMat) 
		if team == 1:
			newMat = mesh.get_surface_material(2).duplicate()#Couleur de l'uniforme
			newMat.albedo_color = Color.BLUE
			mesh.set_surface_override_material(2, newMat) 
			
			newMat = mesh.get_surface_material(4).duplicate()#Couleur du casque
			newMat.albedo_color = Color.BLUE
			mesh.set_surface_override_material(4, newMat)
		
		
		else:
			newMat = mesh.get_surface_material(2).duplicate()#Couleur de l'uniforme
			newMat.albedo_color = Color.RED
			mesh.set_surface_override_material(2, newMat) 
			
			newMat = mesh.get_surface_material(4).duplicate()#Couleur du casque
			newMat.albedo_color = Color.RED
			mesh.set_surface_override_material(4, newMat)
		"""

	if type == 2:
		if randi()%2 == 0:
			mesh.mesh = preload("res://assets/characters/Chef_Female.obj")
		else:
			mesh.mesh = preload("res://assets/characters/Chef_Male.obj")

	if type == 3:
		if randi()%2 == 0:
			mesh.mesh = preload("res://assets/characters/Witch.obj")
		else:
			mesh.mesh = preload("res://assets/characters/Wizard.obj")

	if type == 4:
		if randi()%2 == 0:
			mesh.mesh = preload("res://assets/characters/Viking_Female.obj")
		else:
			mesh.mesh = preload("res://assets/characters/Viking_Male.obj")

			
			
		#var redMat = mesh.get_surface_override_material(1).duplicate()
		#redMat.albedo_color = Color.RED
		#mesh.set_surface_override_material(1, redMat)

# Appelé à chaque frame, delta est le temps écoulé depuis la dernière frame
func _process(delta):
	if !isPlaying : return # Si la simulation n'est pas lancée, on ne fait rien	
	
	#Si le combattant n'a plus de vie, il meurt
	if hp<=0:
		isDead()
		return

	#Si le combattant n'a pas de cible, il explore
	if state == Etat.Exploring:
		timer += delta
		if timer > 1:
			randx = randi_range(-1,1)
			randz = randi_range(-1,1)
			direction = Vector3(randx*speed,0,randz*speed)
			#le personnage rotate pour regarder dans la direction où il va
			look_at(global_position-direction, Vector3(0,1,0))
			timer = 0
			
		apply_central_impulse(direction)
		
	#Si le combattant a une cible, il se dirige vers elle et l'attaque
	if state == Etat.Fighting:
		timer += delta
		
		# Si on a atteint la cible, on passe en mode combat
		if global_position.distance_to(target.global_position) <= distToFire:
			#On regarde la cible
			look_at(target.global_position, Vector3(0,1,0))
			if timer > 1/fireRate:
				send_damage()
				timer = 0
		else: #Sinon on se rapproche suffisament d'abord, en regardant la cible
			#Toutes les 0.5s on recalcule la direction à prendre pour rejoindre la cible
			if timer > 0.5:
				direction = (target.global_position - global_position).normalized()*speed
				look_at(global_position-direction, Vector3(0,1,0))
				timer = 0
			apply_central_impulse(direction)
		

func isDead():
	# On enlève le combattant mort du target des ennemis qui le ciblaient
	for enemy in targeted:
		#Le combattant actuel n'est plus dans leur zone, ni leur cible
		#enemy.target = null
		var tmpInZone = enemy.inArea
		enemy.inArea = []
		for enemy2 in tmpInZone:
			if enemy2 != self:
				enemy.inArea.append(enemy2)

	if target != null:
		# Le combattant mort ne cible plus sa cible
		target.targeted.erase(self)

	# On informe la scène principale qu'un combattant est mort
	emit_signal("dead")
	#On supprime le combattant
	queue_free()

# Démarrer les mouvements
func on_playStateChange(state):
	isPlaying = state

# Dans la zone de détection, on se dirige vers son ennemi
func _on_area_3d_area_entered(area):
	if area.get_parent().team == self.team: return # Si c'est un allié
	inArea.append(area.get_parent())
	emit_signal("inZoneChanged")
	
func _on_area_3d_area_exited(area):
	inArea.erase(area.get_parent())
	emit_signal("inZoneChanged")

func send_damage():
	var particleInstance = particle.instantiate()
	particleInstance.global_transform.origin = global_transform.origin
	particleInstance.apply_central_impulse((target.global_position - global_position).normalized()*30)

	particleInstance.set_meta("team", team)
	particleInstance.set_meta("dmg", dmg)
	
	#Ajouter la particule au parent
	get_parent().add_child(particleInstance)
	
func receive_damage(damage):
	hp-=damage

func _on_dead():
	dead.emit(team)

#Quand un ennemi est entré ou sorti de la zone
func _on_in_zone_changed():
	#Je cherche à attaquer un ennemi
	if(len(inArea) > 0 && state != Etat.Fighting):
		target = inArea[0]
		state = Etat.Fighting

	#Si le seul combattant dans ma zone, que je combattais donc, meurt ou sort de ma zone, je ne combats plus
	if(len(inArea) == 0 && state == Etat.Fighting):
		target == null
		state = Etat.Exploring
		
	#Si mon ennemi n'est plus dans la zone, j'en cible un autre si possible
	if(target != null && !inArea.has(target)):
		if(len(inArea) > 0):
			target = inArea[0]
			state = Etat.Fighting
		else:
			target = null
			state = Etat.Exploring


func _on_area_3d_2_area_entered(area):
	var areaParent = area.get_parent().get_parent()
	if(areaParent.get_meta("team") != team):
		#Jouer le son de l'audioStreamPlayer
		get_node("AudioStreamPlayer3D").playing = true
		receive_damage(areaParent.get_meta("dmg"))
		areaParent.queue_free()
