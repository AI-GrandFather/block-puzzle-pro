# Feature: Theme System & Advanced Visual Effects

**Priority:** HIGH
**Timeline:** Week 1-2
**Dependencies:** Core game engine must be functional
**Performance Target:** 120fps on ProMotion displays (iPhone 15/16/17 Pro), 60fps minimum on all devices

---

## Overview

Implement a comprehensive theme system with 7 distinct visual themes, each with unique aesthetics, animations, and particle effects. The system must support hot-swapping, smooth transitions, and unlockable progression.

---

## Theme System Architecture

### Core Components

1. **ThemeManager (Singleton)**
   - Manages current active theme
   - Handles theme switching with 0.5s cross-fade transition
   - Persists theme selection across app launches
   - Tracks unlock status for each theme
   - Provides theme preview functionality
   - Independent theme settings per game mode (optional)

2. **Theme Protocol**
   ```swift
   protocol Theme {
       var id: String { get }
       var name: String { get }
       var unlockLevel: Int { get }
       var isPremium: Bool { get }

       // Color schemes
       var backgroundColor: LinearGradient { get }
       var gridCellColor: Color { get }
       var gridBorderColor: Color { get }
       var blockColors: [BlockColor] { get }
       var textPrimary: Color { get }
       var textSecondary: Color { get }

       // Visual effects
       var lineClearAnimation: LineClearEffect { get }
       var particleType: ParticleType { get }
       var specialEffects: [SpecialEffect] { get }
   }
   ```

3. **Theme Unlock System**
   - Level-based progression:
     * Level 1: Classic Light (default)
     * Level 5: Dark Mode
     * Level 10: Neon Cyberpunk
     * Level 20: Wooden Classic
     * Level 30: Crystal Ice
     * Level 40: Sunset Beach
     * Level 50: Space Odyssey
   - Premium unlock option: $2.99 for all themes
   - Preview system showing animated sample before unlock

---

## Theme Specifications

### Theme 1: Classic Light (Default)

**Background:**
- Gradient: `#F5F7FA` (top) → `#E8EEF3` (bottom)

**Grid:**
- Empty cells: `#FFFFFF` with inner shadow (0px 2px 4px rgba(0,0,0,0.06))
- Borders: `#D1D9E0`, 1px stroke, 8px rounded corners

**Block Colors (with subtle top highlight at +15% brightness, 2px from top):**
- Red: `#FF6B6B`
- Blue: `#4ECDC4`
- Yellow: `#FFE66D`
- Green: `#95E1D3`
- Purple: `#C3ABE1`
- Orange: `#FFA07A`

**UI Elements:**
- Score display: White `#FFFFFF` with shadow (0px 4px 12px rgba(0,0,0,0.08))
- Text: Primary `#2C3E50`, Secondary `#7F8C8D`
- Buttons: Linear gradient `#007AFF` → `#0051D5`, white text

**Effects:**
- Line clear flash: White `#FFFFFF` pulse at 0.8 opacity

---

### Theme 2: Dark Mode

**Background:**
- Gradient: `#0F0F0F` (top) → `#1A1A1D` (bottom)

**Grid:**
- Empty cells: `#2C2C2E` with soft outer glow (0px 0px 8px rgba(255,255,255,0.03))
- Borders: `#3A3A3C`, 1px stroke, 8px rounded corners

**Block Colors (with neon glow: outer glow 0px 0px 12px at 0.6 opacity):**
- Red: `#FF3B3B` with `#FF3B3B` glow
- Cyan: `#00D9FF` with `#00D9FF` glow
- Yellow: `#FFD93D` with `#FFD93D` glow
- Green: `#6BCF7F` with `#6BCF7F` glow
- Purple: `#B565D8` with `#B565D8` glow
- Orange: `#FF8C42` with `#FF8C42` glow

**UI Elements:**
- Score display: Translucent `#2C2C2E` at 40% opacity, backdrop blur 20px
- Text: Primary `#FFFFFF`, Secondary `#A0A0A0`
- Buttons: Linear gradient `#0A84FF` → `#0066CC`, white text

**Effects:**
- Line clear flash: Electric blue `#00D9FF` pulse with expanding glow
- Cleared line animation: Neon trail dissolving outward
- Grid pulsing: Subtle breathing effect (3s cycle)

---

### Theme 3: Neon Cyberpunk

