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
	attr_accessor :binded_enemies

	def initialize(warrior)
		@last_turn_health = 20
		@binded_enemies = []
		super(warrior)
	end

	def go!

		# Если рядом более одного врага, то сажаем их в клетку
		if surounded? then bind_enemy!
	
		# Если рядом что-то есть, то на этом уровне - это враг. В атаку!
		elsif enemy_there? then attack_enemy!  

		# Если мало здоровья, то надо немного отдохнуть от геройств.
		elsif low_health? && !enemy_there? then self.rest!

		# Если рядом пленный, то освободим его.
		elsif captive_there? then rescue_captive!
		
		# Если слышим, что на уровне есть еще хоть что-то, то вперед!	
		elsif heard_something? then move_to_that_sound!
				
		# Пойдем к леснице, если ничего больше не остается.
		else move_to_stairs! end 	

		# Сохраним, сколько у нас осталось здоровья
		last_turn_health = self.health
	end

	# Прислушаемся к шорохам
	def heard_something?
		!self.listen.empty?	
	end

	# Выберем наиболее интересный шорох
	def choose_noise!
		noises = self.listen
		choosen_noise = noises[0]
		noises.each {|noise|
			if noise.captive? then choosen_noise = noise end
		}
		choosen_noise
	end

	# Пойдем на шум
	def move_to_that_sound!
		self.walk!(self.direction_of(choose_noise!))
	end

	# Есть еще враги на уровне
	def still_enemies_there?
		self.listen.each {|noise|
			return true if noise.enemy?
		}
		false
	end

	# Освободим пленного
	def rescue_captive!
		done = false
		# Сначала освободим пленных союзников
		[:forward, :backward, :left, :right].each { |direction|
			if self.feel(direction).captive? && !binded_enemies.include?(direction) then
				done = true
				self.rescue!(direction)
				return nil
			end
		}

		# Только потом освобождаем врагов, что бы убить
		if !done then
		[:forward, :backward, :left, :right].each { |direction|
			if self.feel(direction).captive? then
				self.rescue!(direction)
				binded_enemies.delete(direction)
				return nil
			end
		}
		end
	end
	# Посадим врага в клетку
	def bind_enemy!
		[:forward, :backward, :left, :right].each { |direction|
			if self.feel(direction).enemy? then
				self.bind!(direction)
				binded_enemies << direction
				return nil
			end
		}
				
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

	# Рядом есть враг
	def enemy_there?
		enemy_there = false
		[:forward, :backward, :left, :right].each { |direction|
			enemy_there |= self.feel(direction).enemy?
		}
		enemy_there
	end

	# Рядом есть пленный
	def captive_there?
		captive_there = false
		[:forward, :backward, :left, :right].each { |direction|
			captive_there |= self.feel(direction).captive?
		}
		captive_there
	end

	# Мы окружены врагами
	def surounded?
		enemy_count = 0
		[:forward, :backward, :left, :right].each { |direction|
			enemy_count += 1 if self.feel(direction).enemy?
		}
		enemy_count > 1
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
		self.health < 20 && still_enemies_there?
	end
end
  
