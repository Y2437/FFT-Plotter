import java.util.LinkedList;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Comparator;
final int ERASE_RADIUS=0;
final int GRAD_BOUND=100;
final int MAX_DIST=100;
final int MIN_POINT_NUM=20;
final float drawSpeed = 0.001;
PShape svg;
int imgWidth;
int imgHeight;
List<Complex> allPoints= new ArrayList();
List<Complex> sortedAllPoints= new ArrayList();
List<List<Complex>> sortedPoints=new ArrayList();
List<List<Circle>> circleList= new ArrayList();
void setup(){
  size(500,500, P2D);
  smooth(8);
  pixelDensity(displayDensity());
  svg = loadShape("../img/Tester11.svg");
  imgWidth = ceil(svg.width/2);
  imgHeight = ceil(svg.height/2);
  surface.setSize(imgWidth, imgHeight);
  
  // 1. 提取路径（保持SVG原始拓扑顺序，不打乱闭合性）
  extractPathPoints(svg);
  
  if(allPoints.isEmpty()){
    println("No points detected!");
    return;
  }

  // 2. 图像翻转修正：将Y坐标取反，解决倒置问题
  for(Complex p: allPoints){
    p.image = -p.image;
  }

  // 3. 自动缩放居中
  float minX=Float.MAX_VALUE, maxX=-Float.MAX_VALUE;
  float minY=Float.MAX_VALUE, maxY=-Float.MAX_VALUE;
  for(Complex p:allPoints){
    if(p.real<minX) minX=p.real;
    if(p.real>maxX) maxX=p.real;
    if(p.image<minY) minY=p.image;
    if(p.image>maxY) maxY=p.image;
  }
  
  // 计算内容宽高
  float contentW = max(maxX - minX, 1e-5);
  float contentH = max(maxY - minY, 1e-5);
  
  // 计算缩放比例，预留20%的Padding (0.8)
  float scale = min(imgWidth / contentW, imgHeight / contentH) * 0.8;
  
  float cx=(minX+maxX)/2;
  float cy=(minY+maxY)/2;
  
  for(Complex p:allPoints){
    p.real=(p.real-cx)*scale;
    p.image=(p.image-cy)*scale;
  }
  
  // 4. 重采样与FFT (针对每一条独立路径)
  for(int i=0;i<sortedPoints.size();i++){
    // 自适应采样数 (2的幂次)
    int m=1;
    while(m<sortedPoints.get(i).size()||m<512) m<<=1;
    
    // 重采样
    sortedPoints.set(i,resample(sortedPoints.get(i),m));
    
    // 局部去中心化 (FFT要求)
    float centerX = 0;
    float centerY = 0;
    for(Complex p : sortedPoints.get(i)) {
      centerX += p.real;
      centerY += p.image;
    }
    centerX /= sortedPoints.get(i).size();
    centerY /= sortedPoints.get(i).size();
    for(Complex p : sortedPoints.get(i)) {
      p.real -= centerX;
      p.image -= centerY;
    }
    
    // 执行FFT
    FFT(sortedPoints.get(i));
  }
  
  // 5. 生成圆列表
  for(int i=0;i<sortedPoints.size();i++){
    List<Circle> subCircleList=new ArrayList();
    for(int j=0;j<sortedPoints.get(i).size();j++){
        subCircleList.add(new Circle(j,sortedPoints.get(i).get(j),sortedPoints.get(i).size()));
    }
    Collections.sort(subCircleList, new AmplitudeComparator());
    circleList.add(subCircleList);
  }   
}

void extractPathPoints(PShape shape) {
  for (int i = 0; i < shape.getChildCount(); i++) {
    PShape child = shape.getChild(i);
    extractPathPoints(child);
  }
  int vertexCount = shape.getVertexCount();
  if (vertexCount > 0) {
    List<Complex> currentPath = new ArrayList();
    for (int i = 0; i < vertexCount; i++) {
      PVector v = shape.getVertex(i);
      Complex c = new Complex(v.x, v.y);
      currentPath.add(c);
      allPoints.add(c); // 引用同一个对象，方便后续统一旋转缩放
    }
    // 过滤掉极其微小的噪点路径
    if(currentPath.size() > 5) {
      sortedPoints.add(currentPath);
    }
  }
}

int currentShapeIndex = 0;         
float time = 0;                    
List<List<PVector>> finishedTrails = new ArrayList(); 
List<PVector> currentTrail = new ArrayList();         

