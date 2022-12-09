#!/usr/bin/env ruby
require "curses"

class Tree
  attr_accessor :height, :levels, :coord_x, :coord_y

  def initialize
    @height = 0
    @levels = []

    # Coordonnées de la base de l'arbre
    @coord_x = 0
    @coord_y = 0
  end

  def grow
    case @height
    when 0
      levels.push("|")
    when 1
      levels[0] += "|"
      levels.push("/\\")
    when 2
      levels.insert(1, balanced_level(2))
    else
      previous_leaf_count = levels[1].size / 2
      new_leaf_count = previous_leaf_count + rand(0..1)
      levels.insert(1, balanced_level(new_leaf_count))
    end
    @height += 1
  end

  def balanced_level(number)
    "/" * number + "\\" * number
  end

  def coordinates
  end

  # Returns an array of lines start coordinates
  def lines_coordinates
    levels.each_with_index.map do |level, level_index|
      [coord_x - levels.sized / 2, coord_y + height - level_index]
    end
  end

  def to_s
    width = levels[1].size
    levels.reverse.map { _1.center(width, " ") }.join("\n")
  end
end

class Forest
  EMPTY_SPOT = " "

  attr_accessor :inhabitants, :columns, :rows, :border

  # border is unsed with curses to allow for border around the window
  def initialize(cols:, rows:, border: 0)
    @inhabitants = []
    @columns = cols - border * 2
    @rows = rows - border * 2
    @border = border
  end

  def place(tree:, x:, y:)
    return unless (0..columns).cover?(x) && (0..rows).cover?(y)
    tree.coord_x, tree.coord_y = x, y
    # z_index = z_index(tree)

    @inhabitants.push(tree)
  end

  def add_random_tree
    size = rand(0..4)
    x = rand(0..columns)
    y = rand(0..rows)
    tree = Tree.new
    size.times { tree.grow }
    place(tree: tree, x: x, y: y)
  end

  # Helper to debug. Add 1 tree of size 0 in the middle
  def add_middle_tree
    place(tree: Tree.new, x: columns / 2, y: rows / 2)
  end

  def z_index(tree)
    tree.coord_y * columns + tree.coord_x
  end

  def grow
    inhabitants.each(&:grow)

    # Natural forest gain/loose trees while growing
    # add_random_tree if rand(10) < 3
    # remove_random_trees if rand(10) < 3
  end

  def remove_random_trees
    inhabitants.reject! do |tree|
      tree.height > 3 && tree.height > rand(20)
    end
  end

  def to_s
    # Crée un buffer remplis d'espaces. Array
    @screen = (0..rows).map { EMPTY_SPOT * columns }
    inhabitants.sort_by!(&method(:z_index)).each do |tree|
      tree.levels.reverse.each_with_index do |level, height|
        level_x = tree.coord_x - level.size / 2
        level_y = height + tree.coord_y - tree.height
        level_size = [columns - level_x, level.size].min
        if (0..columns).cover?(level_x) && (0..rows).cover?(level_y)
          @screen[level_y][level_x, level.size] = level.slice(0, level_size)
        end
      end
    end

    sep = "-" * (columns + 1)
    @screen.push sep
    @screen.unshift sep

    @screen.join("|\n|")
  end

  def print_to_curse_window(window)
    inhabitants.sort_by!(&method(:z_index)).each do |tree|
      tree.levels.reverse.each_with_index do |level, height|
        level_y = border + height + tree.coord_y - tree.height
        next unless (border..rows).cover?(level_y)

        raw_level_x = tree.coord_x - level.size / 2
        if raw_level_x < 0
          # Start before window
          level_string = level.slice(-raw_level_x, columns)
          level_x = border
        else
          # start inside window
          level_x = raw_level_x + border
          max_size = columns - level_x
          level_string = level.slice(0, max_size)
        end

        window.setpos(level_y, level_x)
        window.addstr(level_string)
      end
    end

    window.refresh
  end
end

def main_print
  forest = Forest.new(cols: 80, rows: 40)
  forest.add_middle_tree

  10.times do
    puts forest.to_s
    forest.grow
    sleep(1)
  end
end

HELP = "q: quit, g/enter/space: grow once, a: add trees, r: remove trees, s: stop animation, l: resume animation"

def main_curse
  Curses.start_color # Initializes the color attributes for terminals that support it.
  Curses.curs_set(0) # Hides the cursor
  Curses.noecho # Disables characters typed by the user to be echoed by Curses.getch as they are typed.
  Curses.init_pair(1, 2, 0)

  begin
    size = {lines: Curses.lines - 20, cols: Curses.cols - 20}
    window = Curses::Window.new(size[:lines], size[:cols], 10, 10)

    help_window = Curses::Window.new(1, Curses.cols - 11, Curses.lines - 5, 11)
    help_window.addstr(HELP)
    help_window.refresh

    # Act every 300 ms
    window.timeout = 300

    forest = Forest.new(cols: size[:cols], rows: size[:lines], border: 1)
    5.times { forest.add_random_tree }

    # To test basic usage, start with just a single tree
    # forest.add_middle_tree
    # 3.times { forest.grow } # To have a basic initial tree.

    forest_event_loop(window, forest)
  ensure
    Curses.close_screen
  end
end

def forest_event_loop(window, forest)
  frame = 0
  loop do
    window.clear
    window.box("|", "-") # necessary after clear
    forest.print_to_curse_window(window)
    window.noutrefresh

    # window.timeout=300
    str = window.getch.to_s # Reads and returns a character
    case str
    when " " || "g" || "10"
      forest.grow
    when "r"
      forest.remove_random_trees
    when "a"
      forest.add_random_tree
    when "q"
      exit 0
    when "s"
      window.timeout = -1
    when "l"
      window.timeout = 300
    when "" # timeout
      frame += 1
      forest.grow if 5 < rand(10)
      forest.remove_random_trees if frame % 30 == 0
      forest.add_random_tree if frame % 6 == 0
    end
  end
end

# main_print
main_curse