**Background:**
- Animated gradient: `#0D0221` (top) → `#1B0340` (middle) → `#2D0B5F` (bottom)
- Scanline overlay: 1px lines with 4px gaps at 3% opacity, slowly moving downward

**Grid:**
- Empty cells: `#1A0B2E` with electric purple outline glow (0px 0px 6px `#B026FF` at 0.4 opacity)
- Borders: Bright cyan `#00FFFF`, 2px stroke, 10px rounded corners, pulsing opacity 70%-100% (2s cycle)

**Block Colors (holographic gradients with animated shifting):**
- Pink: Linear gradient 135° `#FF0080` → `#FF8C00`, glow 0px 0px 16px `#FF0080`
- Cyan: Linear gradient 135° `#00F0FF` → `#0080FF`, glow 0px 0px 16px `#00F0FF`
- Purple: Linear gradient 135° `#B026FF` → `#FF00FF`, glow 0px 0px 16px `#B026FF`
- Green: Linear gradient 135° `#00FF88` → `#00FFFF`, glow 0px 0px 16px `#00FF88`
- Yellow: Linear gradient 135° `#FFD700` → `#FF1493`, glow 0px 0px 16px `#FFD700`
- Block edge: Bright 2px border in lighter shade

**UI Elements:**
- Score display: HUD style with `#00FFFF` borders (2px), `#0D0221` background at 80% opacity, corner accent lines (20px)
- Text: Primary `#00FFFF`, Secondary `#B026FF`, both with subtle glow
- Buttons: Animated gradient `#FF0080` → `#8000FF` (3s shifting cycle), white text with shadow

**Special Effects:**
- Line clear: Electric arc particles shooting outward, color-matched
- Grid corner decorations: Cyan triangular brackets
- Background particles: Floating squares drifting upward (cyan/pink, 15% opacity)
- Random grid cell pulses: Cyan glow every 5-8 seconds

---

### Theme 4: Wooden Classic

**Background:**
- Warm gradient: `#E8D5C4` (top) → `#D4B59E` (bottom) with subtle paper texture

**Grid:**
- Base: Oak wood texture `#8B6F47` with visible grain
- Empty cells: Recessed wood with inner shadow (0px 3px 6px rgba(0,0,0,0.3))
- Borders: Dark wood trim `#654321`, 3px stroke, beveled edges

**Block Colors (polished wooden with realistic grain texture overlay):**
- Mahogany: `#704214` with darker grain, glossy top highlight
- Maple: `#D4A76A` with lighter grain, glossy highlight
- Walnut: `#5A3825` with rich brown grain, glossy highlight
- Cedar: `#C9795B` with reddish grain, glossy highlight
- Cherry: `#9A2A2A` with deep red grain, glossy highlight
- Pine: `#E6B87D` with yellowish grain, glossy highlight
- Texture: Directional wood grain at 40% opacity, vignette on edges
- Surface: Top highlight gradient (white at 20% opacity, 30% of block height)

**UI Elements:**
- Score display: Parchment `#F4E8D8` with torn edges, dark brown text
- Text: Primary `#3E2723`, Secondary `#6D4C41`, serif font
- Buttons: Carved wood gradient `#8B6F47` → `#654321`, embossed text

**Effects:**
- Line clear: Wood chips and sawdust particles, dissolve fade
- Wood grain shimmer: Passes across blocks every 10 seconds

---

### Theme 5: Crystal Ice

**Background:**
- Gradient: `#E3F2FD` (top) → `#BBDEFB` (bottom) with diamond pattern overlay at 5% opacity

**Grid:**
- Empty cells: Frosted glass `#F0F8FF` with blur, crystalline border sparkles
- Borders: Ice blue `#81D4FA`, 1px stroke, frosted glass effect, subtle shimmer

**Block Colors (translucent crystalline with internal refraction):**
- Diamond: Gradient `#FFFFFF` → `#E3F2FD`, 60% opacity, strong glow 0px 0px 20px `#FFFFFF`
- Sapphire: Gradient `#2196F3` → `#64B5F6`, 70% opacity, glow 0px 0px 16px `#2196F3`
- Aquamarine: Gradient `#00BCD4` → `#4DD0E1`, 70% opacity, glow 0px 0px 16px `#00BCD4`
- Amethyst: Gradient `#9C27B0` → `#BA68C8`, 70% opacity, glow 0px 0px 16px `#9C27B0`
- Emerald: Gradient `#009688` → `#4DB6AC`, 70% opacity, glow 0px 0px 16px `#009688`
- Topaz: Gradient `#FFC107` → `#FFD54F`, 70% opacity, glow 0px 0px 16px `#FFC107`
- Internal effect: Multiple light rays at random angles, prismatic refraction
- Edges: Bright 2px white highlight on top (80% opacity), darker bottom for depth

