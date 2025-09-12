# Data Models

Based on the PRD, here are the core data models for the simple block puzzle game:

## Game Model
**Purpose:** Represents a single game session

**Key Attributes:**
- `id`: UUID - unique game identifier  
- `score`: Int - current/final score
- `gameMode`: GameMode enum - endless, timer3, timer5, timer7
- `isActive`: Bool - game in progress
- `startTime`: Date - when game began
- `endTime`: Date? - when game ended

### TypeScript Interface
```typescript
interface Game {
  id: string;
  score: number;
  gameMode: 'endless' | 'timer3' | 'timer5' | 'timer7';
  isActive: boolean;
  startTime: Date;
  endTime?: Date;
}
```

### Relationships
- One GameSettings has many Games (tracks multiple play sessions)

## GameSettings Model
**Purpose:** User preferences and unlocked features

**Key Attributes:**
- `id`: UUID - settings identifier
- `highScore`: Int - best score achieved
- `unlockedBlocks`: Set<BlockType> - which blocks are available
- `timerModesUnlocked`: Bool - timer modes available at 1000 points

### TypeScript Interface
```typescript
interface GameSettings {
  id: string;
  highScore: number;
  unlockedBlocks: BlockType[];
  timerModesUnlocked: boolean;
}

type BlockType = 'single' | 'double' | 'lShape' | 'twoByOne' | 'tShape';
```

### Relationships
- Has many Games (one-to-many relationship)