void draw() {
  if (circleList.isEmpty()) return;
  translate(imgWidth/2, imgHeight/2);
  background(20);
  strokeWeight(4);
  noFill();
  strokeJoin(ROUND);
  strokeCap(ROUND);
  stroke(0, 255, 255);
  
  // 绘制已完成的路径（闭合）
  for (List<PVector> trail : finishedTrails) {
    beginShape();
    for (PVector p : trail) {
      vertex(p.x, p.y);
    }
    endShape(CLOSE);
  }
  
  int stepsPerFrame = 4; 
  for (int k = 0; k < stepsPerFrame; k++) {
    // 动画循环逻辑：如果绘制完所有形状，重置并重新开始
    if (currentShapeIndex >= circleList.size()) {
       currentShapeIndex = 0;
       finishedTrails.clear();
       currentTrail.clear();
       time = 0;
       break;
    }
    
    List<Circle> circles = circleList.get(currentShapeIndex);
    float x = 0;
    float y = 0;
    for(int i = 0; i < circles.size(); i++){
      Circle c = circles.get(i);
      c.theta = c.p + c.f * time;
      x += (float)(c.a * cos((float)c.theta));
      y += (float)(c.a * sin((float)c.theta));
    }
    currentTrail.add(new PVector(x, y));
    time += drawSpeed;
    
    if (time >= TWO_PI) {
      finishedTrails.add(new ArrayList<PVector>(currentTrail));
      currentTrail.clear();
      time = 0;
      currentShapeIndex++;
    }
  }
  
  strokeWeight(1);
  if (currentShapeIndex < circleList.size()) {
    List<Circle> circles = circleList.get(currentShapeIndex);
    float x = 0;
    float y = 0;
    for(int i = 0; i < circles.size(); i++){
      Circle c = circles.get(i);
      float prevX = x;
      float prevY = y;
      c.theta = c.p + c.f * time;
      x += (float)(c.a * cos((float)c.theta));
      y += (float)(c.a * sin((float)c.theta));
      stroke(255, 255, 51);
      ellipse(prevX, prevY, (float)c.a*2, (float)c.a*2);
      stroke(255, 255, 255);
      line(prevX, prevY, x, y);
    }
    strokeWeight(4);
    stroke(0, 255, 255);
    beginShape();
    for (PVector p : currentTrail) {
      vertex(p.x, p.y);
    }
    // 正在绘制的路径不需要CLOSE，等到完成时再CLOSE
    endShape();
  }
}
class Circle{
  public int f;
  public double a;
  public double p;
  public double theta;
  public Circle(int j, Complex point,int m){
    if(j>=m/2) j=j-m;
    f=j;
    this.a=sqrt(point.real*point.real+point.image*point.image)/m;
    this.p=atan2(point.image,point.real);
    this.theta=p;
  }
  public void update(double delta){
    theta+=f*delta;
  }
  public Complex getPos(){
    return new Complex((float)a*cos((float)theta),(float)a*sin((float)theta));
  }
}
class Complex{
  public float real;
  public float image;
  public Complex(){
    real=0;
    image=0;
  }
  public Complex(float real,float image){
    this.real=real;
    this.image=image;
  }
  public Complex mul(Complex b){
    return new Complex(this.real*b.real-this.image*b.image,this.real*b.image+this.image*b.real);
  }
  public Complex add(Complex b){
    return new Complex(this.real+b.real,this.image+b.image);
  }
  public Complex sub(Complex b){
    return new Complex(this.real-b.real,this.image-b.image);
  }
  public float distSq(Complex b){
    return (this.real-b.real)*(this.real-b.real)+(this.image-b.image)*(this.image-b.image);
  }
}
class AmplitudeComparator implements Comparator<Circle> {
  public int compare(Circle c1, Circle c2) {
    if (c1.a > c2.a) return -1;
    else if (c1.a < c2.a) return 1;
    else return 0;
  }
}
public void FFT(List<Complex> a){
  int n=a.size();
  int p = 0;
  for (int i = 0; i < n - 1; i++) {
    if (i < p) {
      Complex tmp = a.get(i);
      a.set(i, a.get(p));
      a.set(p, tmp);
    }
    int k = n >> 1;
    while (k <= p) {
      p -= k;
      k >>= 1;
    }
    p += k;
  }
  for(int len=2;len<=n;len<<=1){
    double ang=-2*3.1415926535897/len;
    Complex wlen=new Complex((float)cos((float)ang),(float)sin((float)ang));
    for(int i=0;i<n;i+=len){
      Complex w=new Complex(1,0);
      for(int j=0;j<len/2;j++){
        Complex u=a.get(i+j);
        Complex t=w.mul(a.get(i+j+len/2));
        a.set(i+j,u.add(t));
        a.set(i+j+len/2,u.sub(t));
        w=w.mul(wlen);
      }
    }
  }
}
List<Complex> resample(List<Complex> points, int m) {
  List<Complex> newPoints = new ArrayList();
  if (points == null || points.isEmpty()) return newPoints;
  if (points.size() == 1) {
    for(int i=0; i<m; i++) newPoints.add(points.get(0));
    return newPoints;
  }
  float[] dists = new float[points.size()];
  dists[0] = 0;
  for (int i = 1; i < points.size(); i++) {
    Complex p1 = points.get(i - 1);
    Complex p2 = points.get(i);
    float dx = p2.real - p1.real;
    float dy = p2.image - p1.image;
    dists[i] = dists[i - 1] + sqrt(dx * dx + dy * dy);
  }
  float totalLength = dists[dists.length - 1];
  if (totalLength < 1e-6) {
    for(int i=0; i<m; i++) newPoints.add(points.get(0));
    return newPoints;
  }
  newPoints.add(points.get(0));
  for (int i = 1; i < m; i++) {
    float targetDist = (totalLength * i) / (m - 1);
    int currentIdx = 0;
    if (targetDist >= totalLength) {
      newPoints.add(points.get(points.size() - 1));
      continue;
    }
    while (currentIdx < dists.length - 1 && dists[currentIdx + 1] < targetDist) {
      currentIdx++;
    }
    if (currentIdx < points.size() - 1) {
      float d1 = dists[currentIdx];
      float d2 = dists[currentIdx + 1];
      float alpha = (targetDist - d1) / (d2 - d1);
      Complex p1 = points.get(currentIdx);
      Complex p2 = points.get(currentIdx + 1);
      float newReal = p1.real + (p2.real - p1.real) * alpha;
      float newImg = p1.image + (p2.image - p1.image) * alpha;
      newPoints.add(new Complex(newReal, newImg));
    } else {
      newPoints.add(points.get(points.size() - 1));
    }
  }
  return newPoints;
}