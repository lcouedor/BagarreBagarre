extends Node3D

var fighter = preload("res://Fighter.tscn")
var jetons1
var nbFighters1
var jetons2
var nbFighters2

signal playStateChanged(state)
var isPlaying

var VboxLabels1
var VboxLabels2
var VBoxButtons1
var VBoxButtons2
var VBoxStrat1
var VBoxStrat2
var subViewport
var btnPlay
var finished = false

enum Strat{
	AttaqueFrontale,
	Evolution,
	Fuite,
	ViveLeChef,
}
var strategieJ1 = Strat.AttaqueFrontale
var strategieJ2 = Strat.AttaqueFrontale

signal stratChanged(newStrat, joueur)

#Tableau de caméras
var camera = []
var cameraActive = 4 #indice de la caméra active

var currentStrat = 1 #Stratégie active

#Initialisation des variables, la fonction peut être appelée pour relancer une partie
func init():
	finished = false
	isPlaying = false
	btnPlay.text = "Jouter"
	# On supprime tous les combattants
	var fighters = get_node("Fighters").get_children()
	for fighter in fighters:
		fighter.queue_free()
	# On remet les jetons et les combattants à leur état initial
	jetons1 = 20
	jetons2 = 20
	nbFighters1 = 0
	nbFighters2 = 0
	# On remet les labels à jour
	VboxLabels1.get_node("JetonsPlayer1").text = "Jetons joueur 1 : " + str(jetons1)
	VboxLabels2.get_node("JetonsPlayer2").text = "Jetons joueur 2 : " + str(jetons2)
	VboxLabels1.get_node("NbFighters1").text = "Combattants joueur 1 : " + str(nbFighters1)
	VboxLabels2.get_node("NbFighters2").text = "Combattants joueur 2 : " + str(nbFighters2)
	
	subViewport.get_node("Winner").text = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	subViewport = get_node("SubViewportContainer/SubViewport")
	VboxLabels1 = subViewport.get_node("VBoxTextPlayer1")
	VboxLabels2 = subViewport.get_node("VBoxTextPlayer2")
	
	VBoxButtons1 = subViewport.get_node("VBoxButtonsPlayer1")
	VBoxButtons2 = subViewport.get_node("VBoxButtonsPlayer2")
	
	VBoxStrat1 = subViewport.get_node("VBoxStratPlayer1")
	VBoxStrat2 = subViewport.get_node("VBoxStratPlayer2")
	
	btnPlay = subViewport.get_node("Play")
	
	#Gestion des caméras
	camera.append(get_node("Caméras/Camera1"))
	camera.append(get_node("Caméras/Camera2"))
	camera.append(get_node("Caméras/Camera3"))
	camera.append(get_node("Caméras/Camera4"))
	camera.append(get_node("Caméras/Camera5"))
	camera.append(get_node("Caméras/Camera6"))
	camera[cameraActive].current = true

	init()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	subViewport.size.x = get_viewport().size.x #Toujours avoir la largeur de l'écran
	subViewport.size.y = get_viewport().size.y #Toujours avoir la hauteur de l'écran
	
	VboxLabels1.get_node("JetonsPlayer1").text = "Jetons joueur 1 : " + str(jetons1)
	VboxLabels2.get_node("JetonsPlayer2").text = "Jetons joueur 2 : " + str(jetons2)
	VboxLabels1.get_node("NbFighters1").text = "Combattants joueur 1 : " + str(nbFighters1)
	VboxLabels2.get_node("NbFighters2").text = "Combattants joueur 2 : " + str(nbFighters2)
	
	if(!isPlaying && (nbFighters1 == 0 || nbFighters2 == 0) && !finished): #Les combattants n'ont pas été choisis, on ne peut pas lancer
		btnPlay.disabled = true
	elif(!isPlaying && nbFighters1 > 0 && nbFighters2 > 0): #Les équipes sont faites, on peut se battre
		btnPlay.text = "Jouter"
		btnPlay.disabled = false
	elif(isPlaying): #On peut mettre sur pause
		btnPlay.text = "Pause"
		
	
	#On change de couleur les boutons de stratégie qui ne sont pas sélectionnés
	#if strategieJ1 == 1:
		#VBoxStrat1.get_node("ChoixStrat1").color = Color(0,0,0)
		
	
	#Gérer les boutons d'ajout de troupe
	if(isPlaying):
		VBoxButtons1.get_node("AddFighter1").disabled = true
		VBoxButtons1.get_node("AddChief1").disabled = true
		VBoxButtons1.get_node("AddWizard1").disabled = true
		VBoxButtons1.get_node("AddTank1").disabled = true
		
		VBoxButtons2.get_node("AddFighter2").disabled = true
		VBoxButtons2.get_node("AddChief2").disabled = true
		VBoxButtons2.get_node("AddWizard2").disabled = true
		VBoxButtons2.get_node("AddTank2").disabled = true
		
		
		
		VBoxStrat1.get_node("ChoixStrat1").disabled = true
		VBoxStrat1.get_node("ChoixStrat2").disabled = true
		VBoxStrat1.get_node("ChoixStrat3").disabled = true
		VBoxStrat1.get_node("ChoixStrat4").disabled = true
		
	else:
		VBoxButtons1.get_node("AddFighter1").disabled = false
		VBoxButtons1.get_node("AddChief1").disabled = false
		VBoxButtons1.get_node("AddWizard1").disabled = false
		VBoxButtons1.get_node("AddTank1").disabled = false
		
		VBoxButtons2.get_node("AddFighter2").disabled = false
		VBoxButtons2.get_node("AddChief2").disabled = false
		VBoxButtons2.get_node("AddWizard2").disabled = false
		VBoxButtons2.get_node("AddTank2").disabled = false
		
		
		if nbFighters1 > 0 && nbFighters2 > 0:
			VBoxStrat1.get_node("ChoixStrat1").disabled = false
			VBoxStrat1.get_node("ChoixStrat2").disabled = true
			VBoxStrat1.get_node("ChoixStrat3").disabled = false
			VBoxStrat1.get_node("ChoixStrat4").disabled = false
		else:
			VBoxStrat1.get_node("ChoixStrat1").disabled = true
			VBoxStrat1.get_node("ChoixStrat2").disabled = true
			VBoxStrat1.get_node("ChoixStrat3").disabled = true
			VBoxStrat1.get_node("ChoixStrat4").disabled = true
			

