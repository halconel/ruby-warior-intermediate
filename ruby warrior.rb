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

	attr_accessor :last_turn_health

	def initialize(warrior)
		@last_turn_health = 20
		super(warrior)
	end

	def go!

		# Если рядом что-то есть, то на этом уровне - это враг. В атаку!
		attack_enemy! if !nothing_there? 

		# Если мало здоровья, то надо немного отдохнуть от геройств.
		self.rest! if low_health? && nothing_there?

		# Пойдем к леснице, если ничего больше не остается.
		move_to_stairs! if nothing_there? && !low_health?	

		# Сохраним, сколько у нас осталось здоровья
		last_turn_health = self.health
	end

	# Перед нами только голые стены и мрак коридоров
	def nothing_there?
		nothing_there = true
		[:forward, :backward, :left, :right].each { |direction|
			space = self.feel(direction)
			nothing_there &= (space.empty? || space.wall?)
		}
		nothing_there
	end

	# Двигаем по направлению к леснице
	def move_to_stairs!
		self.walk!(self.direction_of_stairs)
	end

	# Атакуем врага, который рядом
	def attack_enemy!
		[:forward, :backward, :left, :right].each { |direction|
			self.attack!(direction) if self.feel(direction).enemy?
		}
	end
	
	# Проверим, что у нас мало здоровья и нас никто не бил на прошлом ходу
	def low_health?
		self.health < 20
	end
end
  
