import sys
import os
import math
import random
import copy

class GameManager:
	def __init__(self, player1, player2):
		self.player1 = player1
		self.player2 = player2
		self.internalTurnNum = 0
		self.turnNum = 0
		self.isPlayer1Turn = False

	def updateState(self):
		self.update_removeDeadCards()
		winner = self.update_checkForWinner()
		if winner == 1:
			self.handleEndOfGame(winner=self.player1, loser=self.player2)
			return
		if winner == 2:
			self.handleEndOfGame(winner=self.player2, loser=self.player1)
			return
		if winner == 3:
			self.handleEndOfGame(winner=None, loser=None)
			return

	def update_removeDeadCards(self):
		for player in [self.player1, self.player2]:
			for card in player.board:
				if card.health <= 0:
					player.graveyard.append(card)
					player.board.remove(card)

	def update_checkForWinner(self):
		p1IsAlive = (self.player1.health != 0)
		p2IsAlive = (self.player2.health != 0)
		# 0=Nothing, 1=P1 wins, 2=P2 wins, 3=Draw
		if not (p1IsAlive or p2IsAlive):
			return 3
		if p1IsAlive and (not p2IsAlive):
			return 1
		if (not p1IsAlive) and p2IsAlive:
			return 2
		return 0

	def incrementTurn(self):
		self.internalTurnNum += 1
		self.turnNum = math.ceil(self.internalTurnNum / 2.0)
		self.isPlayer1Turn = (self.internalTurnNum % 2 == 1)
		if self.isPlayer1Turn:
			self.initPlayerTurn(self.player1)
		else:
			self.initPlayerTurn(self.player2)
		self.updateState()

	def initPlayerTurn(self, player):
		player.maxMana = min(player.maxMana+1, 10)
		player.mana = player.maxMana
		for card in player.board:
			card.canAttack = True
		player.attemptDrawCard()

	def handleEndOfGame(self, winner, loser):
		if winner is not None:
			print("\n"+winner.name+" Wins!")
			sys.exit()
		else:
			print("Draw...")
			sys.exit()

class Player:
	def __init__(self, playerID, name, cardsByID, deckByIndices):
		self.playerID = playerID
		self.name = name
		self.cardsByID = cardsByID
		self.deckByIndices = deckByIndices
		self.hand = []
		self.board = []
		self.graveyard = []
		self.maxHealth = 30
		self.health = self.maxHealth
		self.maxMana = 0
		self.mana = 0
		self.attack = 0

	def prepareAndShuffleDeck(self):
		self.deck = []
		self.deck = getCardsByID([self.cardsByID[index] for index in self.deckByIndices])
		self.shuffleDeck()

	def shuffleDeck(self):
		random.shuffle(self.deck)

	def attemptDrawCard(self):
		if len(self.deck) > 0:
			newCard = self.deck.pop()
			if len(self.hand) < 10:
				self.hand.append(newCard)
		else:
			self.takeDamage(1)

	def playFromHand(self, card):
		self.hand.remove(card)
		card.owner = self
		self.board.append(card)
		card.activateBattlecry()
		self.mana -= card.cost

	def restoreHealth(self, val):
		self.health = min(self.health + val, self.maxHealth)

	def takeDamage(self, val):
		self.health -= val
		if self.health <= 0:
			self.die()

	def die(self):
		pass

	def hasTauntOnBoard(self):
		for card in self.board:
			if card.hasTaunt:
				return True
		return False

class Card:
	def __init__(self, name="PLACEHOLDER", cardID=0, rarity=0, cost=0, attack=1, health=1, hasTaunt=False, hasCharge=False, battlecryType=None, battlecryArg=None):
		# Identification
		self.name = name
		self.cardID = cardID
		self.rarity = 0 # 0=Common, 1=Rare, 2=Epic, 3=Legendary
		# Stats
		self.cost = cost
		self.original_attack = attack
		self.original_health = health
		self.original_hasTaunt = hasTaunt
		self.original_hasCharge = hasCharge
		self.battlecryType = battlecryType
		self.battlecryArg = battlecryArg
		# Initialize starting stats
		self.attack = attack
		self.maxHealth = health
		self.health = health
		self.hasTaunt = hasTaunt
		self.hasCharge = hasCharge
		self.owner = None
		self.canAttack = hasCharge

	def setOwner(self, player):
		self.owner = player

	def performAttack(self, other):
		other.takeDamage(self.attack)
		self.takeDamage(other.attack)
		self.canAttack = False

	def takeDamage(self, val):
		self.health -= val
		if self.health <= 0:
			self.die()

	def die(self):
		pass

	def setAttack(self, val):
		self.attack = val

	def increaseAttack(self, val):
		self.attack += val

	def setHealthAndMaxHealth(self, val):
		self.maxHealth = val
		self.health = val

	def increaseHealth(self, val):
		self.maxHealth += val
		self.health += val

	def restoreHealth(self, val):
		self.health = min(self.health + val, self.maxHealth)

	def silence(self):
		self.attack = self.original_attack
		self.maxHealth = self.original_health
		self.health = min(self.health, self.maxHealth)
		self.hasTaunt = False
		self.hasCharge = False

	def activateBattlecry(self):
		if self.battlecryType == "summon":
			self.battlecry_summon(self.battlecryArg)

	def battlecry_summon(self, cardIDs):
		cards = getCardsByID(cardIDs)
		for card in cards:
			if len(self.owner.board) < 7:
				card.owner = self.owner
				self.owner.board.append(card)



