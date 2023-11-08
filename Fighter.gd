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
	Escaping,
}

#Stats d'un combattant
var speed:float
var hp:float
var initHp:float
var dmg:float
var team:int
var detectZoneRadius:float
var type:int
var fireRate:float # Nombre de coups par seconde
var distToFire:int # Distance minimal à laquelle le combattant peut tirer

var target = null # cible du combattant
var targeted = [] # les ennemis ciblant le combattant
var inAreaEnnemy = [] # Tous les combattants ennemis dans la zone
var inAreaAlly = [] # Tous les combattants alliés dans la zone

var strat

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
	
	change_direction() #Donner une direction initiale au combattant


	#Leurs dégats sont compris entre +20% et -20% de leur valeur initiale
	dmg = dmg + randf()*dmg*0.4 - dmg*0.2

	#Leurs vitesse est comprise entre +20% et -20% de leur valeur initiale
	speed = speed + randf()*speed*0.4 - speed*0.2

	#Leurs hp sont compris entre +20% et -20% de leur valeur initiale
	hp = hp + randf()*hp*0.4 - hp*0.2

	#Leurs vitesses de tir sont comprises entre +20% et -20% de leur valeur initiale
	fireRate = fireRate + randf()*fireRate*0.4 - fireRate*0.2

	initHp = hp

func setSkin():
	var mesh = get_node("MeshInstance3D")
	#Selon son type, on choisit un skin différent, avec une proba de 1/2 que ça soit le skin homme ou femme
	if type == 1:
		if randi()%2 == 0:
			mesh.mesh = preload("res://assets/characters/Worker_Female.obj")
		else:
			mesh.mesh = preload("res://assets/characters/Worker_Male.obj")

	if type == 2:
		if randi()%2 == 0:
			mesh.mesh = preload("res://assets/characters/Chef_Female.obj")
		else:
			mesh.mesh = preload("res://assets/characters/Chef_Male.obj")
			
		# On définit un surface override material au slot 4, qui est la couleur du casque
		var newMat = mesh.get_surface_override_material(5).duplicate()
		if team == 1:
			newMat.albedo_color = Color.BLUE
		else:
			newMat.albedo_color = Color.RED

		mesh.set_surface_override_material(5, newMat)

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
			
	if type == 1 || type == 3 || type == 4:
		# On définit un surface override material au slot 4
		var newMat = mesh.get_surface_override_material(4).duplicate()
		if team == 1:
			newMat.albedo_color = Color.BLUE
		else:
			newMat.albedo_color = Color.RED

		mesh.set_surface_override_material(4, newMat)
			
	# On définit un surface override material au slot 0, qui est la couleur de peau
	var newMat = mesh.get_surface_override_material(0).duplicate()
	if randi()%2 == 0:
		newMat.albedo_color = Color.BURLYWOOD
	else:
		newMat.albedo_color = Color.BLACK
	mesh.set_surface_override_material(0, newMat)


# Appelé à chaque frame, delta est le temps écoulé depuis la dernière frame
func _process(delta):

	#Si le combattant n'a plus de vie, il meurt
	if hp<=0:
		isDead()
		return
		
	if !isPlaying : 
		apply_central_impulse(Vector3.ZERO)
		return # Si la simulation n'est pas lancée, on ne fait rien
		
	if state == Etat.Escaping:
		if len(targeted) == 0: #Si on s'est déciblé, on attaque un ennemi dans la zone si possible, sinon on explore
			hp+=10 #On regagne 10 hp
			if len(inAreaEnnemy) > 0:
				target = inAreaEnnemy[0]
				target.targetMe(self)
				state = Etat.Fighting
			else:
				state = Etat.Exploring
		else:
			#On se déplace dans la direction opposée à la cible plus rapidement que d'habitude
			apply_central_impulse(-direction*1.3)

	
	#Si le combattant n'a pas de cible, il explore
	elif state == Etat.Exploring:
		timer += delta
		apply_central_impulse(direction)
		
	#Si le combattant a une cible, il se dirige vers elle et l'attaque
	elif state == Etat.Fighting:
		if type == 2 && strat == 3: #On est un chef et on est dans le mode ViveLeChef
			#On parcours tous les alliés dans notre zone, s'ils n'ont pas de cible on leur attribue la notre
			for ally in inAreaAlly:
				if ally.target == null:
					ally.target = target
					ally.state = Etat.Fighting
					target.targeted.append(ally)
		
		timer += delta
		
		if !target: #Si la cible n'existe plus, on cherche un autre ennemi dans la zone
			if len(inAreaEnnemy) > 0:
				target = inAreaEnnemy[0]
				target.targetMe(self)
				state = Etat.Fighting
			else:
				state = Etat.Exploring
			return
		
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

	#Si le combattant n'est dans aucun des états précédents, il regarde si il peut attaquer, sinon il explore
	else:
		if len(inAreaEnnemy) > 0:
			target = inAreaEnnemy[0]
			target.targetMe(self)
			state = Etat.Fighting
		else:
			state = Etat.Exploring
		