func _input(event):
	if event.is_action_released("ChangeCameraPlus"):
		camera[cameraActive].current = false
		cameraActive = (cameraActive+1)%len(camera)
		camera[cameraActive].current = true

	if event.is_action_released("ChangeCameraMoins"):
		camera[cameraActive].current = false
		cameraActive = (cameraActive-1)%len(camera)
		camera[cameraActive].current = true

# Créer un combattant avec ses stats et infos
func createFighter(team,type):
	if team == 1 && jetons1 < type : return # Pas possible d'ajouter au joueur 1
	if team == 2 && jetons2 < type : return # Pas possible d'ajouter au joueur 2
	
	#Sinon on peut ajouter le combattant
	var fighter1 = fighter.instantiate()
	fighter1.team = team
	
	#On définit ses stats selon son type
	if type == 1: #Simple soldat
		fighter1.hp = 30.0
		fighter1.dmg = 1.0
		fighter1.detectZoneRadius = 0.0
		fighter1.distToFire = 3
		fighter1.type = 1
		fighter1.speed = 0.0
	elif type == 2: #Chef
		fighter1.hp = 3.0
		fighter1.dmg = 1.0
		fighter1.detectZoneRadius = 30.0
		fighter1.distToFire = 20
		fighter1.type = 2
		fighter1.speed = 0.5
	elif type == 3: #Sorcier
		fighter1.hp = 2.0
		fighter1.dmg = 2.0
		fighter1.detectZoneRadius = 1.0
		fighter1.distToFire = 2
		fighter1.type = 3
		fighter1.speed = 0.5
	elif type == 4: #Tank
		fighter1.hp = 3.0
		fighter1.dmg = 3.0
		fighter1.detectZoneRadius = 25.0
		fighter1.distToFire = 15
		fighter1.type = 4
		fighter1.speed = 0.5
	
	# Décrémenter les jetons et positionner le combattant avant de l'ajouter
	if team == 1: # Equipe 1
		jetons1-=type
		nbFighters1+=1
		
		#On le positionne dans sa partie de la carte
		fighter1.position.x = 10
		fighter1.position.z = nbFighters1*1.5 + 10
			
	if team == 2: # Equipe 2
		jetons2-=type
		nbFighters2+=1
		
		#On le positionne dans sa partie
		fighter1.position.x = 40
		fighter1.position.z = nbFighters2*1.5 + 10
		
	fighter1.connect("dead", fighterDead)
	get_node("Fighters").add_child(fighter1)


func fighterDead(team):
	if team == 1:
		nbFighters1-=1
	elif team == 2:
		nbFighters2-=1
		
	if nbFighters1 == 0 || nbFighters2 == 0:
		btnPlay.text = "Le conflit reprend"
		finished = true
		btnPlay.disabled = false
		isPlaying = false
		playStateChanged.emit(isPlaying)
		
	if nbFighters1 > 0 && nbFighters2 == 0:
		subViewport.get_node("Winner").text = "Bravo joueur 1, tu as fièrement défendu tes terres"
	elif nbFighters2 > 0 && nbFighters1 == 0:
		subViewport.get_node("Winner").text = "Bravo joueur 2, tu as fièrement défendu tes terres"
	elif nbFighters1 == 0 && nbFighters2 == 0:
		subViewport.get_node("Winner").text = "On dirait que vous méritez tous les deux vos terres"


func _on_add_fighter_1_pressed():
	createFighter(1,1)


func _on_add_chief_1_pressed():
	createFighter(1,2)


func _on_add_wizard_1_pressed():
	createFighter(1,3)


func _on_add_tank_1_pressed():
	createFighter(1,4)


func _on_add_fighter_2_pressed():
	createFighter(2,1)


func _on_add_chief_2_pressed():
	createFighter(2,2)


func _on_add_wizard_2_pressed():
	createFighter(2,3)


func _on_add_tank_2_pressed():
	createFighter(2,4)


func _on_play_pressed():
	if(!isPlaying && nbFighters1>0 && nbFighters2>0):
		isPlaying = true
		playStateChanged.emit(isPlaying)
	elif(isPlaying):
		isPlaying = false;
		playStateChanged.emit(isPlaying)
	else:
		init()


func _on_choix_strat_1_pressed():
	strategieJ1 = Strat.AttaqueFrontale
	stratChanged.emit(strategieJ1,1)
	currentStrat = 1


func _on_choix_strat_2_pressed():
	strategieJ1 = Strat.Evolution
	stratChanged.emit(strategieJ1,1)
	currentStrat = 2


func _on_choix_strat_3_pressed():
	strategieJ1 = Strat.Fuite
	stratChanged.emit(strategieJ1,1)
	currentStrat = 3


func _on_choix_strat_4_pressed():
	strategieJ1 = Strat.ViveLeChef
	stratChanged.emit(strategieJ1,1)
	currentStrat = 4