**UI Elements:**
- Score display: Ice crystal card, frosted glass, backdrop blur 30px, `#FFFFFF` at 40% opacity, crystalline corners
- Text: Primary `#01579B`, Secondary `#0277BD`, crisp sans-serif
- Buttons: Frozen glass gradient `#42A5F5` → `#1976D2`, frosted overlay, white text

**Effects:**
- Line clear: Ice crystals shattering, sparkling dissipation with prism rays
- Background particles: Gentle snowflakes, various sizes, 20% opacity
- Ice crack patterns: Appear and fade randomly (every 8-12s)
- Light reflection sweep: Across blocks every 6 seconds

---

### Theme 6: Sunset Beach

**Background:**
- Vibrant gradient: `#FF6B9D` (top) → `#FFA07A` (middle) → `#FFE66D` (bottom)
- Sky overlay: Cloud patterns in `#FFB6C1` at 30% opacity, slowly drifting

**Grid:**
- Empty cells: Warm sand texture `#FFE4B5` with subtle grain
- Borders: Turquoise ocean `#20B2AA`, 2px stroke, wave pattern, gentle flowing animation

**Block Colors (beach-themed radial gradients with warm/cool glows):**
- Coral: Radial `#FF7F50` (center) → `#FF6347` (edge), glow 0px 0px 12px `#FF7F50`
- Ocean: Radial `#1E90FF` (center) → `#4169E1` (edge), glow 0px 0px 12px `#1E90FF`
- Palm: Radial `#32CD32` (center) → `#228B22` (edge), glow 0px 0px 12px `#32CD32`
- Sunrise: Radial `#FFD700` (center) → `#FFA500` (edge), glow 0px 0px 14px `#FFD700`
- Sunset: Radial `#FF1493` (center) → `#FF69B4` (edge), glow 0px 0px 12px `#FF1493`
- Sand: Radial `#F4A460` (center) → `#D2691E` (edge), glow 0px 0px 10px `#F4A460`
- Surface: Glossy wet appearance with top highlight (white at 30% opacity)

**UI Elements:**
- Score display: Beach hut style, bamboo border, warm `#FFF8DC` at 85% opacity
- Text: Primary `#8B4513`, Secondary `#CD853F`, casual playful font
- Buttons: Wave pattern gradient `#00CED1` → `#20B2AA`, white text with shadow

**Effects:**
- Line clear: Water splash particles with droplets, tropical flower petals floating up
- Background: Seagulls flying across occasionally, palm tree shadows on sides
- Ocean waves: Bottom grid has animated waves lapping (continuous subtle motion)
- Sun rays: Beams casting from top corner, lens flare on score, water sparkles on block movement

---

### Theme 7: Space Odyssey (Premium)

**Background:**
- Deep space gradient: `#000000` (edges) → `#0A0A2E` (center)
- Starfield: Thousands of white/blue/yellow dots, various sizes, subtle twinkling, parallax depth layers

**Grid:**
- Empty cells: Dark matter `#0D0D1F` with faint purple nebula glow (0px 0px 10px `#4B0082` at 0.2 opacity)
- Borders: Electric plasma `#00FFFF`, 1px stroke, energy flow animation along edges

**Block Colors (cosmic gems with galaxy textures):**
- Nova Red: Red/orange galaxy texture, supernova glow 0px 0px 18px `#FF0000`
- Nebula Blue: Swirling blue/purple gas clouds, stellar glow 0px 0px 18px `#4169E1`
- Pulsar Green: Radiating green energy waves, radiation glow 0px 0px 18px `#00FF00`
- Solar Yellow: Burning sun surface, solar flare glow 0px 0px 20px `#FFD700`
- Cosmic Purple: Purple nebula clouds, mystery glow 0px 0px 16px `#8A2BE2`
- Meteor Gray: Asteroid surface with craters, space rock glow 0px 0px 12px `#696969`
- Edges: Glowing plasma outline (2px) at higher brightness

