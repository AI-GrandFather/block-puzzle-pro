# Feature: Performance Optimization

**Priority:** CRITICAL
**Timeline:** Ongoing (Week 13+)
**Dependencies:** All systems

---

## Performance Targets

### Frame Rate
- **120fps:** ProMotion devices (iPhone 15/16/17 Pro, iPad Pro)
- **60fps minimum:** All supported devices
- **Battery Saver:** 60fps when low power mode active
- **No frame drops:** During gameplay, animations, transitions

### Memory
- **Active Gameplay:** <150MB
- **Background:** <50MB
- **Peak Usage:** <200MB
- **No memory leaks:** Verified with Instruments

### Load Times
- **Cold Launch:** <2 seconds to main menu
- **Warm Launch:** <1 second
- **Mode Transition:** <0.3 seconds
- **Game Start:** <0.5 seconds
- **Theme Switch:** <0.5 seconds

### Battery
- **Target:** <5% drain per hour of gameplay
- **Respect Low Power Mode:** Reduce animations, lower frame rate

---

## ProMotion 120Hz Implementation

```swift
class DisplayManager {
    var maximumFramesPerSecond: Int {
        return UIScreen.main.maximumFramesPerSecond
    }

    func configureDisplayLink() -> CADisplayLink {
        let displayLink = CADisplayLink(target: self, selector: #selector(update))

        if maximumFramesPerSecond == 120 {
            displayLink.preferredFramesPerSecond = 120
        } else {
            displayLink.preferredFramesPerSecond = 60
        }

        return displayLink
    }

    @objc func update() {
        // Render at maximum supported refresh rate
    }
}
```

---

## Metal Rendering Optimization

### Efficient Rendering Pipeline

**Optimizations:**
- Texture atlasing (single 2048x2048 atlas)
- Batch rendering (single draw call per type)
- Instanced rendering for identical objects
- Early culling of off-screen objects
- Shader compilation caching
- Hardware-accelerated effects

```swift
class MetalRenderer {
    func renderGrid() {
        // Only redraw changed cells
        for cell in changedCells {
            drawCell(cell)
        }
    }

    func renderParticles() {
        // Batch all particles in single draw call
        // Reuse particle buffers (object pooling)
    }
}
```

---

## Memory Management

### Object Pooling

```swift
class ParticlePool {
    private var pool: [Particle] = []
    private let maxSize = 500

    func getParticle() -> Particle {
        if let particle = pool.popLast() {
            particle.reset()
            return particle
        } else {
            return Particle()
        }
    }

    func returnParticle(_ particle: Particle) {
        if pool.count < maxSize {
            pool.append(particle)
        }
    }
}
```

### Memory Monitoring

```swift
func checkMemoryUsage() {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }

    if kerr == KERN_SUCCESS {
        let memoryUsed = Double(info.resident_size) / 1024.0 / 1024.0
        print("Memory used: \(memoryUsed) MB")

        if memoryUsed > 150 {
            // Trigger cleanup
            cleanup()
        }
    }
}
```

---

## Asset Optimization

### Texture Compression
- Use PVRTC/ASTC for textures
- Mipmaps for scaled images
- Lazy loading of large assets
- Unload unused theme assets

### Audio Optimization
- M4A format for music (compressed)
- Short sound effects in memory
- Stream long audio files
- Reduce sample rate where possible (44.1kHz → 22kHz for SFX)

---

## Code Optimization

### SwiftUI Performance

```swift
// Use @Observable instead of ObservableObject
@Observable
class GameViewModel {
    var score: Int
    var grid: GridState
}

// Avoid unnecessary view updates
struct GridView: View {
    let grid: GridState

    var body: some View {
        // Only this view updates when grid changes
    }
}

// Use @Bindable for two-way bindings
struct SettingsView: View {
    @Bindable var settings: Settings
}
```

### Lazy Loading

```swift
// Don't load all levels at once
class LevelManager {
    func loadLevel(_ id: Int) -> Level {
        // Load only requested level
    }
}

// Lazy theme loading
class ThemeManager {
    func activateTheme(_ theme: ThemeID) {
        // Unload previous theme
        unloadCurrentTheme()

        // Load new theme
        loadTheme(theme)
    }
}
```

---

## Profiling & Testing

### Instruments Tools
- **Time Profiler:** Find CPU bottlenecks
- **Allocations:** Track memory usage
- **Leaks:** Detect memory leaks
- **Core Animation:** Monitor frame rate
- **Energy Log:** Battery impact

### Test Devices
- **Minimum Spec:** iPhone 12 (A14 Bionic)
- **Mid-Range:** iPhone 14 (A15 Bionic)
- **High-End:** iPhone 15 Pro (A17 Pro, ProMotion)
- **Tablet:** iPad (9th gen), iPad Pro

### Performance Benchmarks

Run on each device:
- 10-minute gameplay session
- All modes tested
- Theme switching
- Particle-heavy scenarios
- Monitor: FPS, Memory, Battery

---

## Success Criteria

✅ 120fps on ProMotion devices
✅ 60fps minimum on all devices
✅ Memory usage <150MB during gameplay
✅ Cold launch <2 seconds
✅ No memory leaks detected
✅ Battery drain <5% per hour
✅ No frame drops during gameplay
✅ Smooth 60fps on iPhone 12
