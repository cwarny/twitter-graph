import java.util.*;

ArrayList<Node> nodes = new ArrayList();
ArrayList<Spring> springs = new ArrayList();

long rootID = 347348265; // To replace with whatever Twitter ID you want to explore
XML credentials;

PFont misoFont;

boolean fishEyeView = false;
float observerRadius;
PVector center;

TwitterFactory twitterFactory;
Twitter twitter;

Node selectedNode;

void setup() {
  size(1280, 720);
  background(255);
  
  credentials = loadXML("credentials.xml").getChild("twitter");
  
  connectTwitter();

  center = new PVector(mouseX, mouseY);
  observerRadius = min(width, height)/3;
  
  Node rootNode = new Node(width/2, height/2, rootID);
  nodes.add(rootNode);
  selectedNode = rootNode;

  misoFont = createFont("Miso", 12);
  textFont(misoFont);
  imageMode(CENTER);
  
  smooth();
  
  frameRate(24);
}


void draw() {
  background(255);
  center = new PVector(mouseX, mouseY);
  for (Node n : nodes) {
    n.attract(nodes);
    n.update();
  }
  for (Spring s : springs) {
    s.update();
    s.render();
  }
  for (Node n : nodes) {
    n.render();
  }
  if (selectedNode.mouseInside()) selectedNode.render();
  
}

void connectTwitter() {  
  ConfigurationBuilder cb = new ConfigurationBuilder();  
  cb.setOAuthConsumerKey(credentials.getString("consumerKey"));
  cb.setOAuthConsumerSecret(credentials.getString("consumerSecret"));
  cb.setOAuthAccessToken(credentials.getString("accessToken"));
  cb.setOAuthAccessTokenSecret(credentials.getString("accessTokenSecret")); 

  twitterFactory = new TwitterFactory(cb.build());    
  twitter = twitterFactory.getInstance();  

  println("connected");
}

void keyPressed() {
  if (key == ' ') fishEyeView = !fishEyeView;
  if (key == 's') saveFrame("out/frames####.png");
}

void mousePressed() {
  Node newSelectedNode = null;
  for (Node n : nodes) {
    if (n.mouseInside()) {
      newSelectedNode = n;
      break;
    }
  }
  if (newSelectedNode != null) { // If something was actually selected
    selectedNode = newSelectedNode;
    selectedNode.fetchFollowers();
  }
}
