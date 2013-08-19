class Node {
  
  long id;
  String name;
  PImage pic = null;
  Node parent = null;
  Node[] followers = null;
  
  PGraphics pg;
  float rad;
  float scaling = 1;
  float minX, maxX, minY, maxY;
  
  PVector pos;
  PVector velocity = new PVector(0, 0);
  float maxVelocity = 10;
  float damping = 0.5;
  float radius = 100;
  float strength = -10; // Negative ensures repulsion
  float ramp = 1.0;
  
  Node(int x, int y, long rootID) {
    pos = new PVector(x, y);
    long[] root = new long[1];
    root[0] = rootID;
    ResponseList<User> users = lookup(root);
    for (User u : users) {
      id = u.getId();
      name = u.getName();
      rad = map(constrain(u.getStatusesCount(), 0, 3000), 0, 3000, 10, 25);
      pic = loadImage(u.getProfileImageURL(), "png"); 
      int newSize = max(2, int(rad*2));
      pg = createGraphics(newSize, newSize);
      minX = rad;
      maxX = width - rad;
      minY = rad;
      maxY = height - rad;
    }
  }
  
  Node(Node parent, long id, String name, float x, float y, float rad) {
    this.parent = parent;
    this.id = id;
    this.name = name;
    pos = new PVector(x, y);
    this.rad = rad;
    int newSize = max(2, int(rad*2));
    pg = createGraphics(newSize, newSize);
    minX = rad;
    maxX = width - rad;
    minY = rad;
    maxY = height - rad;
  }

  void attract(ArrayList<Node> nodes) {
    for (Node n : nodes) {
      if (n == null) break; // stop when empty
      if (n == this) continue; // not with itself
      float d = PVector.dist(pos, n.pos);
      if (d > 0 && d < radius) {
        float s = pow(d / radius, 1 / ramp);
        float f = s * 9 * strength * (1 / (s + 1) + ((s - 3) / 4)) / d;
        PVector df = PVector.sub(pos, n.pos);
        df.mult(f);
        n.velocity.add(df);
      }
    }
  }

  void update() {
    velocity.limit(maxVelocity);
    pos.add(velocity);
    velocity.mult(1 - damping);
    stayWithinBounds();
  }

  void render() {
    PVector spos = screenPos(pos);
    if (parent == null) {
      if (!mouseInside()) {
        pushMatrix();
        translate(spos.x, spos.y);
        int newSize = max(2, int(rad * 2 * scaling));
        fill(50, 50);
        ellipse(0, 0, max(2, int((rad+8)*scaling)), max(2, int((rad+8)*scaling)));
        stroke(255, 50);
        strokeWeight(2);
        fill(0, 50);
        ellipse(0, 0, newSize/2, newSize/2);
        fill(255, 50);
        ellipse(0, 0, 0.1 * scaling, 0.1 * scaling);
      popMatrix();
      }
      else {
        if (followers != null) {
          highlightFollowers(spos);
        }
        showPic(spos);
        fill(0);
        text(name, spos.x, spos.y - rad);
      }
    } else {
      if (!mouseInside() && !parent.mouseInside()) {
        pushMatrix();
          translate(spos.x, spos.y);
          int newSize = max(2, int(rad * 2 * scaling));
          fill(50, 50);
          ellipse(0, 0, max(2, int((rad+8)*scaling)), max(2, int((rad+8)*scaling)));
          stroke(255, 50);
          strokeWeight(2);
          fill(0, 50);
          ellipse(0, 0, newSize/2, newSize/2);
          fill(255, 50);
          ellipse(0, 0, 0.1 * scaling, 0.1 * scaling);
        popMatrix();
      } else {
        if (followers != null) {
          highlightFollowers(spos);
        }
        showPic(spos);
        fill(0);
        if (mouseInside()) text(name, spos.x, spos.y - rad);
      }
    }
  }
  
  void showPic(PVector spos) {
    if (pic.width > 0) {
      pushMatrix();
        translate(spos.x, spos.y);
        PImage tempPic = pic.get();
        int newSize = max(2, int(rad * 2 * scaling));
        fill(0);
        ellipse(0, 0, newSize + 4, newSize + 4);
        tempPic.resize(newSize, newSize);
        pg.setSize(newSize, newSize);
        pg.smooth();
        pg.beginDraw();
        pg.background(0, 0);
        pg.noStroke();
        pg.fill(255);
        pg.ellipse(newSize/2, newSize/2, newSize, newSize);
        pg.endDraw();
        tempPic.mask(pg);
        image(tempPic, 0, 0);
      popMatrix();
    }
  }
  
  void highlightFollowers(PVector spos) {
    for (int i=0; i<followers.length; i++) {
      stroke(0, 130, 164);
      strokeWeight(1);
      line(spos.x, spos.y, followers[i].screenPos(followers[i].pos).x, followers[i].screenPos(followers[i].pos).y);
      followers[i].showPic(followers[i].screenPos(followers[i].pos));
    }
  }
  
  void fetchFollowers() {
    IDs followers_ids = null;  
    try {        
      followers_ids = twitter.getFollowersIDs(this.id, -1);
    }   
    catch(TwitterException e) {         
      println("Fetch followers: " + e + " Status code: " + e.getStatusCode());
    }
    if (followers_ids != null) { // If there was no issue fetching the list of follower ids
      long[] ids = followers_ids.getIDs();
      int l = min(ids.length, 50);
      followers = new Node[l];
      int start = floor(random(0, l-50));
      ResponseList<User> users = lookup(Arrays.copyOfRange(ids, start, start+50));
      if (users != null) { // If this node is not protected
        // Check if the new node doesn't already exist
        ArrayList<User> newUsers = new ArrayList();
        ArrayList<Node> duplicates = new ArrayList();
        for (User u : users) {
          boolean duplicate = false;
          Node duplicateNode = null;
          for (Node n : nodes) {
            if (n.id == u.getId()) {
              duplicate = true;
              duplicateNode = n;
            }
          }
          if (duplicate) {
            duplicates.add(duplicateNode);
          } else {
            newUsers.add(u);
          }
        }

        for (int i=0; i<newUsers.size(); i++) {
          Node newNode = setupNewNode(this, newUsers.get(i));
          nodes.add(newNode);
          followers[i] = newNode;
          Spring newSpring = new Spring(this, newNode);
          springs.add(newSpring);
          String url = newUsers.get(i).getProfileImageURL();
          newNode.pic = requestImage(url, "png");
        }
        
        for (int i=0; i<duplicates.size(); i++) {
          followers[newUsers.size() + i] = duplicates.get(i);
          Spring newSpring = new Spring(this, duplicates.get(i));
          springs.add(newSpring);
        }
      }
    }
  }
  
  ResponseList<User> lookup(long[] ids) {
    ResponseList<User> users = null;
    try {
      users = twitter.lookupUsers(ids);
    } 
    catch(TwitterException e) {
      println("Lookup users: " + e + " Status code: " + e.getStatusCode());
    }
    return users;
  }
  
  Node setupNewNode(Node parent, User u) {
    long id = u.getId();
    String name = u.getName();
    int statusesCount = u.getStatusesCount();
    Node newNode = new Node( parent, id, name, screenPos(pos).x + random(-200, 200), screenPos(pos).y + random(-200, 200), map(constrain(statusesCount, 0, 3000), 0, 3000, 10, 25) );
    return newNode;
  }

  boolean mouseInside() {
    if (dist(mouseX, mouseY, screenPos(pos).x, screenPos(pos).y) < rad) {
      return true;
    } 
    else {
      return false;
    }
  }

  void stayWithinBounds() {
    if (pos.x < minX) {
      pos.x = minX - (pos.x - minX);
      velocity.x = -velocity.x;
    }
    if (pos.x > maxX) {
      pos.x = maxX - (pos.x - maxX);
      velocity.x = -velocity.x;
    }
    if (pos.y < minY) {
      pos.y = minY - (pos.y - minY);
      velocity.y = -velocity.y;
    }
    if (pos.y > maxY) {
      pos.y = maxY - (pos.y - maxY);
      velocity.y = -velocity.y;
    }
  }

  PVector screenPos(PVector p) {
    if (fishEyeView) {
      PVector centerToPos = PVector.sub(p, center);
      float distanceToCenter = centerToPos.mag();
      float viewingAngle = atan(distanceToCenter / observerRadius);
      float newDistanceToCenter = viewingAngle * observerRadius; 
      centerToPos.normalize();
      centerToPos.mult(newDistanceToCenter);
      scaling = map(viewingAngle, 0, HALF_PI/2, 2, 0.5);
      return PVector.add(center, centerToPos);
    } 
    else {
      scaling = 1;
      return pos;
    }
  }
 
}