**UI Elements:**
- Score display: Futuristic hologram, `#00FFFF` borders with corner brackets, dark translucent center
- Text: Primary `#00FFFF`, Secondary `#FF00FF`, sci-fi geometric font
- Buttons: Animated galaxy swirl gradient `#4B0082` → `#8A2BE2`, glowing white text

**Effects:**
- Line clear: Supernova explosion with expanding ring, stardust dispersion
- Background: Distant planets rotating slowly, asteroid belt drifting
- Shooting stars: Streak across every 8-15 seconds
- Cosmic rays: From cleared lines

---

## Advanced Visual Effects

### 1. Line Clear Animations

**Flash Effect:**
- Theme-appropriate color pulse
- Expanding glow from center
- Duration: 0.3 seconds

**Particle Burst System:**
- 50-100 particles per line clear
- Particle types per theme:
  * Classic/Dark: Sparkles
  * Cyberpunk: Electric sparks
  * Wooden: Wood chips
  * Ice: Ice crystals
  * Beach: Water droplets
  * Space: Stardust
- Particles emit from cleared cells, expand outward
- Fade out over 0.5 seconds
- Object pooling for performance

### 2. Block Cascade Physics

**Animation:**
- Smooth falling animation with ease-out easing
- Duration: 0.3 seconds per cell drop
- Slight bounce on landing (0.1s duration)
- Cascade happens sequentially, not all at once

**Physics:**
- Gravity simulation for natural feel
- Acceleration: 9.8 units/s² virtual gravity
- Terminal velocity cap

### 3. Combo Celebration Animations

**Intensity Scaling:**
- 2x combo: Small burst (30 particles, 0.4s)
- 5x combo: Medium explosion (80 particles, 0.7s)
- 10x+ combo: Screen-wide celebration (200 particles, 1.2s)

**Visual Elements:**
- Combo multiplier number scales up dramatically
- Screen shake intensity increases with combo
- Color intensity and brightness increase
- Sound builds in intensity

### 4. Perfect Clear Animation

**Full-Screen Effect (2 seconds):**
- Theme-specific:
  * Classic: Rainbow wave across screen
  * Dark: Electric surge
  * Cyberpunk: Digital matrix cascade
  * Wooden: Explosion of wood shavings
  * Ice: Ice storm with prism effect
  * Beach: Tidal wave washing over
  * Space: Supernova with gravitational wave

**Sequence:**
1. All remaining blocks light up (0.2s)
2. Special effect triggers from center (0.5s)
3. Blocks dissolve with effect (0.8s)
4. Score multiplier appears with fanfare (0.5s)

### 5. Additional Effects

**Block Placement Ripple:**
- Circular wave expanding from placement point
- Duration: 0.4 seconds
- Fades from 1.0 to 0.0 opacity
- Color matches placed block

**Score Number Animations:**
- Numbers fly upward from action location
- Scale up 1.0x → 1.5x → 1.0x
- Color-coded by point value:
  * 0-100: White
  * 100-500: Yellow
  * 500-1000: Orange
  * 1000+: Gold with glow
- Fade out at top of arc (0.6s total duration)

**Streak Indicators:**
- Visual flame/energy trail on consecutive placements
- Builds up progressively
- Dissipates after 3 seconds of no action

---

## Enhanced UI Components

### Score Display

**Animated Counter:**
- Rolling digits effect (0→final value over 0.3s)
- High score ghost indicator: Previous best shown faded above current score at 40% opacity
- Real-time updates with smooth transitions

**Design:**
- Theme-appropriate card background
- Drop shadow or glow depending on theme
- Large, readable font
- Prominent placement (top of screen)

### Mode Indicator

**Badge Display:**
- Clear designation at top
- Mode-specific icon
- Color-coded:
  * Endless: Blue
  * Timed: Orange
  * Levels: Green
  * Puzzle: Purple
  * Zen: Lavender

### Combo Counter

**Visual Design:**
- Builds up size with each consecutive clear
- Shows multiplier prominently (e.g., "5x COMBO!")
- Pulses with each increment
- Resets with smooth shrink animation

**Placement:**
- Floats above grid during combo
- Semi-transparent background
- Large, bold typography

### Piece Tray

