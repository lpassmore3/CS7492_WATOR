// CS 7492 - Simulation of Biology
// Project 5 - WATOR Predator/Prey Simulator (Following Dewdney's paper)
// Author: Austin Passmore

int TANK_SIZE = 650;  // Size of the swim area for the creatures

int cell_size = 8;  // Size of pixels representing a creature

int FISH_BREED = 6;
int SHARK_BREED = 12;
int SHARK_STARVE = 8;

int[][] fish = new int[TANK_SIZE][TANK_SIZE];  // Value = age
int[][] sharks = new int[TANK_SIZE][TANK_SIZE];  // Value = age
int[][] fishMove = new int[TANK_SIZE][TANK_SIZE];  // 1 = fish has moved there
int[][] sharksMove = new int[TANK_SIZE][TANK_SIZE];  // 1 = fish has moved there
int[][] starve = new int[TANK_SIZE][TANK_SIZE];  // Value = How long since ahrk last ate
// ***Any cell with value = -1 means that there is neither a fish or shark there.

// Represents the random order to visit the cells of the grid during a timestep.
// Visiting the cells in a random order decreases potential directional bias.
// index = (i * number of cells in row/column) + j
int[] order = new int[(TANK_SIZE / cell_size) * (TANK_SIZE / cell_size)];

int fishStart = 100;  // How many fish to begin with
int sharksStart = 10;  // How many sharks to begin with

int fishCount = fishStart;  // Current number of fish
int sharkCount = sharksStart;  // Current number of sharks

int extinctionFish = 7;
int extinctionSharks = 10;  // The number of sharks to add if the sharks go extinct

ArrayList<Integer> phaseFish = new ArrayList<Integer>();  // Holds up to 200 data points of fish counts
ArrayList<Integer> phaseSharks = new ArrayList<Integer>();  // Holds up to 200 data points of shark counts

boolean isSimulating = false; // Controls whether the simulation is paused or running.
boolean isSingleStep = false; // Controls whether the simultion advances only a single step.

void setup() {
  size(1300, 650);
  background(0, 0, 0);
  noStroke();
  
  initialize();
}

void draw() {
  clear();
  
  if (isSimulating) {
    //createOrder();
    fishStep();   
    sharksStep();
    checkExtinction();
    updatePhasePortrait();
  } else if (isSingleStep) {
    createOrder();
    fishStep();
    sharksStep();
    checkExtinction();
    updatePhasePortrait();
    isSingleStep = false;
  }
  
  drawCells();
  drawPhasePortrait();
  
  delay(35);
}

// Controls keyrboard inputs
void keyPressed() {
  if (key == ' ') {  // Pause and unpause the simulation
    if (isSimulating) {
      isSimulating = false;
      println("Simulation paused.");
    } else {
      isSimulating = true;
      println("Simulation playing.");
    }
  } else if (key == 's') {  // Take a single simulation step
    isSimulating = false;
    isSingleStep = true;
    //println("Simulation paused.");
  } else if (key == 'r') {  // Re-initializes the simulation
    isSimulating = false;
    initialize();
    println("Simulation re-initialized");
  } else if (key == '-') {  // Lower the cell-size by 1
    isSimulating = false;
    if (cell_size > 1) {
      cell_size--;
      if (cell_size == 1) {
        println("Please wait while the high resolution re-initializes...");
      }
      initialize();
    }
    println("Cell size is now " + str(cell_size) + ".");
  } else if (key == '+' || key == '=') {  // Raise the cell-size by 1
    isSimulating = false;
    if (cell_size < 16) {
      cell_size++;
      initialize();
    }
    println("Cell size is now " + str(cell_size) + ".");
  }
}

// Creates the random order to visit cells.
void createOrder() {
  int numCells = (TANK_SIZE / cell_size) * (TANK_SIZE / cell_size);
  ArrayList<Integer> indecies = new ArrayList<Integer>();
  for (int n = 0; n < numCells; n++) {
    indecies.add(n);
  }
  int orderSize = 0;
  order = new int[numCells];
  while (indecies.size() > 0) {
    int size = indecies.size();
    int index = (int)(random(1) * (size - 1));
    order[orderSize] = indecies.get(index);
    orderSize++;
    indecies.remove(index);
  }
}

