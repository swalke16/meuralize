#!/usr/bin/env ruby

require 'mini_magick'
require 'optparse'
require 'pathname'
require 'tempfile'

class ImageMeuralizer
  TARGET_ASPECT_RATIO = 16.0 / 9.0
  SUPPORTED_FORMATS = %w[.jpg .jpeg .png .bmp .tiff .tif].freeze
  MAX_FILE_SIZE_MB = 20

  def initialize(folder_path)
    @folder_path = Pathname.new(folder_path)
    validate_folder!
  end

  def process_images
    image_files = find_image_files

    if image_files.empty?
      puts "No supported image files found in #{@folder_path}"
      return
    end

    puts "Found #{image_files.length} image(s) to process..."

    image_files.each_with_index do |file_path, index|
      puts "\nProcessing #{index + 1}/#{image_files.length}: #{file_path.basename}"
      process_single_image(file_path)
    end

    puts "\nProcessing complete!"
  end

  private

  def validate_folder!
    unless @folder_path.exist?
      raise "Folder does not exist: #{@folder_path}"
    end

    unless @folder_path.directory?
      raise "Path is not a directory: #{@folder_path}"
    end
  end

  def find_image_files
    @folder_path.glob("*").select do |file|
      file.file? && SUPPORTED_FORMATS.include?(file.extname.downcase)
    end
  end

    def process_single_image(file_path)
    begin
      # Validate file path
      unless file_path && file_path.exist? && file_path.file?
        puts "  ✗ Invalid file path: #{file_path}"
        return
      end

      image = MiniMagick::Image.open(file_path.to_s)

      # Validate image dimensions
      unless image.width && image.height && image.width > 0 && image.height > 0
        puts "  ✗ Invalid image dimensions: #{file_path.basename}"
        return
      end

      current_aspect_ratio = image.width.to_f / image.height.to_f

      if aspect_ratio_close_to_target?(current_aspect_ratio)
        puts "  ✓ Already 16:9 aspect ratio, skipping"
        return
      end

      puts "  → Creating Meural version (aspect ratio: #{current_aspect_ratio.round(2)})"
      create_meural_version(file_path, image)

    rescue => e
      puts "  ✗ Error processing #{file_path&.basename || 'unknown file'}: #{e.message}"
      puts "    Debug: #{e.backtrace&.first}" if ENV['DEBUG']
    end
  end

  def aspect_ratio_close_to_target?(ratio)
    (ratio - TARGET_ASPECT_RATIO).abs < 0.01
  end

  def create_meural_version(original_path, original_image)
    # Calculate target dimensions
    target_width, target_height = calculate_target_dimensions(original_image)

    # Create blurred background
    background = create_blurred_background(original_image, target_width, target_height)

    # Resize original image to fit within target dimensions while maintaining aspect ratio
    foreground = resize_image_to_fit(original_image, target_width, target_height)

    # Composite the images
    result = composite_images(background, foreground, target_width, target_height)

        # Save the result
    output_path = generate_output_path(original_path)
    unless output_path
      puts "  ✗ Could not generate output path"
      return
    end

    result.write(output_path.to_s)

        # Check and reduce file size if needed
    ensure_file_size_limit(output_path, result)

    # Show final file size
    final_size_mb = (File.size(output_path) / 1024.0 / 1024.0).round(1)
    puts "  ✓ Saved: #{output_path.basename} (#{final_size_mb}MB)"
  end

  def calculate_target_dimensions(image)
    # Determine target dimensions based on the larger dimension
    if image.width > image.height
      # Landscape or square - use width as reference
      target_width = [image.width, 1920].max  # Minimum reasonable width
      target_height = (target_width / TARGET_ASPECT_RATIO).round
    else
      # Portrait - use height as reference
      target_height = [image.height, 1080].max  # Minimum reasonable height
      target_width = (target_height * TARGET_ASPECT_RATIO).round
    end

    [target_width, target_height]
  end

  def create_blurred_background(image, target_width, target_height)
    # Create background using image data, not cloning
    background_data = image.to_blob
    background = MiniMagick::Image.read(background_data)

    # Resize to fill the entire target area (this will crop if necessary)
    background.combine_options do |c|
      c.resize "#{target_width}x#{target_height}^"
      c.gravity 'center'
      c.extent "#{target_width}x#{target_height}"
    end

    # Apply strong gaussian blur to make background unrecognizable
    background.blur "0x95"  # radius x sigma - much stronger blur

        # Apply wave distortion for organic, flowing abstraction (without spiral patterns)
    background.wave "4x40"  # amplitude=4, wavelength=40 - creates gentle flowing patterns

    # Apply strong gaussian blur to make background unrecognizable
    background.blur "0x95"  # radius x sigma - much stronger blur

    # Desaturate and darken the background to make it more subtle
    background.modulate "80,90,100"  # brightness=75%, saturation=40%, hue=100%

    background
  end

    def resize_image_to_fit(image, target_width, target_height)
    # Create foreground using image data, not cloning
    foreground_data = image.to_blob
    foreground = MiniMagick::Image.read(foreground_data)

    # Calculate the size to fit within target dimensions
    scale_x = target_width.to_f / image.width
    scale_y = target_height.to_f / image.height
    scale = [scale_x, scale_y].min

    new_width = (image.width * scale).round
    new_height = (image.height * scale).round

    # Resize the image
    foreground.resize "#{new_width}x#{new_height}"

    foreground
  end

  def composite_images(background, foreground, target_width, target_height)
    # Calculate position to center the foreground
    x_offset = (target_width - foreground.width) / 2
    y_offset = (target_height - foreground.height) / 2

    # Use a simpler approach with MiniMagick's page geometry
    result_data = background.to_blob
    result = MiniMagick::Image.read(result_data)

    # Create a temporary file just for the foreground (much safer)
    Dir.mktmpdir do |tmpdir|
      fg_path = File.join(tmpdir, 'fg.png')
      foreground.write(fg_path)

      # Use composite with the temporary file - IMPORTANT: capture the result!
      result = result.composite(MiniMagick::Image.open(fg_path)) do |c|
        c.compose "Over"
        c.geometry "+#{x_offset}+#{y_offset}"
      end
    end

    result
  end

      def generate_output_path(original_path)
    return nil unless original_path

    extension = original_path.extname || ""
    basename = original_path.basename(extension)
    directory = original_path.dirname

    directory + "#{basename}-meural#{extension}"
  end

    def ensure_file_size_limit(file_path, image)
    max_size_bytes = MAX_FILE_SIZE_MB * 1024 * 1024
    min_width = 1920
    min_height = 1080

    # Check current file size
    current_size = File.size(file_path)

    if current_size <= max_size_bytes
      return # File is already within limit
    end

    puts "    → File size #{(current_size / 1024.0 / 1024.0).round(1)}MB exceeds limit, optimizing..."

    # Start with the current image using blob data to avoid cloning issues
    image_data = image.to_blob
    optimized = MiniMagick::Image.read(image_data)

    # Step 1: Try resizing down to minimum 1920x1080 (maintaining 16:9 aspect ratio)
    if optimized.width > min_width || optimized.height > min_height
      # Calculate the scale factor to fit within minimum dimensions
      scale_x = min_width.to_f / optimized.width
      scale_y = min_height.to_f / optimized.height
      scale_factor = [scale_x, scale_y].max  # Use max to ensure we don't go below minimum

      # Only resize if we need to make it smaller
      if scale_factor < 1.0
        new_width = (optimized.width * scale_factor).round
        new_height = (optimized.height * scale_factor).round

        optimized.resize "#{new_width}x#{new_height}"
        optimized.write(file_path.to_s)

        if File.size(file_path) <= max_size_bytes
          puts "    → Reduced to #{(File.size(file_path) / 1024.0 / 1024.0).round(1)}MB by resizing to #{new_width}x#{new_height}"
          return
        end
      end
    end

    # Step 2: Try reducing quality for JPEG files
    if file_path&.extname&.downcase&.match?(/\.jpe?g/)
      # Try quality 85
      optimized.quality "85"
      optimized.write(file_path.to_s)

      if File.size(file_path) <= max_size_bytes
        puts "    → Reduced to #{(File.size(file_path) / 1024.0 / 1024.0).round(1)}MB by adjusting quality to 85%"
        return
      end

      # Try quality 70
      optimized.quality "70"
      optimized.write(file_path.to_s)

      if File.size(file_path) <= max_size_bytes
        puts "    → Reduced to #{(File.size(file_path) / 1024.0 / 1024.0).round(1)}MB by adjusting quality to 70%"
        return
      end

      # Try quality 60 as last resort for quality reduction
      optimized.quality "60"
      optimized.write(file_path.to_s)

      if File.size(file_path) <= max_size_bytes
        puts "    → Reduced to #{(File.size(file_path) / 1024.0 / 1024.0).round(1)}MB by adjusting quality to 60%"
        return
      end
    end

    # Step 3: As last resort, resize below minimum dimensions
    scale_factor = 0.9
    max_attempts = 10
    attempts = 0

    puts "    → As last resort, resizing below minimum dimensions..."

    while File.size(file_path) > max_size_bytes && attempts < max_attempts
      new_width = (optimized.width * scale_factor).round
      new_height = (optimized.height * scale_factor).round

      optimized.resize "#{new_width}x#{new_height}"
      optimized.write(file_path.to_s)

      attempts += 1
    end

    final_size = File.size(file_path)
    if final_size <= max_size_bytes
      puts "    → Reduced to #{(final_size / 1024.0 / 1024.0).round(1)}MB by resizing to #{optimized.width}x#{optimized.height}"
    else
      puts "    → Warning: Could not reduce below #{MAX_FILE_SIZE_MB}MB limit (final: #{(final_size / 1024.0 / 1024.0).round(1)}MB)"
    end
  end
end

# Command line interface
def main
  options = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: ruby meuralize.rb [options] FOLDER_PATH"

    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end

    opts.on("-v", "--version", "Show version") do
      puts "Meuralize v2.0.0 - Professional Gallery Edition"
      exit
    end
  end.parse!

  if ARGV.empty?
    puts "Error: Please provide a folder path"
    puts "Usage: ruby meuralize.rb FOLDER_PATH"
    puts "       ruby meuralize.rb --help for more information"
    exit 1
  end

  folder_path = ARGV[0]

  begin
    meuralizer = ImageMeuralizer.new(folder_path)
    meuralizer.process_images
  rescue => e
    puts "Error: #{e.message}"
    exit 1
  end
end

# Run the script if called directly
if __FILE__ == $0
  main
end