**3 Slots:**
- Subtle pulsing border when pieces available (1.5s cycle, opacity 60%→100%)
- Empty state shows outline only with dashed border
- Smooth piece generation animation (fade in + scale 0.8x → 1.0x over 0.3s)

**Interaction:**
- Touch to pick up piece
- Visual lift effect (scale 1.05x, raise 8px)
- Shadow increases during lift

### Hold Slot

**Design:**
- Clear visual designation separate from piece tray
- Icon indicating "Hold" functionality
- Smooth swap animation (0.3s rotation: active piece rotates out 180°, held piece rotates in)
- Cooldown indicator if limited (circular progress overlay)

### Power-Up Bar

**Icons:**
- Each power-up has distinct icon
- Count/cooldown overlay
- Pulse animation when available
- Grayscale when unavailable
- Tap to activate

---

## ProMotion & Performance Optimization

### 120Hz Display Support

**Implementation:**
- Detect ProMotion capability: `UIScreen.main.maximumFramesPerSecond`
- Adaptive frame rate: 60-120fps range
- Metal rendering loop at maximum supported refresh rate
- CADisplayLink for smooth animation timing

**Frame Rate Management:**
- 120fps: iPhone 15/16/17 Pro, iPad Pro (2021+)
- 60fps: All other devices
- Battery saver: Drop to 60fps
- Background: 30fps or paused

### Particle System Optimization

**Object Pooling:**
- Pre-allocate particle object pool (500 particles)
- Reuse instead of create/destroy
- Reset particle state on reuse
- Automatic pool expansion if needed (rare)

**Rendering:**
- Batch particle rendering
- Single draw call per particle type
- Instanced rendering for identical particles
- Early culling of off-screen particles

### Texture Atlasing

**Implementation:**
- Single 2048x2048 texture atlas containing all block graphics
- All color variations, highlights, effects in one texture
- Reduces texture swaps (major performance gain)
- Smaller memory footprint

**Atlas Organization:**
- Base blocks: 256x256 each
- Effects and overlays: 128x128
- UI elements: Various sizes
- Mipmaps for quality at different scales

### Asset Loading

**Lazy Loading:**
- Load only active theme assets
- Unload previous theme when switching
- Background preload when browsing themes (anticipatory loading)

**Memory Management:**
- Monitor memory warnings
- Automatic cleanup of unused assets
- Compress textures when possible (PVRTC, ASTC)
- Use iOS automatic resource management

### Render Optimization

**Smart Redrawing:**
- Only redraw changed grid cells
- Dirty region tracking
- Background layer caching (static elements)
- Separate render layers for grid, pieces, effects

**GPU Acceleration:**
- Metal 3 for all rendering
- Shader compilation caching
- Efficient blend modes
- Hardware-accelerated gradients and effects

---

## Implementation Checklist

- [ ] Create ThemeManager singleton with protocol
- [ ] Implement all 7 theme specifications
- [ ] Build theme switching with 0.5s cross-fade
- [ ] Implement unlock progression system
- [ ] Create theme preview functionality
- [ ] Build particle system with object pooling
- [ ] Implement line clear animations per theme
- [ ] Create cascade physics system
- [ ] Build combo celebration scaling
- [ ] Implement perfect clear animations
- [ ] Create block placement ripple effect
- [ ] Build score number animations
- [ ] Implement streak indicators
- [ ] Design and implement enhanced UI components
- [ ] Set up ProMotion 120fps support
- [ ] Implement texture atlasing
- [ ] Build lazy loading system for themes
- [ ] Optimize rendering pipeline
- [ ] Performance test on all target devices
- [ ] Verify 120fps on ProMotion displays
- [ ] Verify 60fps minimum on standard displays

---

## Success Criteria

✅ All 7 themes implemented with exact specifications
✅ Theme switching works smoothly with 0.5s transition
✅ Unlock progression system functional
✅ Theme preview shows animated sample
✅ Particle effects render correctly for all themes
✅ Line clear animations are theme-appropriate
✅ Cascade physics feel natural and responsive
✅ Combo celebrations scale appropriately
✅ Perfect clear animation is impressive
✅ 120fps achieved on ProMotion displays
✅ 60fps minimum on all supported devices
✅ Memory usage under 150MB during gameplay
✅ No frame drops or stuttering
✅ All UI components animate smoothly
✅ Theme assets load efficiently
