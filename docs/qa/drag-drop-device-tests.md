# Physical Device Testing Checklist: Drag-and-Drop Block Placement

## Test Environment Setup
- [ ] Project builds successfully in Xcode
- [ ] App installs and launches on device without crashes
- [ ] All drag-drop components are visible and properly sized

## Device-Specific Tests

### iPhone Testing
**Device Types to Test:** iPhone SE, iPhone 14/15, iPhone 14/15 Pro Max

#### Touch Responsiveness Tests
- [ ] **Single finger drag**: Block responds immediately to touch
- [ ] **Touch precision**: Can accurately select small blocks on iPhone screen
- [ ] **Edge cases**: Drag works near screen edges and notch area
- [ ] **Gesture conflicts**: No conflicts with iOS system gestures (Control Center, etc.)

#### Performance Tests  
- [ ] **Smooth 60fps**: No frame drops during continuous dragging
- [ ] **Memory usage**: App doesn't crash during extended drag sessions
- [ ] **Battery impact**: Reasonable battery consumption during gameplay

#### Visual Feedback Tests
- [ ] **Drag lift effect**: Block scales and shows shadow when drag begins
- [ ] **Follow finger**: Block follows finger movement smoothly without lag
- [ ] **Grid highlights**: Valid positions highlight clearly during drag
- [ ] **Preview feedback**: Placement preview shows correctly sized for iPhone

### iPad Testing  
**Device Types to Test:** iPad Mini, iPad Air, iPad Pro

#### Touch and Size Tests
- [ ] **Larger targets**: Touch targets are appropriately sized for iPad
- [ ] **Multi-touch**: No accidental multi-touch interference
- [ ] **Palm rejection**: Works properly with Apple Pencil/palm resting
- [ ] **Orientation**: Drag works in both portrait and landscape modes

#### Visual Scale Tests
- [ ] **Grid scaling**: Game grid uses full iPad screen appropriately  
- [ ] **Block sizing**: Blocks are properly sized for larger screen
- [ ] **Animation timing**: Animations feel natural on larger screen
- [ ] **Spacing**: All UI elements have appropriate spacing for iPad

## Cross-Device Feature Tests

### Core Drag Functionality
- [ ] **Drag initiation**: Touch and hold to start drag works consistently
- [ ] **Drag movement**: Block follows finger smoothly across screen
- [ ] **Drag termination**: Releasing finger ends drag appropriately
- [ ] **Cancel drag**: Dragging outside valid area cancels gracefully

### Placement Validation
- [ ] **Valid placement**: Green highlights appear for valid drop zones
- [ ] **Invalid placement**: No highlights or red feedback for invalid zones  
- [ ] **Boundary checking**: Cannot place blocks outside 10x10 grid
- [ ] **Collision detection**: Cannot place on occupied cells

### Animation Quality
- [ ] **Snap animation**: Smooth spring animation when block snaps to grid
- [ ] **Success feedback**: Satisfying completion effect when block placed
- [ ] **Invalid feedback**: Clear shake/return animation for invalid drops
- [ ] **Performance**: All animations maintain 60fps on device

### Haptic Feedback
- [ ] **Drag start**: Light haptic when drag begins
- [ ] **Valid drop**: Success haptic when block placed successfully  
- [ ] **Invalid drop**: Error haptic for invalid placement attempts
- [ ] **Appropriate intensity**: Haptics feel natural, not overwhelming

## Accessibility Tests

### VoiceOver Testing
- [ ] **Enable VoiceOver**: All drag elements are announced properly
- [ ] **Alternative input**: Can place blocks using VoiceOver double-tap
- [ ] **State announcements**: Drag state changes are announced
- [ ] **Grid navigation**: Can navigate grid positions with VoiceOver

### Motor Accessibility
- [ ] **Switch Control**: Works with external switch controls
- [ ] **Assistive Touch**: Compatible with iOS Assistive Touch
- [ ] **Larger touch targets**: Touch targets meet accessibility guidelines
- [ ] **Timeout handling**: No time pressure for users with motor difficulties

## Device-Specific Edge Cases

### iPhone Specific
- [ ] **Dynamic Island**: UI doesn't interfere with Dynamic Island (iPhone 14 Pro+)
- [ ] **Home indicator**: Drag gestures don't trigger home gesture
- [ ] **Reachability**: Works properly when reachability is enabled
- [ ] **Low power mode**: Maintains functionality in low power mode

### iPad Specific  
- [ ] **Split view**: Works properly in iPad split screen mode
- [ ] **Slide over**: Handles slide over apps without interference
- [ ] **External keyboard**: No conflicts with keyboard shortcuts
- [ ] **Stage Manager**: Compatible with Stage Manager multitasking

## Performance Benchmarks

### Frame Rate Testing
- [ ] **Continuous drag**: Maintains 60fps during 30+ second drag sessions
- [ ] **Multiple blocks**: Performance stable with all 3 blocks being dragged
- [ ] **Grid updates**: Real-time preview updates don't cause frame drops
- [ ] **Background apps**: Performance maintained with other apps running

### Memory Testing
- [ ] **Memory leaks**: No memory growth during extended gameplay
- [ ] **Memory warnings**: App handles low memory situations gracefully
- [ ] **State preservation**: Drag state preserved during app backgrounding
- [ ] **Restart recovery**: Clean state after force quit and restart

## Edge Case Testing

### Unusual Interactions
- [ ] **Rapid tapping**: Multiple rapid taps don't cause issues
- [ ] **Gesture interruption**: Phone calls/notifications handled gracefully
- [ ] **Rotation during drag**: Screen rotation during drag handled properly
- [ ] **App backgrounding**: Dragging interrupted by backgrounding recovers

### Error Conditions
- [ ] **Grid full**: Appropriate feedback when grid becomes full
- [ ] **No valid moves**: Handles situation when no blocks can be placed
- [ ] **Concurrent operations**: Multiple simultaneous drags handled safely
- [ ] **State corruption**: App recovers from any corrupted drag states

## Test Results Documentation

### Performance Measurements
- Average frame rate during drag: _____ fps
- Memory usage during gameplay: _____ MB  
- Battery drain per hour: _____%
- Touch response latency: _____ ms

### Device-Specific Issues Found
- iPhone issues: _________________
- iPad issues: ___________________
- Cross-device issues: ____________

### Recommendations
- Performance optimizations needed: _________________
- UI adjustments required: _______________________
- Feature improvements suggested: ________________

## Test Completion
- [ ] All critical tests passed
- [ ] Performance meets 60fps requirement
- [ ] No crashes or major issues found
- [ ] Accessibility features working
- [ ] Ready for production release

**Tested by:** _________________  
**Test date:** _________________  
**Devices used:** ______________  
**iOS versions:** ______________