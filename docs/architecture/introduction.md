# Introduction

This document outlines the complete system architecture for **Block Puzzle Pro**, a premium iOS puzzle game featuring progressive block unlocks, customizable timer modes, and player-controlled monetization. The architecture encompasses the entire technical stack from Swift 6.1 + SpriteKit game engine through SwiftData persistence, CloudKit sync, and AdMob integration.

This unified approach ensures consistency across all system components while maintaining the rapid development timeline (6-8 week solo development) and premium user experience requirements (60fps performance, <2s launch times, 40% Day 1 retention targets).

The architecture is specifically designed for AI-driven development, providing clear patterns and constraints that enable efficient code generation while maintaining architectural integrity throughout the development process.

## Starter Template or Existing Project

**Status:** ✅ **Native iOS Project - Swift + SpriteKit Foundation**

After reviewing the PRD, this is a **greenfield iOS mobile game project** using Apple's native development stack:

- **Platform:** Native iOS (Swift 6.1 + SpriteKit)
- **Architecture Pattern:** Actor-based monolith with component separation  
- **Target:** Single iOS app with integrated backend services (CloudKit, AdMob)
- **Constraints:** Portrait-only orientation, offline-first with cloud sync

**Key Architectural Decisions Already Made:**
- Swift 6.1 for enhanced concurrency safety and performance
- SpriteKit for 60fps game rendering and smooth animations  
- SwiftData for local persistence with automatic CloudKit integration
- Actor-based architecture (GameEngine, ScoreTracker, BlockFactory, AdManager)
- iOS 17+ minimum support for 95% device coverage

This is **not a traditional web fullstack** application but rather a **comprehensive mobile system** that includes client-side game logic, local data persistence, cloud synchronization, and third-party service integrations.

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|---------|
| 2025-09-12 | 1.0 | Initial architecture document creation | Winston (Architect) |
