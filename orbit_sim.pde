int[] screen_size = {900, 900}; // Size of canvas

ArrayList<Body> allBodies = new ArrayList<Body>();
ArrayList<Particle> activeParticles = new ArrayList<Particle>();

Body body1 = new Body(40, 1e16, new PVector(450, 450));
//Body planet1 = new Body(15, 1e14, new PVector(450, 600), new PVector(-66.69, 0));
//Body planet2 = new Body(10, 1e14, new PVector(750, 450), new PVector(0, 47.16));
//Body planet3 = new Body(7, 0, new PVector(600, 50), new PVector(10, 10));
//Body moon = new Body(3, 0, new PVector(765, 450), new PVector(0, 60));
Rocket rocket = new Rocket(10, new PVector(800, 450), new PVector(0, -50.08), 50);

int particle_spread = 20;
int particle_speed = 200;

final double G = 6.673e-11;

// Setting screen size accordign to 'screen_size' array
// See more at: https://processing.org/reference/size_.html
void settings() {
  size(screen_size[0], screen_size[1]);
  noSmooth();
}

void setup() {
  background(0);
  
  return;
}


double last_millis = (double)millis();

void render(float time_step) {
  background(0);

  // Renders each particle
  for (Particle part : activeParticles) {    
    part.display();
    
    part.time_alive += time_step;
    part.pos.add(PVector.mult(part.vel, time_step));
  }
  
  // Removes all dead particles from render
  // Particle is deleted when its lifetime is over
  activeParticles.removeIf(p -> p.time_alive >= p.lifetime);
  
  // Rocket releases particles when thrust is applied
  if (rocket.thrusting) {
    new Particle(2, 3, rocket.pos.copy(),
    PVector.add(rocket.vel.copy(), PVector.mult(PVector.fromAngle(rocket.rotation + (float)Math.toRadians(Math.random() * particle_spread - particle_spread / 2)), -particle_speed)));
  }
  
  // Render all bodies
  for (Body body : allBodies) {
    body.display();
  }
}

void physics_update(float time_step) {

  // Applies additional acceleration to a rocket due thrust
  if (rocket.thrusting) {
    rocket.vel.add(PVector.fromAngle(rocket.rotation).mult(time_step * rocket.thrust));
  }
  
  // Calculate acceleration due gravity 
  for (Body body : allBodies) {
    PVector acceleration = new PVector(0, 0);
    
    for (Body other_body : allBodies) {
      if (!body.equals(other_body)) {
        PVector diff = new PVector(0,0);
        PVector.sub(other_body.pos, body.pos, diff);
        double distance = diff.mag();
        double ax = G * other_body.mass / (distance * distance) * diff.normalize().x;
        double ay = G * other_body.mass / (distance * distance) * diff.normalize().y;
        
        acceleration.add((float)ax, (float)ay);
      }
    }
    

    // Moves objects according to velocity
    // Applies acceleration and velocity to position
    body.vel.add(acceleration.x * time_step, acceleration.y * time_step);
    body.pos.add(body.vel.x * time_step, body.vel.y * time_step);
  }
}

boolean leftPressed = false;
boolean rightPressed = false;

// Applies thrust to rocket when SPACE is pressed
void keyPressed() {
  if (key == ' ') {
    rocket.thrusting = true;
  }
  
  if (keyCode == LEFT) {
    leftPressed = true;
  } else if (keyCode == RIGHT) {
    rightPressed = true;
  }
}

// Stops rocket thrust when SPACE is released
void keyReleased() {
  if (key == ' ') {
    rocket.thrusting = false;
  }
  
  if (keyCode == LEFT) {
    leftPressed = false;
  } else if (keyCode == RIGHT) {
    rightPressed = false;
  }
}


void draw() {
  
  // Time since last render step (in seconds)
  double time_step = ((double)millis() - last_millis) / 1000;
  last_millis = (double)millis();
  
  render((float) time_step);
  physics_update((float)time_step);
  
  // Allows for rotating the rocket when left or right arrow keys are pressed
  if (rightPressed) {
    rocket.rotation += 0.05;
  }
  if (leftPressed) {
    rocket.rotation += -0.05;
  }
  
  return;
}