// Clears all arrays to have a value of -1 at all cells
void clearArrays() {
  for (int i = 0; i < TANK_SIZE; i++) {
    for (int j = 0; j < TANK_SIZE; j++) {
      fish[i][j] = -1;
      sharks[i][j] = -1;
      fishMove[i][j] = -1;
      sharksMove[i][j] = -1;
      starve[i][j] = -1;
    }
  }
}

// Initializes the fish in random locations.
void initFish() {
  int numRows = TANK_SIZE / cell_size;
  int count = 0;
  while (count < fishCount) {
    int i = (int)(random(1) * numRows);
    int j = (int)(random(1) * numRows);
    if (fish[i][j] == -1) {
      int age = (int)(random(1) * FISH_BREED);
      fish[i][j] = age;
      fishMove[i][j] = 1;
      count++;
    }
  }
}

// Initializes the fish in random locations.
void initSharks() {
  int numRows = TANK_SIZE / cell_size;
  int count = 0;
  while (count < sharkCount) {
    int i = (int)(random(1) * numRows);
    int j = (int)(random(1) * numRows);
    if (fish[i][j] == -1 && sharks[i][j] == -1) {
      int age = (int)(random(1) * SHARK_BREED);
      sharks[i][j] = age;
      sharksMove[i][j] = 1;
      starve[i][j] = 0;
      count++;
    }
  }
}

// Initializes all arrays, randomly places fish and sharks
void initialize() {
  fishCount = fishStart;
  sharkCount = sharksStart;
  createOrder();
  clearArrays();
  initFish();
  initSharks();
  phaseFish.clear();
  phaseFish.add(fishCount);
  phaseSharks.clear();
  phaseSharks.add(sharkCount);
}

// Moves all the fish at random, breeds new fish when needed.
void fishStep() {
  int rowSize = TANK_SIZE / cell_size;
  int numCells = order.length;
  for (int n = 0; n < numCells; n++) {
    int index = order[n];
    int j = index % rowSize;
    int i = (index - j) / rowSize;
    
    fishMove[i][j] = -1;
  }
  for (int n = 0; n < numCells; n++) {
    int index = order[n];
    int j = index % rowSize;
    int i = (index - j) / rowSize;
    
    if (fish[i][j] != -1 && fishMove[i][j] == -1) {
    
      int newI = i;
      int newJ = j;
      
      // Get empty neighbors
      ArrayList<String> emptyNeighbors = getEmptyNeighbors(i, j);
      if (emptyNeighbors.size() > 0) {
        int directionIndex = (int)(random(1) * emptyNeighbors.size());
        String direction = emptyNeighbors.get(directionIndex);
        
        // Get the new i and j positions
        if (direction == "NW" || direction == "W" || direction == "SW") {
          newI = (i - 1 + rowSize) % rowSize;
        }
        if (direction == "NE" || direction == "E" || direction == "SE") {
          newI = (i + 1 + rowSize) % rowSize;
        }
        if (direction == "NW" || direction == "N" || direction == "NE") {
          newJ = (j - 1 + rowSize) % rowSize;
        }
        if (direction == "SW" || direction == "S" || direction == "SE") {
          newJ = (j + 1 + rowSize) % rowSize;
        }
      }
      
      // Move fish
      if (newI == i && newJ == j) {
        fish[i][j]++;
        if (fish[i][j] >= FISH_BREED) {
          fish[i][j] = 0;
        }
      } else {
        int age = fish[i][j];
        fish[newI][newJ] = age + 1;
        fishMove[newI][newJ] = 1;
        if (fish[newI][newJ] >= FISH_BREED) {
          fish[newI][newJ] = 0;
          fish[i][j] = 0;
          fishMove[i][j] = 1;
          fishCount++;
        } else {
          fish[i][j] = -1;
        }
      }
    
    }
    
  }
}

