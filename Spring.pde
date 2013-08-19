class Spring {
  
  Node from;
  Node to;

  float length = 20;
  float stiffness = 0.5;
  float damping = 0.9;

  Spring(Node from, Node to) {
    this.from = from;
    this.to = to;
  }

  void update() {
    PVector diff = PVector.sub(to.pos, from.pos);
    diff.normalize();
    diff.mult(length);
    PVector target = PVector.add(from.pos, diff);

    PVector force = PVector.sub(target, to.pos);
    force.mult(0.5);
    force.mult(stiffness);
    force.mult(1 - damping);

    to.velocity.add(force);
    from.velocity.add(PVector.mult(force, -1));
  }
  
  void render() {
    stroke(0, 130, 164, 50);
    strokeWeight(1);
    PVector sposfrom = from.screenPos(from.pos);
    PVector sposto = to.screenPos(to.pos);
    line(sposfrom.x, sposfrom.y, sposto.x, sposto.y);
  }

}