# Card Library

allCards = [
	Card(
		cardID        = 1,
		name          = "Goldshire Footman",
		rarity        = 0,
		cost          = 1,
		attack        = 1,
		health        = 2,
		hasTaunt      = True,
		hasCharge     = False,
		battlecryType = None,
		battlecryArg  = None
		),
	Card(
		cardID        = 2,
		name          = "Stonetusk Boar",
		rarity        = 0,
		cost          = 1,
		attack        = 1,
		health        = 1,
		hasTaunt      = False,
		hasCharge     = True,
		battlecryType = None,
		battlecryArg  = None
		),
	Card(
		cardID        = 3,
		name          = "Bloodfen Raptor",
		rarity        = 0,
		cost          = 2,
		attack        = 3,
		health        = 2,
		hasTaunt      = False,
		hasCharge     = False,
		battlecryType = None,
		battlecryArg  = None
		),
	Card(
		cardID        = 4,
		name          = "Bluegill Warrior",
		rarity        = 0,
		cost          = 2,
		attack        = 2,
		health        = 1,
		hasTaunt      = False,
		hasCharge     = True,
		battlecryType = None,
		battlecryArg  = None
		),
	Card(
		cardID        = 5,
		name          = "Frostwolf Grunt",
		rarity        = 0,
		cost          = 2,
		attack        = 2,
		health        = 2,
		hasTaunt      = True,
		hasCharge     = False,
		battlecryType = None,
		battlecryArg  = None
		),
	Card(
		cardID        = 6,
		name          = "River Crocolisk",
		rarity        = 0,
		cost          = 2,
		attack        = 2,
		health        = 3,
		hasTaunt      = False,
		hasCharge     = False,
		battlecryType = None,
		battlecryArg  = None
		),
	Card(
		cardID        = 7,
		name          = "Magma Rager",
		rarity        = 0,
		cost          = 3,
		attack        = 5,
		health        = 1,
		hasTaunt      = False,
		hasCharge     = False,
		battlecryType = None,
		battlecryArg  = None
		),
	Card(
		cardID        = 8,
		name          = "Silverback Patriarch",
		rarity        = 0,
		cost          = 3,
		attack        = 1,
		health        = 4,
		hasTaunt      = True,
		hasCharge     = False,
		battlecryType = None,
		battlecryArg  = None
		),
	Card(
		cardID        = 9,
		name          = "Wolfrider",
		rarity        = 0,
		cost          = 3,
		attack        = 3,
		health        = 1,
		hasTaunt      = False,
		hasCharge     = True,
		battlecryType = None,
		battlecryArg  = None
		),
	Card(
		cardID        = 10,
		name          = "Chillwind Yeti",
		rarity        = 0,
		cost          = 4,
		attack        = 4,
		health        = 5,
		hasTaunt      = False,
		hasCharge     = False,
		battlecryType = None,
		battlecryArg  = None
		),
	Card(
		cardID        = 11,
		name          = "Murloc Tidehunter",
		rarity        = 0,
		cost          = 2,
		attack        = 2,
		health        = 1,
		hasTaunt      = False,
		hasCharge     = False,
		battlecryType = "summon",
		battlecryArg  = [12]
		),
	Card(
		cardID        = 12,
		name          = "Murloc Scout",
		rarity        = 0,
		cost          = 0,
		attack        = 1,
		health        = 1,
		hasTaunt      = False,
		hasCharge     = False,
		battlecryType = None,
		battlecryArg  = None
		),
	Card(
		cardID        = 13,
		name          = "Saronite Chain Gang",
		rarity        = 1,
		cost          = 4,
		attack        = 2,
		health        = 3,
		hasTaunt      = True,
		hasCharge     = False,
		battlecryType = "summon",
		battlecryArg  = [13]
		),
	Card(
		cardID        = 14,
		name          = "Epic Fourteen",
		rarity        = 2,
		cost          = 5,
		attack        = 7,
		health        = 7,
		hasTaunt      = False,
		hasCharge     = False,
		battlecryType = None,
		battlecryArg  = None
		),
	Card(
		cardID        = 15,
		name          = "Legendary 15",
		rarity        = 3,
		cost          = 8,
		attack        = 5,
		health        = 5,
		hasTaunt      = True,
		hasCharge     = False,
		battlecryType = "summon",
		battlecryArg  = [16,16,16,16]
		),
	Card(
		cardID        = 16,
		name          = "Army Man",
		rarity        = 0,
		cost          = 0,
		attack        = 2,
		health        = 1,
		hasTaunt      = False,
		hasCharge     = False,
		battlecryType = None,
		battlecryArg  = None
		),
	]

def getCardsByName(names):
	cards = []
	for card in allCards:
		for name in names:
			if card.name == name:
				cards.append(copy.copy(card))
				break
	return cards

def getCardsByID(ids):
	cards = []
	for cardID in ids:
		for card in allCards:
			if card.cardID == cardID:
				cards.append(copy.copy(card))
				break
	return cards