// Moves all the sharks at random, eat fish is near, and breeds new sharks when needed.
void sharksStep() {
  int rowSize = TANK_SIZE / cell_size;
  int numCells = order.length;
  for (int n = 0; n < numCells; n++) {
    int index = order[n];
    int j = index % rowSize;
    int i = (index - j) / rowSize;
    
    sharksMove[i][j] = -1;
  }
  for (int n = 0; n < numCells; n++) {
    int index = order[n];
    int j = index % rowSize;
    int i = (index - j) / rowSize;
    
    if (sharks[i][j] != -1 && sharksMove[i][j] == -1) {
    
      int newI = i;
      int newJ = j;
      
      // Get neighboring fish
      ArrayList<String> fishNeighbors = getFishNeighbors(i, j);
      if (fishNeighbors.size() > 0) {
        int directionIndex = (int)(random(1) * fishNeighbors.size());
        String direction = fishNeighbors.get(directionIndex);
        
        // Get the new i and j positions
        if (direction == "NW" || direction == "W" || direction == "SW") {
          newI = (i - 1 + rowSize) % rowSize;
        }
        if (direction == "NE" || direction == "E" || direction == "SE") {
          newI = (i + 1 + rowSize) % rowSize;
        }
        if (direction == "NW" || direction == "N" || direction == "NE") {
          newJ = (j - 1 + rowSize) % rowSize;
        }
        if (direction == "SW" || direction == "S" || direction == "SE") {
          newJ = (j + 1 + rowSize) % rowSize;
        }
        
        // Move and eat fish
        int age = sharks[i][j];
        fish[newI][newJ] = -1;
        fishMove[newI][newJ] = -1;
        sharks[newI][newJ] = age + 1;
        sharksMove[newI][newJ] = 1;
        starve[newI][newJ] = 0;
        fishCount--;
        if (sharks[newI][newJ] >= SHARK_BREED) {
          sharks[newI][newJ] = 0;
          sharks[i][j] = 0;
          sharksMove[i][j] = 1;
          starve[i][j] = 0;
          sharkCount++;
        } else {
          sharks[i][j] = -1;
          sharksMove[i][j] = -1;
          starve[i][j] = -1;
        }
      } else {
      
        // Get empty neighbors
        ArrayList<String> emptyNeighbors = getEmptyNeighbors(i, j);
        if (emptyNeighbors.size() > 0) {
          int directionIndex = (int)(random(1) * emptyNeighbors.size());
          String direction = emptyNeighbors.get(directionIndex);
          
          // Get the new i and j positions
          if (direction == "NW" || direction == "W" || direction == "SW") {
            newI = (i - 1 + rowSize) % rowSize;
          }
          if (direction == "NE" || direction == "E" || direction == "SE") {
            newI = (i + 1 + rowSize) % rowSize;
          }
          if (direction == "NW" || direction == "N" || direction == "NE") {
            newJ = (j - 1 + rowSize) % rowSize;
          }
          if (direction == "SW" || direction == "S" || direction == "SE") {
            newJ = (j + 1 + rowSize) % rowSize;
          }
        }
        
        int oldStarve = starve[i][j];
        
        // Move shark
        if (newI == i && newJ == j) {
          sharks[i][j]++;
          if (sharks[i][j] >= SHARK_BREED) {
            sharks[i][j] = 0;
            sharksMove[i][j] = 1;
          }
        } else {
          int age = sharks[i][j];
          sharks[newI][newJ] = age + 1;
          sharksMove[newI][newJ] = 1;
          if (sharks[newI][newJ] >= SHARK_BREED) {
            sharks[newI][newJ] = 0;
            sharks[i][j] = 0;
            sharksMove[i][j] = 1;
            starve[i][j] = 0;
            sharkCount++;
          } else {
            sharks[i][j] = -1;
            starve[i][j] = -1;
          }
        }
        
        // Check if shark starved
        starve[newI][newJ] = oldStarve + 1;
        if (starve[newI][newJ] >= SHARK_STARVE) {
          sharks[newI][newJ] = -1;
          sharksMove[newI][newJ] = -1;
          starve[newI][newJ] = -1;
          sharkCount--;
        }
      }
    
    }
    
  }
}

