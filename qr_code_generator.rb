#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'rqrcode'
require 'chunky_png'

class QRCodeGenerator
  DEFAULT_SIZE = 1200
  DEFAULT_COLOR = '000000'
  DEFAULT_BACKGROUND = 'FFFFFF'
  DEFAULT_LEVEL = :q
  VALID_LEVELS = %i[l m q h].freeze

  def initialize(options)
    @url = options[:url]
    @size = options[:size] || DEFAULT_SIZE
    @color = parse_color(options[:color] || DEFAULT_COLOR)
    @background = parse_color(options[:background] || DEFAULT_BACKGROUND)
    @logo_path = options[:logo]
    @filename = options[:filename]
    @level = parse_level(options[:level])
  end

  def generate
    validate_options!

    qr = RQRCode::QRCode.new(@url, level: @level)
    qr_modules = qr.modules

    module_count = qr_modules.size
    module_size = @size / module_count
    actual_size = module_size * module_count

    png = ChunkyPNG::Image.new(actual_size, actual_size, @background)

    qr_modules.each_with_index do |row, row_index|
      row.each_with_index do |is_dark, col_index|
        if is_dark
          x = col_index * module_size
          y = row_index * module_size
          (0...module_size).each do |dx|
            (0...module_size).each do |dy|
              png[x + dx, y + dy] = @color
            end
          end
        end
      end
    end

    if @logo_path
      png = add_logo(png, actual_size)
    end

    output_filename = generate_output_filename
    png.save(output_filename)
    puts "QR code generated: #{output_filename}"
    puts "Size: #{actual_size}x#{actual_size} pixels"
  end

  private

  def validate_options!
    raise ArgumentError, 'URL is required' if @url.nil? || @url.empty?
    raise ArgumentError, 'Size must be positive' if @size <= 0

    if @logo_path && !File.exist?(@logo_path)
      raise ArgumentError, "Logo file not found: #{@logo_path}"
    end
  end

  def parse_level(level_string)
    return DEFAULT_LEVEL if level_string.nil?

    level = level_string.to_s.downcase.to_sym
    unless VALID_LEVELS.include?(level)
      raise ArgumentError, "Invalid error correction level: #{level_string} (must be one of #{VALID_LEVELS.map { |l| l.to_s.upcase }.join(', ')})"
    end

    level
  end

  def parse_color(color_string)
    hex = color_string.gsub('#', '')
    raise ArgumentError, "Invalid color format: #{color_string}" unless hex.match?(/\A[0-9a-fA-F]{6}\z/)

    r = hex[0..1].to_i(16)
    g = hex[2..3].to_i(16)
    b = hex[4..5].to_i(16)
    ChunkyPNG::Color.rgb(r, g, b)
  end

  def add_logo(png, size)
    logo = ChunkyPNG::Image.from_file(@logo_path)

    # Logo should be about 20% of the QR code size
    max_logo_size = (size * 0.2).to_i
    logo_width = logo.width
    logo_height = logo.height

    # Scale logo if needed
    if logo_width > max_logo_size || logo_height > max_logo_size
      scale = max_logo_size.to_f / [logo_width, logo_height].max
      new_width = (logo_width * scale).to_i
      new_height = (logo_height * scale).to_i
      logo = logo.resample_bilinear(new_width, new_height)
    end

    # Calculate center position
    x_offset = (size - logo.width) / 2
    y_offset = (size - logo.height) / 2

    # Add white background behind logo for better visibility
    padding = 10
    bg_x = x_offset - padding
    bg_y = y_offset - padding
    bg_width = logo.width + (padding * 2)
    bg_height = logo.height + (padding * 2)

    (bg_x...(bg_x + bg_width)).each do |x|
      (bg_y...(bg_y + bg_height)).each do |y|
        png[x, y] = ChunkyPNG::Color::WHITE if x >= 0 && y >= 0 && x < size && y < size
      end
    end

    # Overlay the logo
    png.compose!(logo, x_offset, y_offset)
    png
  end

  def generate_output_filename
    output_dir = File.join(File.dirname(__FILE__), 'generated')
    Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

    if @filename
      name = @filename.end_with?('.png') ? @filename : "#{@filename}.png"
      File.join(output_dir, name)
    else
      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      File.join(output_dir, "qr_code_#{timestamp}.png")
    end
  end
end

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby qr_code_generator.rb --url=URL [options]"

  opts.on('--url=URL', 'URL to encode (required)') do |url|
    options[:url] = url
  end

  opts.on('--size=SIZE', Integer, "Size in pixels (default: #{QRCodeGenerator::DEFAULT_SIZE})") do |size|
    options[:size] = size
  end

  opts.on('--color=COLOR', '--colour=COLOR', "QR code color in hex format (default: #{QRCodeGenerator::DEFAULT_COLOR})") do |color|
    options[:color] = color
  end

  opts.on('--background=COLOR', 'Background color in hex format (default: FFFFFF)') do |color|
    options[:background] = color
  end

  opts.on('--logo=PATH', 'Path to logo image to place in center') do |logo|
    options[:logo] = logo
  end

  opts.on('--level=LEVEL', 'Error correction level: L, M, Q, H (default: H). Lower levels produce fewer/larger modules.') do |level|
    options[:level] = level
  end

  opts.on('--filename=NAME', '-o=NAME', 'Output filename (default: qr_code_TIMESTAMP.png)') do |filename|
    options[:filename] = filename
  end

  opts.on('-h', '--help', 'Show this help message') do
    puts opts
    exit
  end
end.parse!

begin
  generator = QRCodeGenerator.new(options)
  generator.generate
rescue ArgumentError => e
  puts "Error: #{e.message}"
  exit 1
rescue StandardError => e
  puts "Error: #{e.message}"
  puts "Make sure you have installed the required gems:"
  puts "  gem install rqrcode chunky_png"
  exit 1
end
