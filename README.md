# Meuralize - Professional Image Aspect Ratio Converter

A Ruby script that processes images to create stunning 16:9 aspect ratio versions suitable for Meural digital frames and gallery displays.

## What it does

For each image in a given folder, the script:

1. **Checks the aspect ratio** - Determines if the image is already 16:9
2. **Skips if already correct** - Leaves 16:9 images unchanged
3. **Creates Meural version** - For non-16:9 images, generates a new file with:
   - Original filename + "-meural" suffix (e.g., `photo.jpg` → `photo-meural.jpg`)
   - Perfect 16:9 aspect ratio canvas
   - Sophisticated abstract background using advanced image processing
   - Original image centered and properly scaled on top
   - File size optimized to stay under 20MB

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
2. **Smart Canvas Sizing**: Determines optimal canvas size based on original image dimensions
3. **Advanced Background Creation**:
   - Resizes original image to fill 16:9 canvas (with intelligent cropping)
   - Applies heavy Gaussian blur (sigma 95) to make content completely unrecognizable
   - Adds wave distortion for organic, flowing patterns
   - Applies second blur to smooth and refine the abstract patterns
   - Desaturates and darkens colors for sophisticated, gallery-quality appearance
4. **Foreground Processing**:
   - Scales original image to fit within canvas while maintaining perfect aspect ratio
   - Centers the sharp image over the abstract background
5. **File Size Optimization**:
   - Maintains minimum 1920x1080 resolution when possible
   - Reduces JPEG quality only if necessary to stay under 20MB
   - Uses intelligent scaling as last resort
6. **File Output**: Saves with "-meural" suffix, preserving original format and showing final file size

## Example Output

**Input:** `sunset.jpg` (4:3 aspect ratio, 2000x1500)
**Output:** `sunset-meural.jpg` (16:9 aspect ratio, 2000x1125, 15.2MB)

The original 4:3 image becomes a stunning 16:9 gallery piece with:
- A completely abstract, flowing background derived from the original colors
- Heavy blur and wave distortion making the background totally unrecognizable
- Sophisticated color grading (desaturated and darkened for elegance)
- The original sharp sunset image perfectly centered on top
- No distortion or stretching of the original image
- Professional file size optimization

## Performance Notes

- Processing time depends on image size and quantity (advanced effects take more time)
- Large images (>4K) may take longer due to multiple blur and distortion passes
- The script processes images sequentially for memory efficiency
- Original files are never modified
- File size optimization happens automatically - larger source images may require additional processing
- Memory usage is optimized to avoid MiniMagick cleanup issues

## Error Handling

The script handles common issues gracefully:
- Invalid folder paths and missing files
- Corrupted or unreadable image files
- Unsupported formats
- Write permission errors
- ImageMagick compatibility issues
- File size optimization failures

Advanced error handling includes:
- Input validation for file paths and image dimensions
- Safe navigation to prevent nil method errors
- Detailed error reporting with optional debug mode
- Automatic cleanup of temporary files
- Graceful degradation when optimization limits are reached

Failed images are reported but don't stop the batch process.

## File Size Optimization

The script automatically ensures all output files stay under 20MB using a smart optimization strategy:

### Three-Step Optimization Process:

1. **Intelligent Resizing** (Priority: Maintain Quality)
   - Only resizes if larger than 1920x1080 minimum
   - Preserves aspect ratio and image quality
   - Ideal for Meural display resolution

2. **Quality Adjustment** (JPEG files only)
   - Reduces compression quality: 85% → 70% → 60%
   - Maintains visual quality while reducing file size
   - PNG and other formats skip to step 3 if needed

3. **Below-Minimum Resizing** (Last Resort)
   - Only if steps 1-2 don't achieve 20MB target
   - Iterative scaling with clear user notification
   - Preserves aspect ratio throughout

### Example Optimization Output:
```
Processing large-photo.jpg
  → File size 45.2MB exceeds limit, optimizing...
  → Reduced to 18.7MB by resizing to 1920x1080
  ✓ Saved: large-photo-meural.jpg (18.7MB)
```

## License

MIT License - Feel free to modify and distribute as needed.