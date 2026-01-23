# Image Optimization Guide

Complete guide for optimizing images in your Rails application using automated tools and manual methods.

## Table of Contents

- [Quick Start (Automated)](#quick-start-automated)
- [Optimization Results](#optimization-results)
- [Manual Compression Methods](#manual-compression-methods)
- [Usage Scenarios](#usage-scenarios)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)
- [Best Practices](#best-practices)

## Quick Start (Automated)

### 1. Check Current Image Sizes

```bash
# Using Docker
docker compose exec web rails assets:check_images

# Without Docker
rails assets:check_images
```

**Output Example:**

```
🔍 Checking image sizes in app/assets/images...

Current Image Sizes:
--------------------------------------------------------------------------------
✓                  280.49 KB - intent-harvest-logo.webp
⚠️  LARGE          1003.4 KB - oil-palm-background.jpg
⚠️  LARGE          824.49 KB - sidebar-background.png
--------------------------------------------------------------------------------
```

**Status Indicators:**

- `✓` - File size is acceptable (< 500 KB)
- `⚠️  LARGE` - File size is large (500 KB - 1 MB)
- `⚠️  TOO LARGE` - File size is too large (> 1 MB)

### 2. Backup Your Images First!

**⚠️ IMPORTANT**: The optimization task overwrites original files. Always create backups:

```bash
# Create backup of all images
cp -r app/assets/images app/assets/images.backup

# Or backup specific images
cp app/assets/images/oil-palm-background.jpg app/assets/images/oil-palm-background.jpg.backup
```

### 3. Optimize Images

```bash
# Using Docker
docker compose exec web rails assets:optimize_images

# Without Docker
rails assets:optimize_images
```

**Output Example:**

```
🔧 Optimizing images in app/assets/images...

Optimizing images...
--------------------------------------------------------------------------------
✓ intent-harvest-logo.webp
  Before: 315.73 KB → After: 280.49 KB
  Saved: 35.24 KB (11.2%)

✓ oil-palm-background.jpg
  Before: 5809.52 KB → After: 1003.4 KB
  Saved: 4806.12 KB (82.7%)

--------------------------------------------------------------------------------

Total Before: 6.53 MB
Total After:  2.06 MB
Total Saved:  4.48 MB (68.5%)

✅ Image optimization complete!
```

### 4. Verify Results

```bash
docker compose exec web rails assets:check_images
```

## Optimization Results

### Before and After

| Image                    | Before      | After       | Savings     | % Reduction  |
| ------------------------ | ----------- | ----------- | ----------- | ------------ |
| oil-palm-background.jpg  | 5.67 MB     | 1.00 MB     | 4.67 MB     | **82.7%** ✅ |
| sidebar-background.png   | 566 KB      | 824 KB      | -258 KB     | N/A ⚠️       |
| intent-harvest-logo.webp | 316 KB      | 280 KB      | 36 KB       | 11.2% ✅     |
| **TOTAL**                | **6.53 MB** | **2.06 MB** | **4.48 MB** | **68.5%**    |

### Performance Impact

**Before Optimization:**

- Login page first load: **~6.5 MB** (background image alone was 5.7 MB)
- 3G connection: **20-30 seconds** just for images
- 4G connection: **5-8 seconds** for images

**After Optimization:**

- Login page first load: **~2 MB**
- 3G connection: **6-10 seconds** for images
- 4G connection: **2-3 seconds** for images

**Result**: ~68% reduction in total image size! 🎉

### Tools Used

- **`image_processing` gem** (v1.2) - Already in Gemfile
- **libvips backend** - Fast, efficient image processing
- **Rake tasks** in `lib/tasks/image_optimization.rake`:
  - `rails assets:check_images` - Lists all images with size warnings
  - `rails assets:optimize_images` - Compresses all images automatically

### Optimization Settings

**JPEG Compression:**

```ruby
ImageProcessing::Vips
  .source(image_path)
  .saver(quality: 85, strip: true)
```

- Quality: 85% (good balance between size and visual quality)
- Strip: Removes EXIF metadata to reduce file size
- Expected: 70-85% size reduction for large photos

**PNG Compression:**

```ruby
ImageProcessing::Vips
  .source(image_path)
  .saver(compression: 9, strip: true)
```

- Compression: Level 9 (maximum lossless compression)
- Strip: Removes metadata
- Expected: 10-30% size reduction (lossless)

**Note**: Some PNG files may increase in size due to vips encoding. For these cases, use manual compression methods below.

## Manual Compression Methods

### Method 1: Online Tools (Easiest & Best for PNG)

**For JPEG files (oil-palm-background.jpg):**

1. Go to [TinyJPG](https://tinyjpg.com/) or [Squoosh.app](https://squoosh.app/)
2. Upload `oil-palm-background.jpg`
3. Set quality to **80-85%**
4. Download and replace the file
5. **Expected result**: 5.7 MB → ~400-600 KB

**For PNG files (sidebar-background.png, intent-harvest-logo.webp):**

1. Go to [TinyPNG](https://tinypng.com/)
2. Upload the PNG files
3. Download compressed versions
4. Replace the original files
5. **Expected results**:
   - sidebar-background.png: 567 KB → ~200-300 KB
   - intent-harvest-logo.webp: 316 KB → ~50-100 KB

### Method 2: Convert to WebP (Best Compression)

WebP provides 25-35% better compression than JPEG/PNG while maintaining quality.

**Using online tools:**

1. Go to [Squoosh.app](https://squoosh.app/)
2. Upload your image
3. Select **WebP** format
4. Adjust quality slider (80-85 is good)
5. Download and save with `.webp` extension

**Update your Rails views to use WebP:**

```erb
<!-- Before -->
<%= image_tag "intent-harvest-logo.webp", alt: "Intent Harvest Logo", class: "logo" %>

<!-- After (with fallback) -->
<%= image_tag "intent-harvest-logo.webp", alt: "Intent Harvest Logo", class: "logo",
    onerror: "this.onerror=null; this.src='#{asset_path('intent-harvest-logo.webp')}'" %>
```

**For CSS backgrounds:**

```scss
.login-background {
  // Modern browsers (WebP)
  background-image: image-url("oil-palm-background.webp");

  // Fallback for older browsers
  @supports not (background-image: image-url("oil-palm-background.webp")) {
    background-image: image-url("oil-palm-background.jpg");
  }
}
```

### Method 3: Using ImageMagick (Linux/Mac)

```bash
# Install ImageMagick
sudo apt-get install imagemagick  # Ubuntu/Debian
brew install imagemagick          # Mac

# Compress JPEG (oil-palm-background.jpg)
convert oil-palm-background.jpg -quality 85 -strip oil-palm-background-optimized.jpg

# Compress PNG (intent-harvest-logo.webp)
convert intent-harvest-logo.webp -strip -resize 80% intent-harvest-logo-optimized.png

# Convert to WebP
convert oil-palm-background.jpg -quality 85 oil-palm-background.webp
```

**Using Docker (if you don't want to install locally):**

```bash
# Run ImageMagick in Docker container
docker run -v $(pwd)/app/assets/images:/images --rm dpokidov/imagemagick \
  convert /images/oil-palm-background.jpg -quality 85 -strip /images/oil-palm-background-optimized.jpg

docker run -v $(pwd)/app/assets/images:/images --rm dpokidov/imagemagick \
  convert /images/oil-palm-background.jpg -quality 85 /images/oil-palm-background.webp
```

## Usage Scenarios

### Scenario 1: New Project Setup

When starting a new project with images:

```bash
# 1. Add images to app/assets/images/
cp ~/Downloads/*.jpg app/assets/images/

# 2. Check sizes
docker compose exec web rails assets:check_images

# 3. Backup originals
cp -r app/assets/images app/assets/images.backup

# 4. Optimize
docker compose exec web rails assets:optimize_images

# 5. Verify results
docker compose exec web rails assets:check_images
```

### Scenario 2: Adding New Images

When adding new images to an existing project:

```bash
# 1. Add new image
cp ~/Downloads/new-background.jpg app/assets/images/

# 2. Backup just this image
cp app/assets/images/new-background.jpg app/assets/images/new-background.jpg.backup

# 3. Optimize all images (only new one will be compressed)
docker compose exec web rails assets:optimize_images
```

### Scenario 3: Re-optimizing with Different Settings

If you want to try different quality settings:

```bash
# 1. Make sure you have backup
ls app/assets/images.backup/

# 2. Restore originals
cp app/assets/images.backup/* app/assets/images/

# 3. Edit optimization settings in lib/tasks/image_optimization.rake
# Change quality: 85 to quality: 80 (or other value)

# 4. Re-optimize
docker compose exec web rails assets:optimize_images
```

### Scenario 4: Manual Compression for Problem Files

If automated optimization doesn't work well (e.g., PNG gets larger):

```bash
# 1. Restore from backup
cp app/assets/images.backup/sidebar-background.png app/assets/images/

# 2. Use online tool like TinyPNG
# Go to https://tinypng.com/, upload, download compressed version

# 3. Or convert to WebP format for better compression
```

## Troubleshooting

### Problem: PNG Files Get Larger After Optimization

**Why**: Vips PNG encoding may add extra data for certain images.

**Solution**:

1. Restore from backup: `cp app/assets/images.backup/image.png app/assets/images/`
2. Use online tools like [TinyPNG](https://tinypng.com/) for better PNG compression
3. Or convert to WebP format (see Method 2 above)

### Problem: JPEG Quality Too Low

**Why**: Quality 85% might be too aggressive for some images.

**Solution**:

1. Restore from backup
2. Edit `lib/tasks/image_optimization.rake`
3. Change `quality: 85` to `quality: 90`
4. Re-run optimization

### Problem: Task Fails with "LoadError"

**Why**: `image_processing` gem not installed.

**Solution**:

```bash
# Check if gem is in Gemfile
grep image_processing Gemfile

# Install gems
docker compose exec web bundle install
```

### Problem: Optimization Too Slow

**Why**: Large images or many files.

**Solution**:

- Optimize images one at a time manually
- Or run optimization in background
- Consider using faster compression tools (online tools are usually faster)

### Restore from Backup

If you're not satisfied with any optimization results:

```bash
# Restore all images
cp -r app/assets/images.backup/* app/assets/images/

# Or restore specific image
cp app/assets/images/oil-palm-background.jpg.backup app/assets/images/oil-palm-background.jpg
```

## Advanced Usage

### Custom Quality Settings

Edit `lib/tasks/image_optimization.rake` to customize compression:

```ruby
# For higher quality (larger file size)
.saver(quality: 90, strip: true)  # JPEG

# For lower quality (smaller file size)
.saver(quality: 75, strip: true)  # JPEG

# For PNG with different compression
.saver(compression: 6, strip: true)  # Faster but less compression
```

### Optimize Only Specific Images

Modify the task to target specific patterns:

```ruby
# In lib/tasks/image_optimization.rake, change:
images = Dir.glob(Rails.root.join('app', 'assets', 'images', '**', '*.{jpg,jpeg,png}'))

# To only backgrounds:
images = Dir.glob(Rails.root.join('app', 'assets', 'images', '*background*.{jpg,jpeg,png}'))

# Or only logos:
images = Dir.glob(Rails.root.join('app', 'assets', 'images', '*logo*.{png}'))
```

### Convert to WebP Automatically

Add WebP conversion to your rake task:

```ruby
# Add to the optimization task in lib/tasks/image_optimization.rake
if image_path.match?(/\.(jpg|jpeg|png)$/i)
  webp_path = image_path.sub(/\.(jpg|jpeg|png)$/i, '.webp')

  ImageProcessing::Vips
    .source(image_path)
    .convert('webp')
    .saver(quality: 85, strip: true)
    .call(destination: webp_path)

  puts "  Created WebP version: #{File.basename(webp_path)}"
end
```

Then update your views to use WebP with fallback:

```erb
<%= image_tag "oil-palm-background.webp",
              fallback_src: "oil-palm-background.jpg",
              alt: "Background" %>
```

### Automate on Git Pre-commit

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Check for new/modified images
git diff --cached --name-only --diff-filter=ACM | grep -E '\.(jpg|jpeg|png)$'

if [ $? -eq 0 ]; then
  echo "🔍 Detected image changes. Running optimization..."
  docker compose exec web rails assets:optimize_images

  # Stage optimized images
  git add app/assets/images/
fi
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

## Best Practices

### 1. Always Backup Before Optimization

```bash
cp -r app/assets/images app/assets/images.backup
```

### 2. Check Before and After Sizes

```bash
# Before
docker compose exec web rails assets:check_images

# Optimize
docker compose exec web rails assets:optimize_images

# After
docker compose exec web rails assets:check_images
```

### 3. Test Images Visually

After optimization, check images in browser:

- Do backgrounds look good?
- Are logos still crisp?
- Is text readable?

### 4. Target File Size Guidelines

| Image Type               | Recommended Size | Maximum Size |
| ------------------------ | ---------------- | ------------ |
| Background images (JPEG) | 200-500 KB       | 1 MB         |
| Logos (PNG)              | 50-100 KB        | 200 KB       |
| Icons (PNG)              | 10-30 KB         | 50 KB        |
| Photos (JPEG)            | 100-300 KB       | 500 KB       |

### 5. Use Appropriate Formats

- **JPEG**: Photos, backgrounds, complex images without transparency
- **PNG**: Logos, icons, simple graphics with transparency
- **WebP**: Modern format, best compression (use with fallback for older browsers)

### 6. Optimize Early and Often

- Optimize images when you add them, not later
- Run check task regularly: `rails assets:check_images`
- Keep backups of originals in a safe location

### 7. What Gets Optimized

The automated task scans these locations:

```
app/assets/images/**/*.jpg
app/assets/images/**/*.jpeg
app/assets/images/**/*.png
```

All subdirectories are included automatically.

## Additional Tips

### Lazy Loading

Add lazy loading to improve initial page load:

```erb
<%= image_tag "background.jpg", loading: "lazy", alt: "Background" %>
```

### Responsive Images

Serve different sizes for different devices:

```erb
<%= image_tag "background.jpg",
    srcset: "background-mobile.jpg 480w, background-tablet.jpg 768w, background.jpg 1920w",
    sizes: "(max-width: 480px) 480px, (max-width: 768px) 768px, 1920px",
    alt: "Background" %>
```

### CDN Caching

Consider using a CDN for static assets for faster global delivery.

### Cache Headers

Ensure proper caching for images in `config/environments/production.rb`:

```ruby
config.public_file_server.headers = {
  'Cache-Control' => 'public, max-age=31536000'
}
```

## Quick Reference

### Commands

```bash
# Check image sizes
docker compose exec web rails assets:check_images

# Optimize all images
docker compose exec web rails assets:optimize_images

# Check specific file size
docker compose exec web ls -lh app/assets/images/oil-palm-background.jpg

# Create backup
cp -r app/assets/images app/assets/images.backup

# Restore backup
cp -r app/assets/images.backup/* app/assets/images/
```

### Supported File Types

- **JPEG/JPG** - Photos, backgrounds, complex images
- **PNG** - Logos, icons, images with transparency

### When to Use Each Method

- **Automated (rake task)**: Best for JPEGs, bulk optimization, development workflow
- **Online tools (TinyPNG/TinyJPG)**: Best for PNGs, one-off compression, maximum compression
- **WebP conversion**: Best for production, maximum file size reduction (25-35% better)
- **ImageMagick**: Best for batch processing, CI/CD integration, advanced customization

## References

- [Squoosh.app](https://squoosh.app/) - Google's image compression tool
- [TinyPNG](https://tinypng.com/) - PNG compression
- [TinyJPG](https://tinyjpg.com/) - JPEG compression
- [WebP Browser Support](https://caniuse.com/webp) - Check browser compatibility
- [Rails Asset Pipeline](https://guides.rubyonrails.org/asset_pipeline.html)
- [image_processing gem](https://github.com/janko/image_processing)
- [libvips](https://www.libvips.org/)

## Support

If you encounter issues:

1. Check this guide's [Troubleshooting](#troubleshooting) section
2. Verify `image_processing` gem is installed: `bundle list | grep image_processing`
3. Check Docker logs: `docker compose logs web`
4. Restore from backup and try different settings

---

**Last Updated**: November 20, 2025