// Returns a list of empty neighbor cells.
// The list will hold strings that are abbreviations of the 8 cardinal directions.
ArrayList<String> getEmptyNeighbors(int i, int j) {
  int numRows = TANK_SIZE / cell_size;
  ArrayList<String> emptyCells = new ArrayList<String>();
  if (fish[(i - 1 + numRows) % numRows][(j - 1 + numRows) % numRows] == -1 && sharks[(i - 1 + numRows) % numRows][(j - 1 + numRows) % numRows] == -1) {
    emptyCells.add("NW");
  }
  if (fish[(i + numRows) % numRows][(j - 1 + numRows) % numRows] == -1 && sharks[(i + numRows) % numRows][(j - 1 + numRows) % numRows] == -1) {
    emptyCells.add("N");
  }
  if (fish[(i + 1 + numRows) % numRows][(j - 1 + numRows) % numRows] == -1 && sharks[(i + 1 + numRows) % numRows][(j - 1 + numRows) % numRows] == -1) {
    emptyCells.add("NE");
  }
  if (fish[(i - 1 + numRows) % numRows][(j + numRows) % numRows] == -1 && sharks[(i - 1 + numRows) % numRows][(j + numRows) % numRows] == -1) {
    emptyCells.add("W");
  }
  if (fish[(i + 1 + numRows) % numRows][(j + numRows) % numRows] == -1 && sharks[(i + 1 + numRows) % numRows][(j + numRows) % numRows] == -1) {
    emptyCells.add("E");
  }
  if (fish[(i - 1 + numRows) % numRows][(j + 1 + numRows) % numRows] == -1 && sharks[(i - 1 + numRows) % numRows][(j + 1 + numRows) % numRows] == -1) {
    emptyCells.add("SW");
  }
  if (fish[(i + numRows) % numRows][(j + 1 + numRows) % numRows] == -1 && sharks[(i + numRows) % numRows][(j + 1 + numRows) % numRows] == -1) {
    emptyCells.add("S");
  }
  if (fish[(i + 1 + numRows) % numRows][(j + 1 + numRows) % numRows] == -1 && sharks[(i + 1 + numRows) % numRows][(j + 1 + numRows) % numRows] == -1) {
    emptyCells.add("SE");
  }
  return emptyCells;
}

// Returns a list of empty neighbor cells.
// The list will hold strings that are abbreviations of the 8 cardinal directions.
ArrayList<String> getFishNeighbors(int i, int j) {
  int numRows = TANK_SIZE / cell_size;
  ArrayList<String> fishCells = new ArrayList<String>();
  if (fish[(i - 1 + numRows) % numRows][(j - 1 + numRows) % numRows] != -1) {
    fishCells.add("NW");
  }
  if (fish[(i + numRows) % numRows][(j - 1 + numRows) % numRows] != -1) {
    fishCells.add("N");
  }
  if (fish[(i + 1 + numRows) % numRows][(j - 1 + numRows) % numRows] != -1) {
    fishCells.add("NE");
  }
  if (fish[(i - 1 + numRows) % numRows][(j + numRows) % numRows] != -1) {
    fishCells.add("W");
  }
  if (fish[(i + 1 + numRows) % numRows][(j + numRows) % numRows] != -1) {
    fishCells.add("E");
  }
  if (fish[(i - 1 + numRows) % numRows][(j + 1 + numRows) % numRows] != -1) {
    fishCells.add("SW");
  }
  if (fish[(i + numRows) % numRows][(j + 1 + numRows) % numRows] != -1) {
    fishCells.add("S");
  }
  if (fish[(i + 1 + numRows) % numRows][(j + 1 + numRows) % numRows] != -1) {
    fishCells.add("SE");
  }
  return fishCells;
}

// Checks if the sharks went extinct and randomly adds new sharks.
void checkExtinction() {
  int rowSize = TANK_SIZE / cell_size;
  if (sharkCount <= 0) {
    int count = 0;
    int n = (int)(random(1) * order.length);
    while (count < extinctionSharks) {
      int index = order[n];
      int j = index % rowSize;
      int i = (index - j) / rowSize;
      if (fish[i][j] == -1) {
        sharks[i][j] = (int)(random(1) * SHARK_BREED);
        sharksMove[i][j] = 1;
        starve[i][j] = 0;
        sharkCount++;
        count++;
      }
      n = (n + 1 + order.length) % order.length;
    }
  }
  if (fishCount <= 0) {
    int count = 0;
    int n = (int)(random(1) * order.length);
    while (count < extinctionFish) {
      int index = order[n];
      int j = index % rowSize;
      int i = (index - j) / rowSize;
      if (sharks[i][j] == -1) {
        fish[i][j] = (int)(random(1) * FISH_BREED);
        fishMove[i][j] = 1;
        fishCount++;
        count++;
      }
      n = (n + 1 + order.length) % order.length;
    }
  }
}