/* This is where all the classes are
 * Having classes in one file is better for compatability 
 * for Processing, though it supports classes in separate files.
 */
 
// Body class - any body that obeys the laws of gravity
class Body {
  public double mass = 0;  // Mass of object in kg
  public int size = 1;     // Radius of an object
  public PVector pos = new PVector(0, 0);  // Object position
  public PVector vel = new PVector(0, 0);  // Object velocity

  // Constructors
  Body(int size, PVector pos) {
    this.size = size;
    this.pos = pos;
    
    allBodies.add(this);  // Adds this body to a list of active bodies for render and physics calculations
  }

  Body(int size, PVector pos, PVector vel) {
    this.size = size;
    this.pos = pos;
    this.vel = vel;
    
    allBodies.add(this);
  }
  
  Body(int size, double mass, PVector pos) {
    this.mass = mass;
    this.size = size;
    this.pos = pos;
    
    allBodies.add(this);
  }
  
    Body(int size, double mass, PVector pos, PVector vel) {
    this.mass = mass;
    this.pos = pos;
    this.vel = vel;
    this.size = size;
    allBodies.add(this);
  }
  
  // Renders this body
  public void display() {
    fill(255);
    noStroke();
    
    ellipse(this.pos.x, this.pos.y, this.size, this.size);
  }
  
  // Checks if two bodies are equal
  public boolean equals(Body o) {
    return this.pos == o.pos;
  }
  
  
  // Prints body object with format:
  // "Body at (x pos, y pox) with velocity (x vel, y vel)"
  @Override
  public String toString() {
    return String.format("Body at (%s, %s) with velocity (%s, %s)", pos.x, pos.y, vel.x, vel.y);
  }
}


// Controllable Rocket
// Obeys the laws of gravity but can also be controlled by user
// Arrow keys to rotate rocket
// SPACE to release realistic thrust
class Rocket extends Body {
 
 public float thrust = 0;    // Thrust acceleration in m/s^2
 public float rotation = 0;
 public boolean thrusting = false;
 
 Rocket(int size, PVector pos, float thrust) {
   super(size, pos);
   this.thrust = thrust;
 }
 
  Rocket(int size, PVector pos, PVector vel, float thrust) {
   super(size, pos, vel);
   this.thrust = thrust;
 }
 
 // Renders rocket as a pointing triangle
 @Override
 public void display() {
   fill(255);
   noStroke();
    PVector dir = PVector.fromAngle(rotation).mult(this.size);
    PVector left = PVector.fromAngle(rotation + TWO_PI / 3).mult(this.size);
    PVector right = PVector.fromAngle(rotation + 2 * TWO_PI / 3).mult(this.size);
    
    // Add the rocket's position to these vectors
    float x1 = pos.x + dir.x;
    float y1 = pos.y + dir.y;
    float x2 = pos.x + left.x;
    float y2 = pos.y + left.y;
    float x3 = pos.x + right.x;
    float y3 = pos.y + right.y;
    
    triangle(x1, y1, x2, y2, x3, y3);

 }
 
 @Override
 public String toString() {
  return String.format("Rocket at (%s, %s) with velocity (%s, %s)", pos.x, pos.y, vel.x, vel.y);
 }
  
}


class Particle {
 
  public int size = 1;
  public PVector pos;
  public PVector vel;
  public float lifetime = 5;  // How long particle exists
  public float time_alive = 0;
  
  Particle(int size, float lifetime, PVector pos, PVector vel) {
    this.size = size;
    this.lifetime = lifetime;
    this.pos = pos;
    this.vel = vel;
    
    activeParticles.add(this);
  }
  
  // Displays this particle on the screen
  public void display() {    
    fill((int)(255.0 * (lifetime - time_alive) / lifetime));
    ellipse(this.pos.x, this.pos.y, this.size, this.size);
  }
}
