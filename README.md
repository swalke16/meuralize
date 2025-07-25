# Meuralize - Image Aspect Ratio Converter

A Ruby script that processes images to create 16:9 aspect ratio versions suitable for Meural digital frames.

## What it does

For each image in a given folder, the script:

1. **Checks the aspect ratio** - Determines if the image is already 16:9
2. **Skips if already correct** - Leaves 16:9 images unchanged
3. **Creates Meural version** - For non-16:9 images, generates a new file with:
   - Original filename + "-meural" suffix (e.g., `photo.jpg` → `photo-meural.jpg`)
   - 16:9 aspect ratio canvas
   - Blurred background using the original image
   - Original image centered and properly scaled on top

## Prerequisites

- Ruby (version 2.7 or higher recommended)
- ImageMagick installed on your system
- Bundler gem

### Installing ImageMagick

**macOS (with Homebrew):**
```bash
brew install imagemagick
```

**Ubuntu/Debian:**
```bash
sudo apt-get install imagemagick
```

**Windows:**
Download from [ImageMagick official site](https://imagemagick.org/script/download.php#windows)

## Installation

1. Clone or download this repository
2. Install dependencies:
   ```bash
   bundle install
   ```

## Usage

### Basic Usage
```bash
ruby meuralize.rb /path/to/your/image/folder
```

### Examples
```bash
# Process images in current directory
ruby meuralize.rb .

# Process images in a specific folder
ruby meuralize.rb ~/Pictures/vacation-photos

# Get help
ruby meuralize.rb --help

# Check version
ruby meuralize.rb --version
```

## Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- BMP (.bmp)
- TIFF (.tiff, .tif)

## How It Works

1. **Aspect Ratio Detection**: Calculates width/height ratio and compares to 16:9 (≈1.78)
2. **Smart Sizing**: Determines optimal canvas size based on original image dimensions
3. **Background Creation**:
   - Resizes original image to fill 16:9 canvas (with cropping if needed)
   - Applies Gaussian blur for aesthetic background
4. **Foreground Placement**:
   - Scales original image to fit within canvas while maintaining aspect ratio
   - Centers the image on the blurred background
5. **File Output**: Saves with "-meural" suffix, preserving original format

## Example Output

**Input:** `sunset.jpg` (4:3 aspect ratio, 2000x1500)
**Output:** `sunset-meural.jpg` (16:9 aspect ratio, 2000x1125)

The original 4:3 image becomes a 16:9 image with:
- A blurred version of the sunset as background
- The original sharp sunset image centered on top
- No distortion or stretching

## Performance Notes

- Processing time depends on image size and quantity
- Large images (>4K) may take longer to process
- The script processes images sequentially for memory efficiency
- Original files are never modified

## Error Handling

The script handles common issues gracefully:
- Invalid folder paths
- Corrupted image files
- Unsupported formats
- Write permission errors

Failed images are reported but don't stop the batch process.

## License

MIT License - Feel free to modify and distribute as needed.