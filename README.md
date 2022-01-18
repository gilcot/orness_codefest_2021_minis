# Orness Code Fest 2021 [Dev] - Mini Challenges > Cellular Life Simulation

Ce dépôt est ma petite contriution à l'[Orness Code Fest
2021](https://dojo.codes/articles/event-orness-code-fest-2021), pour la
campagne, du <abbr title="2021-04-09T20:00:00+2">9</abbr> au
<abbr title="2021-04-11T08:00:00+2">11 avril</abbr>, de [mini 
challenges](https://dojo.codes/campaigns/orness_codefest_2021_minis) qui
finalement n'en comportait qu'une seule. 

  * [d'abord la présentation du défi sur le site](#challenge)
  * [ensuite le petit topo sur cette contribution](#debriefing)

C'est parti.

![mini challenges](https://dojo-space.ams3.digitaloceanspaces.com/orness_codefest_mini.png)

## challenge

Author: bew

### Simulation de vie cellulaire

La vie cellulaire... Dans un monde si vaste et diversifié, le niveau
microscopique n'en voit qu'une toute petite partie et leur univers 
pourrait presque être qualifié de simple comparé à ce que nous connaissons.

L'objectif de ce challenge est de créer une simulation d'un amas de 
cellules dans un univers donné, à travers plusieurs générations.

#### Définition d'un univers

##### La grille:

Dans cette simulation, un univers est représenté par une grille de cellules 
à 2 dimensions de _taille infinie_.

Cette grille possède un système de coordonnées `(x, y)` qui permet de cibler
n'importe quelle cellule de la grille, relatif au point d'origine de la 
grille de coordonnées `(0, 0)`.
```
             ^ -y
             |
             |
             |
-x           |           +x
 <-----------X----------->
             |(0,0)
             |
             |
             |
             v +y
```

##### Une cellule:

Peut être dans 2 états possible: vivante (`x`) ou morte (`_`).

Une cellule (`C` ci-dessous) possède 8 voisines, qui sont les cellules 
adjacentes horizontalement, verticalement et diagonalement:
```
123
4C5
678
```

##### Les règles de l'univers:

Un univers est régi par _2 règles_ qui décident quelles cellules vont 
naître, survivre ou mourir pour la prochaine génération. Les détails des 
règles varient d'un univers à l'autre, mais le principe reste le même.

En fonction du nombre de cellules voisines vivante:

   - _La règle des naissances_ décide si une cellule morte va naître
   - _La règle de survie_ décide si une cellule vivante va survivre ou mourir

Les règles s'appliquent sur la génération courante, et leur application 
défini la prochaine génération de cette univers.

##### Extrait d'un univers:

Voici un extrait d'univers:
```
____xx__x__xxx_x
xx__x_xx_xx_x_xx
___xx_x_xx__x___
x_xx_xxx___x_x_x
_x___x_x__xx_x__
_x_x__x_x_x__x__
_xx_x_____xxx_xx
x___x_xx_x__x_x_
```

#### Entrée

Le programme de simulation recevra sur son entrée standard (`stdin`) un 
certain nombre de lignes représentant les paramètres de l'univers, ainsi 
que les informations sur la sortie attendue.

Le format est le suivant:
```
3,5,6          -- règle de naissance (ici: 3, 5 ou 6 voisines)
2,3            -- règle de survie (ici: 2 or 3 voisines)
-10,-5         -- coordonnées en haut à gauche de l'univers initial (ici: -10, -5)
13x7           -- taille de l'univers initial LARGEURxHAUTEUR
__xxx__x_xx_x
xxx_xx__x_xx_  -- la grille initiale de l'univers
x_xx__xxxx__x  -- dans cette example:
__x_x_xx_xx__  --   'O' montre le point d'origine (0, 0) de l'univers
_xx__xR__xxx_  --   'R' montre le point en haut à gauche de la grille attendu en sortie
x_xx___xx_O_x
__xx_x_x__x_x
42             -- génération attendue en sortie (0 étant la génération de départ)
3,3            -- première coordonnée du rectangle attendu en sortie
-4,-1          -- deuxième coordonnée du rectangle attendu en sortie
```

#### Sortie attendue

Le programme de simulation devra afficher sur sa sortie standard (`stdout`) 
un extrait de la grille de l'univers à une génération donnée (ces 
informations sont données en entrée).

Le format de la sortie est l'extrait de la grille, représenté sur une seule 
ligne (chaque ligne de la grille étant séparée par un `|`), suivie d'un 
retour à la ligne.

Si l'extrait de la grille est:
```
x__x____x
__xx_x_xx
_x_x___xx
```
La sortie attendue est: `x__x____x|__xx_x_xx|_x_x___xx\n`

#### Exemple de simulation complète

```
3
1,2,3,4
2,2
3x2
x__
xxx
8
0,5
5,0
```
Cette entrée nous donne les informations suivantes:

  - Règles de l'univers:
    - Une cellule nait si elle est entourée de 3 autres cellules vivantes
    - Une cellule survie si elle est entourée de 1, 2, 3 ou 4 autres cellules vivantes
  - La grille initiale de l'univers:
    - Le coin en haut à gauche est positionné aux coordonnées (x=2, y=2) de la grille infinie
    - Fais 3 colonnes et 2 lignes de cellules:
      - Ligne 1: vivante, morte, morte
      - Ligne 2: vivante, vivante, vivante
  - Résultat attendu:
    - 8 ème génération
    - Extrait de l'univers entre les points de coordonnées `(x=0, y=5)` et `(x=5, y=0)`

Voici un affichage de l'évolution de l'univers, vu depuis le rectangle 
d'affichage final:
```
+--------------+--------------+--------------+
| GENERATION 0 | GENERATION 1 | GENERATION 2 |
|              |              |              |
|    ______    |    ______    |    ______    |
|    ______    |    ______    |    ______    |
|    __x___    |    __x___    |    __x___    |
|    __xxx_    |    __xxx_    |    __xxx_    |
|    ______    |    ___x__    |    __xxx_    |
|    ______    |    ______    |    ______    |
|              |              |              |
+--------------+--------------+--------------+
| GENERATION 3 | GENERATION 4 | GENERATION 5 |
|              |              |              |
|    ______    |    ______    |    ______    |
|    ______    |    ______    |    __x___    |
|    __x___    |    _xxx__    |    _xxx__    |
|    _xx_x_    |    _xx_x_    |    x___x_    |
|    __x_x_    |    _xx_x_    |    _xx_x_    |
|    ___x__    |    ___x__    |    __xx__    |
|              |              |              |
+--------------+--------------+--------------+
| GENERATION 6 | GENERATION 7 | GENERATION 8 |
|              |              |              |
|    ______    |    __x___    |    __x___    |
|    _xxx__    |    _x_x__    |    xx_xx_    |
|    _xxx__    |    xx_xx_    |    xx_xx_    |
|    x___x_    |    x___x_    |    x___xx    |
|    _xx_x_    |    xxx_x_    |    x_x_x_    |
|    _xxx__    |    _xxx__    |    x__x__    |
|              |              |              |
+--------------+--------------+--------------+
```
La grille finale de la génération 8 est donc:
```
__x___
xx_xx_
xx_xx_
x___xx
x_x_x_
x__x__
```
Et sa représentation en une ligne attendu est:
`__x___|xx_xx_|xx_xx_|x___xx|x_x_x_|x__x__\n`

#### Indice pour représenter la grille infinie

Toutes les cellules de la grille n'ont pas nécessairement besoin d'être en 
mémoire, on peut par exemple ne garder en mémoire que les cellules vivantes.

#### 

**Note de l'editeur:** Une fois votre simulateur terminé, n'hésitez pas à 
jouer avec en faisant vos propre inputs, en lancant votre programme sur une
grosse grille et découvrez comment évoluent vos cellules sur le long terme! 
Vous pourriez bien découvrir des comportements explosifs, destructifs, 
statiques ou encore complètement random à-la-Matrix (: Utilisez le 
caractère unicode `█` pour les cellules vivantes pour un meilleur visuel!

### Test Case

(Un certain nombre de _test cases_ est prévu pour être lancé via un bouton,
et les tests ont trois paramètres dont deux qui sont vides ici)

|            |               |
|------------|---------------|
| Files      | `{}`          |
| Parameters | `[]`          |
| StdIn      | voir ci-après |

(le troisième est une chaîne qu'on va indiquer en le précédant du croisillon
avant de l'indiquer sous forme décomposée pour la lisibilité) 

#### Still block

```
#"3\n2,3\n1,1\n6x6\n______\n______\n__xx__\n__xx__\n______\n______\n1\n1,1\n6,6\n"
3
2,3
1,1
6x6
______
______
__xx__
__xx__
______
______
1
1,1
6,6
```

#### Blinker

```
#"3\n2,3\n1,1\n6x6\n______\n__x___\n__x___\n__x___\n______\n______\n5\n1,1\n5,5\n"
3
2,3
1,1
6x6
______
__x___
__x___
__x___
______
______
5
1,1
5,5
```

#### Maze (small)

```
#"3\n1,2,3,4\n1392,-5\n4x2\nxx_x\n_xxx\n40\n1407,-10\n1382,-20\n"
3
1,2,3,4
1392,-5
4x2
xx_x
_xxx
40
1407,-10
1382,-20
```

#### It's alive! (medium)

```
#"3,5,7\n1,3,5,8\n1,1\n16x12\n_xx__xx__xx__xx_\n_x_xx__x_x____xx\n________________\n_xx__xx__xx__xx_\n_x_xx__x_x_____x\n_xx_____x___x__x\n_xx___x___x____x\n________________\n_xx_____x___x__x\n_x_xx__x_xx_x_x_\n______xxxxx__xx_\nxxx__xx____x___x\n80\n-2,-5\n18,18\n"
3,5,7
1,3,5,8
1,1
16x12
_xx__xx__xx__xx_
_x_xx__x_x____xx
________________
_xx__xx__xx__xx_
_x_xx__x_x_____x
_xx_____x___x__x
_xx___x___x____x
________________
_xx_____x___x__x
_x_xx__x_xx_x_x_
______xxxxx__xx_
xxx__xx____x___x
80
-2,-5
18,18
```

## debriefing

Author: gilcot

### Pourquoi…

Introduisons le sujet en répondant à aux questions qui posent le contexte.

#### Non participation

Votre serviteur s'est inscrit pour cette édition par curiosité, mais n'a pu
vraiment participer… La semaine de travail chargée m'a achevée et j'ai été
dans un sorte de coma jusqu'à dix-huit heure et quelque et ai activé cette
campagne à mon réveil dimanche. Ensuite, suis allé faire un peu de ménage,
et ai fini par une douche vers vingt-et-une heure et une grosse faim… Je me
suis quand même remis au boulot le lundi soir, histoire d'aller au bout de
ce que j'ai commencé. Ne pouvant plus soumettre ma contribution, au passage
inachevée, ce dépôt livre en pâture mes pérégrinations.

#### La faisabilité

Parmi les langages possibles, il y avait Bash, qui une fois sélectionné
présentait le modèle suivant :
```sh
#!/bin/bash

# This is a placeholder, feel free to delete everything
# and start from scratch we won't be (too) mad (:

# --- Read program input from stdin
read birth_conditions_line
# ... parse other lines based on the challenge instructions

# --- Compute the simulation

# --- Get the universe extract from the wanted generation
#     and output it with the required format
echo "x__x____x|__xx_x_xx|_x_x___xx"

# If you're really trying in bash... good luck

```
Noter la seizième ligne : c'est vraiment un défi dans le défi quand
on peut utiliser Python 3.8.2 dans la liste de propositions. Mais ayant
déjà une bonne idée de ce qu'il faut faire dans les autres langages de la
liste (ayant fait quelques implémentations d'algorithmes de base en C sur
les graphes, et sachant comment transcrire cela en Go et en Java, je pense
même pouvoir transposer rapidement en C++ ou C# ou Rust ou Racket) je me
suis dit que ça peut être intéressant de voir dans quelle mesure c'est
faisable pour quelqu'un qui passe ses journées en administration système.
(sorte de <a href="https://fr.wikipedia.org/wiki/Preuve_de_concept"><abbr 
title="Proof of Concept">PoC</abbr></a> en quelque sorte.)

Mais soyons joueur : je ne vais pas utiliser les avantages de bourne
Again ou de Korn, mais rester POSIX… en espérant ne pas le regretter.

### Comment…

Poursuivons par l'analyse du cahier de charges et l'implémentation faite ici.

#### Entrée

Il y a quelques remarques à faire sur ce point. Je vais essayer de regrouper
mes pensées et remarques, et espère que mon propos ne sera pas trop confus.

##### saisie interactive

Bon, on devait lire un certain nombre de lignes sur l'entrée standard. Je
fais le choix inverse, au début, d'avoir une saisie intéractive pour ne pas
avoir à faire des aller-retours entre la page web et le script, ni me perdre
dans la longue liste. Et puis c'est quand même plus sympa d'avoir une vraie
interface bien que je devine que l'idée est de faire faire un composant qui
va probablement s'interfacer avec autre chose. Dans cette optique, je fais
arrêter le script le script dès qu'une mauvaise ligne est saisie…   
Le dimanche suivant, j'ai enfin ajouté la lecture des argument en argument.

##### grille initiale

Pas évident, mais pour moi, quand on a dit que :
> Cette grille possède un système de coordonnées `(x, y)` qui permet de 
> cibler n'importe quelle cellule de la grille, relatif au point d'origine 
> de la grille de coordonnées `(0, 0)`.

…alors je ne vois pas l'intérêt d'indiquer :
> 'O' montre le point d'origine (0, 0) de l'univers

…on sait où est l'origine en ayant les deux éléments précédants
  - coordonnées en haut à gauche de l'univers initial (ici : -10, -5)
  - taille de l'univers initial LARGEURxHAUTEUR (ici : 13x7)

De plus, ça me pose un autre souci : en mettant un caractère, `O`, on
ne peut plus indiquer si cet emplacement est occupé ou vide (ce qu'on fait
normalement avec `x` ou `_` ici.)

Contrairement à ce que je recommande, j'ai commencé à pondre du code avant
d'avoir pris connaissance de tout l'énoncé. Du coup, j'avais fait une 'tite
boucle dont on sort en saisissant une ligne vide. Après avoir vu l'exemple
donné, le mardi, j'ai modifié la boucle pour saisir autant de lignes que la
hauteur indiquée …et on tronque (ou compléte à blanc) à la largeur indiquée.

##### rectangle de sortie

Voici un autre truc pas très clair… Dans la saisie de la grille initiale, on
a aussi, comme pour l'origine :
> 'R' montre le point en haut à gauche de la grille attendue en sortie

Ça me pose le même problème : on ne sait plus si cette case est vivante
ou morte. De plus, pareillement, on a comme derniers paramètres, la première
et la deuxième « coordonnée du rectangle attendu en sortie » Si au début
j'ai cru que c'était un point de la grille initiale, l'exemple donné ensuite
montre que c'est un cadre englobant, ce qui n'est pas déconnant.

Petit bémol… Comme je traite les entrées au fur et à mesure (i.e. on ne
collecte pas d'abord pour les traitement tranquillement ensuite, mais au
contraire on fait au moins la validation au plus tôt pour arrêter au plus
vite en cas d'erreur), j'aurais préféré que ces deux coordonnées soient
saisies avant la grille initiale. Ce faisant, j'aurais pu préparer la grille
finale et y inscrire les cellules de départ, au lieu de devoir actullement
redimensionner la grille de départ (ce qui est un peu plus chronophage…)

#### Sortie

Ici aussi, il y a quelques remarques à faire.

##### Pas à pas

Je suis aussi allé à contre-indication ici, en ne présentant pas l'_uniline_
demandée mais plutôt en faisant un rendu de la fenêtre de sortie, et ce
à chaque génération : toujours le côté intéractif… Cependant, on n'utilise
pas les coordonnées pour de l'affichage en console : on met systématiquement
le coin haut-gauche de la sortie sur la première colonne de la ligne suivante
tout simplement. Bon, à l'arrivée, je l'ai masqué par une variable de niveau
de verbosité du débogage : il faut précéder l'appel du script par `DEBUG=1`
pour réactiver cela.

Au passage, encore merci pour l'exemple détaillé qui montre ce qui est voulu
car je n'avais pas le même décompte du nombre de colonnes entre `R1` et `R2`.
Bon, il a fallu recalculer par endroit pour retomber sur nos pattes.

##### Algo

Il reste un petit souci : mon exécution diffère de l'exemple à partir de la
huitième génération… On ne doit pas avoir le même algorithme, mais dispo pour
en discuter.
```
+--------------+--------------+--------------+
| GENERATION 6 | GENERATION 7 | GENERATION 8 |
|              |              |              |
|    ______    |    __x___    |    __x___    |
|    _xxx__    |    _x_x__    |    xx_xx_    |
|    _xxx__    |    xx_xx_    |    xx_xx_    |
|    x___x_    |    x___x_    |    x___xx    |
|    _xx_x_    |    xxx_x_    |    x_x_x_    |
|    _xxx__    |    _xxx__    |    xxxx__    |
|              |              |              |
+--------------+--------------+--------------+
```
Je suis preneur de toute demande de fusion/tirage apportant la correction.

##### Formatage

Petit bonus : pour la sortie j'ai traité l'affichage de l'origine, mais un
peu différement de juste afficher `O`… C'est perfectible, comme beaucoup
d'autres choses dans le script, et je suis preneur de toute suggestion. Par
contre, je n'ai pas traité le cas du premier coin de la fenêtre d'affichage
(peut-être dans une prochaine monture si je trouve que ça fait quelque sens.)

Dans le même esprit, tous les caractères utilisés peuvent être changé en
utilisant les bascules prévues à cet effet. Attention que les arguments
passés doivent contenir deux caractères, excepté pour le séparateur.

### Tests…

Résultats avec la différence d'algorithme

#### my Still block

```
______
______
__xx__
__xx__
______
______
```
Ici, le même bloc se répète indéfiniement.

#### my Blinker

```
______
______
_xxx__
______
______
```
…aux tours pairs, et
```
______
__x___
__x___
__x___
______

```
…aux tours impaires.

#### my Maze

```
__________________________
__________________________
__________________________
__________________________
__________________________
__________________________
__________________________
__________________________
__________________________
__________________________
__________________________
```
?
#### my Alive

```
_____________________
_____________________
_____________________
___________x_xx______
_________x_x__x______
_O_x_________xx______
_______xx____xx______
___xx__x_x_xxx_______
_______x_x_xx________
__x____x____x________
_xx_x_x___x_x________
_xxx_x_x____x________
___xx_____x__________
_xxx_xx_xx__xx_______
_xx_x_xxxxx__________
_x_______xxxxx_______
__x__x___x_xx_x______
____x________x_x_____
______x____xx__xx____
____________x_xxx____
_____________xxx_____
____________xxxx_____
____________x________
_____________________
```
Ça varie à chaque tour, faisant penser à une quelque [culture bactérienne
en milieu agar-agar](https://fr.wikipedia.org/wiki/Bo%C3%AEte_de_Petri).
Voici l'état dix générations plus tôt :
```
_____________________
_____________________
_____________________
__x________x_________
_________xx__________
_X_____x_xxx_x_______
_______x__xx_x_______
__x____xxxx_xx_______
_xxxxxx_x__x_________
_____xx_xx_____x_____
______xxx_xx_xx_x____
___xx_x_x___xxxxx____
___xxx_xx___x___x____
___x__x_xxx_x________
___xx_xxx_xx__xx_____
__x____xx____x_x_____
______xxx__x____x____
_____xx_xx_xx________
__________x__x_______
____________x________
__________x_x________
__________xxx________
___________x_________
____________x________
```
Au passage, on voit que plus la fenêtre est grosse plus le script met du
temps à se dérouler, mais ça semble proportionnel (`O(n)` à vu de nez…)

