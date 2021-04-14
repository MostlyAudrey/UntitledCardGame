import sys
import os
from classes import *
import test_scenario

def main():
	playGame(test_scenario.player1, test_scenario.player2)

def playGame(player1, player2):
	gameManager = GameManager(player1, player2)
	for player in [player1, player2]:
		player.prepareAndShuffleDeck()
		while len(player.hand) < 3:
			player.attemptDrawCard()
	# Game Loop (one loop = one turn)
	while True: # Start-of-turn events
		gameManager.incrementTurn()
		if gameManager.isPlayer1Turn:
			currPlayer = player1
			opponent = player2
		else:
			currPlayer = player2
			opponent = player1
		while True: # Player choices
			gameManager.updateState()
			printFullGameState(opponent, currPlayer)
			gameManager.updateState()
			choice = makeChoice(currPlayer.name+"\'s turn.\nSelect an action.", ["Play Card", "Attack", "End Turn"])
			if choice == 1:
				printFullGameState(opponent, currPlayer)
				if len(currPlayer.hand) == 0:
					input("You have no cards to play.")
					continue
				if len(currPlayer.board) >= 7:
					input("Your board is full (max: 7 cards).")
					continue
				strPad = getStrPad(currPlayer.hand)
				choice = makeChoice("Which card do you want to play?", [printCardInfo(card, False, strPad) for card in currPlayer.hand]+["Go Back"])
				if choice == len(currPlayer.hand) + 1:
					continue
				cardToPlay = currPlayer.hand[choice-1]
				if cardToPlay.cost > currPlayer.mana:
					input("Not enough mana.")
					continue
				currPlayer.playFromHand(cardToPlay)
			elif choice == 2:
				printFullGameState(opponent, currPlayer)
				if len(currPlayer.board) == 0:
					input("You have no cards to attack with.")
					continue
				strPad = getStrPad(currPlayer.board)
				choice = makeChoice("Which card do you want to attack with?", [printCardInfo(card, True, strPad) for card in currPlayer.board]+["Go Back"])
				if choice == len(currPlayer.board) + 1:
					continue
				attacker = currPlayer.board[choice-1]
				if not attacker.canAttack:
					input("This card cannot attack right now.")
					continue
				printFullGameState(opponent, currPlayer)
				strPad = getStrPad(opponent.board)
				choice = makeChoice(printCardInfo(attacker, True, 0)+"\nWhat do you want to attack?", [printCardInfo(card, False, strPad) for card in opponent.board]+["Opponent", "Go Back"])
				if choice == len(opponent.board) + 2:
					continue
				if choice == len(opponent.board) + 1:
					if opponent.hasTauntOnBoard():
						input("You must attack a Taunt card first.")
						continue
					attacker.performAttack(opponent)
				else:
					defender = opponent.board[choice-1]
					if (not defender.hasTaunt) and opponent.hasTauntOnBoard():
						input("You must attack a Taunt card first.")
						continue
					attacker.performAttack(defender)
			else:
				break


######################
# Specific Utilities #
######################

def getStrPad(cards):
	if len(cards) == 0:
		return 0
	return max([len(card.name) for card in cards])

def printFullGameState(topPlayer, bottomPlayer):
	clearScreen()
	printPlayerStatus(topPlayer, False)
	printBoard(topPlayer, bottomPlayer)
	printPlayerStatus(bottomPlayer, False)
	print("\n")

def printPlayerStatus(player, showAsleepStatus):
	print(player.name)
	print("Health: "+str(player.health))
	print("Mana: "+str(player.mana)+" / "+str(player.maxMana))
	print("Deck: "+str(len(player.deck))+" cards remaining")
	print("Hand:")
	strPad = getStrPad(player.hand)
	for card in player.hand:
		print("    "+printCardInfo(card, showAsleepStatus, strPad))
	print()

def printBoard(topPlayer, bottomPlayer):
	print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	print()
	strPad = getStrPad(topPlayer.board)
	for card in topPlayer.board:
		print("    "+printCardInfo(card, False, strPad))
	print()
	print(" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -")
	print()
	strPad = getStrPad(bottomPlayer.board)
	for card in bottomPlayer.board:
		print("    "+printCardInfo(card, True, strPad))
	print()
	print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
	print()

def printCardInfo(card, showAsleepStatus=True, strPad=0):
	string = "X " if (not card.canAttack) and showAsleepStatus else ""
	string += card.name.ljust(strPad)
	string += " (Cost: "+str(card.cost)
	string += ", Attack: "+str(card.attack)
	string += ", Health: "+str(card.health)
	if card.hasTaunt:
		string += ", Taunt"
	if card.hasCharge:
		string += ", Charge"
	if card.battlecryType is not None:
		string += ", Battlecry: "+str(card.battlecryType)
	string += ")"
	return string

#####################
# General Utilities #
#####################

def clearScreen():
	os.system('clear' if os.name =='posix' else 'cls')

def makeChoice(question, options, allowMultiple=False, validChoicesWarning=True):
	numChoices = len(options)
	if numChoices == 0:
		if validChoicesWarning:
			print("Warning: A question was asked with no valid answers. Returning None.")
		return None
	if numChoices == 1:
		if validChoicesWarning:
			print("A question was asked with only one valid answer. Returning this answer.")
		return 1
	print("\n"+question)
	for i in range(numChoices):
		print(str(i+1)+": "+options[i])
	cInput = input("\n").split(" ")
	if not allowMultiple:
		try:
			assert len(cInput) == 1
			choice = int(cInput[0])
			assert choice > 0 and choice <= numChoices
			return choice
		except:
			print("\nInvalid input.")
			return makeChoice(question, options, allowMultiple)
	else:
		try:
			choices = [int(c) for c in cInput]
			for choice in choices:
				assert choice > 0 and choice <= numChoices
			return choices
		except:
			print("\nInvalid input.")
			return makeChoice(question, options, allowMultiple)

if __name__ == "__main__":
	main()