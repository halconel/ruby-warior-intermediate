DEBUG = true

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
	class << self; attr_accessor :bond_enemies end
	@bond_enemies = []

	DIRS = [:forward, :backward, :left, :right]

	def initialize(warrior)
		@last_turn_health = 20
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
	def choosen_noise
		noises = self.listen
		choosen_noise = noises[0]
		noises.each {|noise|
			if noise.captive? then choosen_noise = noise end
		}
		choosen_noise
	end

	# Пойдем на шум
	def move_to_that_sound!
		# Определим направление на шум
		choosen_direction = self.direction_of(choosen_noise)

		# Если в этом направлении лестница, то попробуем обойти
		if self.feel(choosen_direction).stairs? then
			DIRS.each { |direction|
				if !self.feel(direction).stairs? && self.feel(direction).empty? then
					self.walk!(direction)
					return nil
				end
			}	
		else 
			self.walk!(choosen_direction)
		end
	end

	# Есть еще враги на уровне
	def still_enemies_there?
		self.listen.each {|noise|
			return true if noise.enemy?
		}
		
		puts "Bond enemies: " + WarriorTurn.bond_enemies.size.to_s if DEBUG

		!WarriorTurn.bond_enemies.empty?
	end

	# Проверяет, что переданная область содержет пленненного врага
	def is_bond_enemy?(direction)
		self.feel(direction).captive? && WarriorTurn.bond_enemies.include?(direction)
	end

	# Освободим пленного
	def rescue_captive!
		done = false
		# Сначала освободим пленных союзников
		DIRS.each { |direction|
			space = self.feel(direction)
			if space.captive? && !is_bond_enemy?(direction) then
				done = true
				self.rescue!(direction)
				break
			end
		}

		# Только потом освобождаем врагов, что бы убить
		if !done then
			DIRS.each { |direction|
				space = self.feel(direction)
				if space.captive? then
					self.rescue!(direction)
					WarriorTurn.bond_enemies.delete(direction) if is_bond_enemy?(direction)
					break
				end
			}
		end
	end
	
	# Посадим врага в клетку
	def bind_enemy!
		DIRS.each { |direction|
			if self.feel(direction).enemy? then
				WarriorTurn.bond_enemies << direction
				self.bind!(direction)
				break
			end
		}
				
	end

	# Перед нами только голые стены и мрак коридоров
	def nothing_there?
		nothing_there = true
		DIRS.each { |direction|
			space = self.feel(direction)
			nothing_there &= (space.empty? || space.wall?)
		}
		nothing_there
	end

	# Рядом есть враг
	def enemy_there?
		enemy_there = false
		DIRS.each { |direction|
			enemy_there ||= self.feel(direction).enemy?
		}
		enemy_there
	end

	# Рядом есть пленный
	def captive_there?
		captive_there = false
		DIRS.each { |direction|
			captive_there ||= self.feel(direction).captive?
		}
		captive_there
	end

	# Мы окружены врагами
	def surounded?
		enemy_count = 0
		DIRS.each { |direction|
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
		DIRS.each { |direction|
			self.attack!(direction) if self.feel(direction).enemy?
		}
	end
	
	# Проверим, что у нас мало здоровья и нас никто не бил на прошлом ходу
	def low_health?
		self.health < 20 && still_enemies_there?
	end
end