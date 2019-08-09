class Chromosome
  attr_accessor :data, :rank, :dist
  attr_reader :size
  def initialize
    @size = 5
    @max = 20
    @data = Array.new
    @size.times {@data << (rand(20) - 10)}
    @rank = 0
    @dist = 0
  end
  def to_s
    @data.join(',')
  end
  def mutate!
    @data.collect! do |v|
      if rand(100) > 50
        rand(@max) - 10
      else
        v
      end
    end
  end
  def reproduce_with(aChromosome)
    son = Chromosome.new
    @size.times do |i|
      if rand(100) > 50
        son.data[i] = @data[i]
      else
        son.data[i] = aChromosome.data[i]
      end
    end
    son
  end
  def objectiveOne
    result = 0.0
    @data.each {|v| result += (v**2)}
    result
  end
  def objectiveTwo
    result = 0.0
    @data.each {|v| result += ((v - 2)**2)}
    result
  end
end

class NSGA
  def initialize(generations, population_size)
    @generations = generations
    @population_size = population_size
  end

  def run
    @pop = Array.new(@population_size) {Chromosome.new}
    @generations.times do
      compute_rank
      compute_distance
      mating_pool = Array.new(@population_size) {better(@pop[rand(@pop.size)], @pop[rand(@pop.size)])}
      @pop += reproduce(mating_pool)
      compute_rank
      compute_distance
      reduce_population # Todo: should sort by rank / dist first. Shouldn't we?
      puts "---------------------"
      @pop.each do |c|
        puts c
        puts "(#{c.objectiveOne},#{c.objectiveTwo})"
      end
    end
  end

  def reproduce(pop)
    children = Array.new
    @population_size.times do
      dad = pop.sample
      mom = pop.sample
      son = dad.reproduce_with(mom)
      son.mutate!
      children << son
    end
    children
  end

  def better(dad, mom)
    if dad.rank == mom.rank
      return (dad.dist > mom.dist) ? dad : mom
    end
    return (dad.rank < mom.rank) ? dad : mom
  end

  def reduce_population
    @pop = @pop.first(@population_size)
  end

  def compute_rank
    @fronts = Array.new
    @pop.each {|c| c.rank = 0}
    @pop.sort! {|x,y| x.objectiveOne <=> y.objectiveOne}
    rank = 0
    done = false
    while not done do
      rank += 1
      min = 1.0 / 0.0
      done = true
      @pop.each do |c|
        if c.rank == 0
          done = false
          if c.objectiveTwo < min
            min = c.objectiveTwo
            c.rank = rank
            @fronts[rank - 1] ||= Array.new
            @fronts[rank - 1] << c
          end
        end
      end
    end
  end

  def compute_distance
    total = 0
    @fronts.each do |f|
      if total < @population_size
        f.sort! {|x,y| x.objectiveOne <=> y.objectiveOne}
        f[1...(f.size)].each_index do |i|
          f[i].dist = f[i+1].objectiveOne - f[i-1].objectiveOne
        end
        f.first.dist = 1.0 / 0.0
        f.last.dist = 1.0 / 0.0
        f.sort! {|x,y| x.objectiveTwo <=> y.objectiveTwo}
        f[1...(f.size)].each_index do |i|
          f[i].dist += f[i+1].objectiveTwo - f[i-1].objectiveTwo if f[i].dist < 1.0 / 0.0
        end
        f.first.dist = 1.0 / 0.0
        f.last.dist = 1.0 / 0.0
      end
      total += f.size
    end
  end
end

ns = NSGA.new(100, 300)
ns.run