func isDead():
	# On enlève le combattant mort du target des ennemis qui le ciblaient
	for enemy in targeted:
		#Le combattant actuel n'est plus dans leur zone, ni leur cible
		#enemy.target = null
		if !enemy: return
		var tmpInZone = enemy.inAreaEnnemy
		enemy.inAreaEnnemy = []
		for enemy2 in tmpInZone:
			if enemy2 != self:
				enemy.inAreaEnnemy.append(enemy2)

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
	if area.get_parent().is_in_group("fighter") && area.get_parent().team == self.team && area.get_parent()!=self: # Si c'est un combattant allié, et que ce n'est pas lui
		inAreaAlly.append(area.get_parent())
	elif area.get_parent().is_in_group("fighter") && area.get_parent().team != self.team && area.get_parent()!=self:
		inAreaEnnemy.append(area.get_parent())
		emit_signal("inZoneChanged")
	
func _on_area_3d_area_exited(area):
	if area.get_parent().is_in_group("fighter") && area.get_parent().team == self.team: #C'est un allié:
		inAreaAlly.erase(area.get_parent())
	else:
		inAreaEnnemy.erase(area.get_parent())
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
	if strat == 2 && len(targeted) > 0 && hp < initHp*0.5: #On est en stratégie de Fuite, et on doit fuir
		state = Etat.Escaping
		target = null
		
func targetMe(ennemy):
	if !targeted.has(ennemy):
		targeted.append(ennemy)

func _on_dead():
	dead.emit(team)

#Quand un ennemi est entré ou sorti de la zone
func _on_in_zone_changed():
	#Je cherche à attaquer un ennemi
	if(len(inAreaEnnemy) > 0 && state != Etat.Fighting):
		target = inAreaEnnemy[0]
		target.targetMe(self)
		state = Etat.Fighting

	#Si le seul combattant dans ma zone, que je combattais donc, meurt ou sort de ma zone, je ne combats plus
	if(len(inAreaEnnemy) == 0 && state == Etat.Fighting):
		target == null
		state = Etat.Exploring
		
	#Si mon ennemi n'est plus dans la zone, j'en cible un autre si possible
	if(target != null && !inAreaEnnemy.has(target)):
		if(len(inAreaEnnemy) > 0):
			target = inAreaEnnemy[0]
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
		
func change_direction():
	if state == Etat.Exploring || state == Etat.Escaping:
		var valid_directions = []  # Stocke les directions valides pour le déplacement

		# Génère les huit directions possibles (Nord, Sud, Est, Ouest et les diagonales)
		var directions = [
			Vector3(0, 0, -speed), 
			Vector3(0, 0, speed), 
			Vector3(-speed, 0, 0), 
			Vector3(speed, 0, 0), 
			Vector3(-speed, 0, -speed), 
			Vector3(speed, 0, -speed), 
			Vector3(-speed, 0, speed), 
			Vector3(speed, 0, speed)
		]

		for direction_attempt in directions:
			# Vérifie si la direction entraîne une collision avec un mur (ou sort de la zone de jeu, si nécessaire)
			var new_position = global_transform.origin + direction_attempt
			var collision_shape = move_and_collide(direction_attempt)

			if not collision_shape:
				# Si la direction n'entraîne pas de collision, elle est valide
				valid_directions.append(direction_attempt)

		if valid_directions.size() > 0:
			# S'il y a des directions valides, choisissez-en une aléatoirement parmi celles-ci
			direction = valid_directions[randi_range(0, valid_directions.size() - 1)]

		# Faites en sorte que le personnage regarde dans la direction où il va
		look_at(global_transform.origin - direction, Vector3(0, 1, 0))
