
class Player
	# Инициализация
	def initialize
	end
 
	# Метод выполнения шага игры
    def play_turn(warrior)
		turn = WarriorTurn.new(warrior)
		turn.go!
  	end
end

class WarriorTurn < SimpleDelegator

	def go!
		# Пойдем к леснице, если ничего больше не остается
		move_to_stairs! if nothing_there?	
	end

	def nothing_there?
		true
	end

	def move_to_stairs!
		self.walk!(self.direction_of_stairs)
	end
end
  
