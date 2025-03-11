# BaseState.gd
extends Node

class_name BaseState

# Function to handle entering the state
func enter(_character):
	pass

# Function to handle exiting the state
func exit(_character):
	pass

# Function to update the state
func update(_character, _delta):
	pass

# Function to handle input in the state
func handle_input(_character):
	pass
