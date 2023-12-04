# BagarreBagarre
Projet de M2 - Simulation multi-agents
Réalisation sous Godot 4

# Le projet
Le but était de représenter un système multi-agents (Minimum 4 classes d'agents différents) sous Godot.
J'ai donc choisi de simuler une bagarre entre fermiers voisins.
La simulation prend la forme d'un jeu en 1vs1, dans laquelle il faut composer son équipe avant de lancer l'exécution de la simulation, grâce à une quantité initiale de jetons à dépenser.
Chaque jour peut alors choisir entre 4 types d'agents, et pourra également choisir (soit au début soit pendant une pause) une stragégie que devront suivre les agents.

# Les agents
- Les combattants : Unités au coût faible, et aux statistiques moyennes
- Les chefs : Unités onéreuses, avec un champ de vision plus important
- Les chamans : Unités onéreuses, rapides et fragiles mais avec une grande distance de tir
- Les gros balourds : Unités très onéreuses, lentes et myopes, mais avec une grande résistance et de gros dégâts

# Les stragéties
- Attaque frontale : Augmentation des statistiques de 20%
- Fuite : Les unités dont les points de vie sont inférieurs à 25% cherchent à se faire décibler de leur attaquant
- Vive le chef : Les chefs partagents leur vision avec les autres unités, et peuvent leur attribuer des cibles

# Fonctionnement
Les unités sont placées aléatoirement dans leur partie de l'arène. Une fois la simulation lancée, ils sont en phase d'exploration, à la recherche d'un ennemi, et se déplacent donc aléatoirement.
Lorsqu'un ennemi est détecté, ils sont en phase d'attaque et cherchent à éliminer leur adversaire, grâce à un lancer de poulet (le poulet est porteur de l'information de dégât).
La simulation prend fin lorsque l'une des deux équipe n'est plus représentée.