// Updates the phase portrait data
void updatePhasePortrait() {
  if (phaseFish.size() == 200) {
    phaseFish.remove(0);
    phaseSharks.remove(0);
  }
  phaseFish.add(fishCount);
  phaseSharks.add(sharkCount);
}

// Draws the cells with fish green and the cells with sharks red.
void drawCells() {
  int rowSize = TANK_SIZE / cell_size;
  int numCells = order.length;
  strokeWeight(1);
  if (cell_size == 1) {
    noStroke();
  } else if (cell_size > 1 && cell_size < 4) {
    stroke(0, 0, 0);
  } else {
    stroke(100, 100, 100);
  }
  for (int n = 0; n < numCells; n++) {
    int index = order[n];
    int j = index % rowSize;
    int i = (index - j) / rowSize;
    if (fish[i][j] != -1) {
      fill(0, 255, 0);
      rect(i * cell_size, j * cell_size, cell_size, cell_size);
    } else if (sharks[i][j] != -1) {
      fill(255, 0, 0);
      rect(i * cell_size, j * cell_size, cell_size, cell_size);
    } else {
      fill(0, 0, 0);
      rect(i * cell_size, j * cell_size, cell_size, cell_size);
    }
  }
}

// Draws the phase portrait to the left side of the screen
void drawPhasePortrait() {
  // Background
  fill(255, 255, 255);
  noStroke();
  rect(650, 0, 650, 650);
  
  drawPhaseAxes();
  drawPhaseText();
  drawPhaseData();
}

// Draws the axes of the phase portrait
void drawPhaseAxes() {
  strokeWeight(2);
  textSize(12);
  
  // Shark line
  stroke(255, 0, 0);
  line(TANK_SIZE + 75, 25, TANK_SIZE + 75, 550);
  line(TANK_SIZE + 75, 25, TANK_SIZE + 65, 25);
  fill(255, 0, 0);
  text("10%", TANK_SIZE + 25, 32);
  
  // Fish line
  stroke(0, 255, 0);
  line(TANK_SIZE + 75, 550, TANK_SIZE + 575, 550);
  line(TANK_SIZE + 575, 550, TANK_SIZE + 575, 560);
  fill(0, 255, 0);
  text("100%", TANK_SIZE + 560, 575);
}

// Draws the text displayed on the phase portrait
void drawPhaseText() {
  int numCells = (TANK_SIZE / cell_size) * (TANK_SIZE / cell_size);
  double fishPercentage = (((double) fishCount) / ((double) numCells)) * 100.0;
  double sharkPercentage = (((double) sharkCount) / ((double) numCells)) * 100.0;
  
  String fishText = "Fish Count: " + str(fishCount) + "(" + str(Math.round(fishPercentage * 100.0) / 100.0) + "%)";
  String sharkText = "Shark Count: " + str(sharkCount) + " (" + str(Math.round(sharkPercentage * 100.0) / 100.0) + "%)";
  String cellText = "Cell Size: " + str(cell_size);
  
  textSize(16);
  fill(255, 0, 0);
  text(sharkText, TANK_SIZE + 70, 615);
  fill(0, 255, 0);
  text(fishText, TANK_SIZE + 280, 615);
  fill(0, 0, 0);
  text(cellText, TANK_SIZE + 490, 615);
}

// Draws the data points onto the phase portrait
void drawPhaseData() {
  int numCells = (TANK_SIZE / cell_size) * (TANK_SIZE / cell_size);
  int x0 = TANK_SIZE + 75;
  int y0 = 550;
  int sharkY = 25;
  int fishX = TANK_SIZE + 575;
  
  noStroke();
  fill(0, 0, 0);
  
  for (int n = 0; n < phaseFish.size(); n++) {
    double fishPercentage = ((double) phaseFish.get(n)) / ((double) numCells);
    double sharkPercentage = ((double) phaseSharks.get(n)) / ((double) numCells);
    int x = x0 + (int)((fishX - x0) * fishPercentage);
    int y = y0 - (int)((y0 - sharkY) * sharkPercentage / 0.1);
    fill(0, 0, 0 + (255 * n / 200));
    ellipse(x, y, 10, 10);
  }
  
}
