# frozen_string_literal: true

require 'optparse'
require 'etc'

MAX_COLUMN = 3

def main
  options = ARGV.getopts('alr')
  options_a = options['a']
  options_l = options['l']
  options_r = options['r']
  items = items(options_a)
  items = sort_items(options_r, items)
  if options_l
    total_f_blocks = calc_item_length(items)
    display_for_l(items, total_f_blocks)
  else
    max_item_string_length = 0
    items.each do |item|
      max_item_string_length = item.to_s.length if max_item_string_length <= item.to_s.length
    end
    window_length = `tput cols`.to_i
    number_of_columns = window_length / (max_item_string_length + 1)
    number_of_columns = MAX_COLUMN if number_of_columns > MAX_COLUMN
    push_empty_elements(items, number_of_columns)
    display_for_general(items, number_of_columns, max_item_string_length)
  end
end

def items(options_a)
  if options_a
    Dir.glob('*', File::FNM_DOTMATCH)
  else
    Dir.glob('*')
  end
end

def sort_items(options_r, items)
  if options_r
    items.reverse
  else
    items
  end
end

def find_file_type(f_type)
  file_type_letters = {
    'directory' => 'd',
    'file' => '-',
    'link' => 'l'
  }
  file_type_letters[f_type]
end

def build_permission(permission_number_ary)
  permission_chars = []
  permission_number_ary.each_slice(3) do |permission_group|
    permission_group.each_with_index do |bit_str, index|
      permission_chars << to_permission_char(bit_str, index)
    end
  end
  permission_chars.join
end

def to_permission_char(bit_str, index)
  if bit_str == '1' && index.zero?
    'r'
  elsif bit_str == '1' && index == 1
    'w'
  elsif bit_str == '1' && index == 2
    'x'
  else
    '-'
  end
end

def f_owner(file_stat)
  owner_uid = file_stat.uid
  Etc.getpwuid(owner_uid).name
end

def f_group(file_stat)
  group_uid = file_stat.gid
  Etc.getgrgid(group_uid).name
end

def push_empty_elements(items, number_of_columns)
  remainder_n = items.length % number_of_columns
  while remainder_n != 0
    items.push('')
    remainder_n = items.length % number_of_columns
  end
end

def print_new_line(transposed_items_ary, this_item_x, number_of_columns)
  transposed_items_ary.each_with_index do |_, i|
    print "\n" if (i % (number_of_columns * this_item_x)).zero?
  end
end

def print_transported_items(transposed_items, this_item_x, this_item_y, max_item_string_length)
  print transposed_items[this_item_x][this_item_y].ljust(max_item_string_length.to_i + 1, ' ')
end

def display_for_l(items, total_f_blocks)
  puts "total #{total_f_blocks}"
  items.each do |item|
    print_items_for_l(item)
  end
end

def print_items_for_l(item)
  file_stat = File.stat(File.absolute_path(item.to_s))
  file_type = find_file_type(file_stat.ftype)
  file_size = file_stat.size
  file_time_mtime = file_stat.mtime
  file_time_mtime = format_mtime(file_time_mtime)
  file_link = file_stat.nlink
  permission_number_ary = (file_stat.mode.to_s(2).to_i % 1_000_000_000).to_s.split('')
  permission = build_permission(permission_number_ary)
  owner = f_owner(file_stat)
  group = f_group(file_stat)
  link_st = file_link.to_s.rjust(2, ' ')
  size_st = file_size.to_s.rjust(8, ' ')
  print "#{file_type}#{permission} #{link_st} #{owner} #{group} #{size_st} #{file_time_mtime} #{item}"
  print "\n"
end

def format_mtime(file_time_mtime)
  file_time_mtime.strftime('%-m  %-d %H:%M')
end

def display_for_general(items, number_of_columns, max_item_string_length)
  number_of_rows = (items.length / number_of_columns.to_i).to_i
  transposed_items = items.each_slice(number_of_rows).to_a.transpose
  this_item_x = 0
  transposed_items_ary = []

  while this_item_x < transposed_items.length
    this_item_y = 0
    while this_item_y < number_of_columns
      print_transported_items(transposed_items, this_item_x, this_item_y, max_item_string_length)
      transposed_items_ary << transposed_items[this_item_x][this_item_y]
      this_item_y += 1
    end
    this_item_x += 1
    print_new_line(transposed_items_ary, this_item_x, number_of_columns)
  end
end

def calc_item_length(items)
  total_f_blocks = 0
  items_length = 0
  items.each do |item|
    file_stat = File.stat(File.absolute_path(item.to_s))
    total_f_blocks += file_stat.blocks
  end
  [items_length, total_f_blocks]
end

main
