import java.util.LinkedList;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Comparator;

final int ERASE_RADIUS=0;
final int GRAD_BOUND=20000;
final int MAX_DIST=40;
final int MIN_POINT_NUM=20;
final float drawSpeed = 0.01;
PImage img;
//定义复数点数组
List<Complex> allPoints= new LinkedList();
List<Complex> sortedAllPoints= new LinkedList();
// List<List<Complex>> points=new LinkedList();
List<List<Complex>> sortedPoints=new ArrayList();
List<List<Circle>> circleList= new LinkedList();
void setup(){
    size(500,500, P2D);
    smooth(32);

    pixelDensity(displayDensity());
    //加载图片像素(不要我写这个函数真是太好了)
    img= loadImage("../img/Tester4.jpg");
    img.loadPixels();
    img.resize(ceil(img.width), ceil(img.height));

    // size(img.width,img.height);
    surface.setSize(img.width, img.height);


    float [][] grayTable=new float [img.width][img.height];
    float [][] gradientTable=new float [img.width][img.height];

    //二值化
    for(int x=0;x<img.width;x++){
        for(int y=0;y<img.height;y++){
            int index=x+y*img.width;
            color c=img.pixels[index];
            // 0.299R + 0.587G + 0.114B
            grayTable[x][y]=red(c)*0.299+green(c)*0.587+blue(c)*0.114;
        }
    }


    //卷积核定义
    int [][] sobelX={
        {-1,0,1},
        {-2,0,2},
        {-1,0,1}
    };
    int [][] sobelY={
        {-1,-2,-1},
        {0,0,0},
        {1,2,1}
    };
    

    //卷积提取边缘
    for(int x=1;x<img.width-1;x++){
        for(int y=1;y<img.height-1;y++){
            float Gx=0;
            float Gy=0;
            for(int p=x-1;p<=x+1;p++){
                for(int q=y-1;q<=y+1;q++){
                    Gx+=sobelX[p-(x-1)][q-(y-1)]*grayTable[p][q];
                    Gy+=sobelY[p-(x-1)][q-(y-1)]*grayTable[p][q];
                }
            }   
            gradientTable[x][y]=Gx*Gx+Gy*Gy;
        }
    }
    // //池化防止双层线
    // for(int x=0;x<img.width-poolSize;x+=poolSize){
    //     for(int y=1;y<img.height-poolSize;y+=poolSize){
    //         float G=0;
    //         for(int p=x;p<x+poolSize;p++){
    //             for(int q=y;q<y+poolSize;q++){
    //                 G=max(G,gradientTable[p][q]);
    //             }
    //         }   
    //         pooledTable[x/poolSize][y/poolSize]=G;
    //     }
    // }
    // //此处可简化(但是为了清晰性保留)(反正只是乘常数)
    // for(int i=0;i<img.width/poolSize;i++){
    //     for(int j=0;j<img.height/poolSize;j++){
    //         if(pooledTable[i][j]>100000) points.add(new Complex(i,j));
    //     }
    // }


    // //使用破坏性爬虫方法重写,试图解决双层线问题
    // //查找最大的梯度值,仅保留这个梯度值,其余清零
    // for(int x = ERASE_RADIUS; x < img.width - ERASE_RADIUS - 1; x++){
    //     for(int y = ERASE_RADIUS; y < img.height - ERASE_RADIUS - 1; y++){
    //         if(gradientTable[x][y] > GRAD_BOUND){
    //             float maxVal = gradientTable[x][y];
    //             int peakX = x;
    //             int peakY = y;
    //             int searchR = ERASE_RADIUS; 
    //             for(int i = -searchR; i <= searchR; i++){
    //                 for(int j = -searchR; j <= searchR; j++){
    //                     if(x+i >= 0 && x+i < img.width && y+j >= 0 && y+j < img.height){
    //                          if(gradientTable[x+i][y+j] > maxVal){
    //                              maxVal = gradientTable[x+i][y+j];
    //                              peakX = x + i;
    //                              peakY = y + j;
    //                          }
    //                     }
    //                 }
    //             }
    //             allPoints.add(new Complex(peakX-img.width/2, peakY-height/2));
    //             for(int p = peakX - ERASE_RADIUS; p <= peakX + ERASE_RADIUS; p++){
    //                 for(int q = peakY - ERASE_RADIUS; q <= peakY + ERASE_RADIUS; q++){
    //                     if(p >= 0 && p < img.width && q >= 0 && q < img.height){
    //                        gradientTable[p][q] = 0;
    //                     }
    //                 }
    //             }   
    //         }
    //     }
    // }
    int[][] binaryMap = new int[img.width][img.height];
    for (int x = 0; x < img.width; x++) {
        for (int y = 0; y < img.height; y++) {
            if (gradientTable[x][y] > GRAD_BOUND) {
                binaryMap[x][y] = 1;
            } else {
                binaryMap[x][y] = 0;
            }
        }
    }
    int[] dx = {0, 1, 1, 1, 0, -1, -1, -1};
    int[] dy = {-1, -1, 0, 1, 1, 1, 0, -1};
    boolean isChanged = true;
    List<Integer> pointsToDelete = new ArrayList<Integer>();

    while (isChanged) {
        isChanged = false;
        
        // --- 子迭代 1 ---
        // 删除满足条件 A, B, C1, D1 的像素
        pointsToDelete.clear();
        for (int x = 1; x < img.width - 1; x++) {
            for (int y = 1; y < img.height - 1; y++) {
                if (binaryMap[x][y] == 0) continue;

                // 获取8邻域像素值
                int p2 = binaryMap[x + dx[0]][y + dy[0]];
                int p3 = binaryMap[x + dx[1]][y + dy[1]];
                int p4 = binaryMap[x + dx[2]][y + dy[2]];
                int p5 = binaryMap[x + dx[3]][y + dy[3]];
                int p6 = binaryMap[x + dx[4]][y + dy[4]];
                int p7 = binaryMap[x + dx[5]][y + dy[5]];
                int p8 = binaryMap[x + dx[6]][y + dy[6]];
                int p9 = binaryMap[x + dx[7]][y + dy[7]];

                // 条件A：2 <= B(P1) <= 6，其中 B(P1) 是非零邻居的数量
                int B = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9;
                if (B < 2 || B > 6) continue;

                // 条件B：A(P1) = 1，其中 A(P1) 是邻域序列中 0->1 的跳变次数
                // 序列顺序 P2, P3, P4, P5, P6, P7, P8, P9, P2
                int A = 0;
                if (p2 == 0 && p3 == 1) A++;
                if (p3 == 0 && p4 == 1) A++;
                if (p4 == 0 && p5 == 1) A++;
                if (p5 == 0 && p6 == 1) A++;
                if (p6 == 0 && p7 == 1) A++;
                if (p7 == 0 && p8 == 1) A++;
                if (p8 == 0 && p9 == 1) A++;
                if (p9 == 0 && p2 == 1) A++;
                if (A != 1) continue;
                if (p2 * p4 * p6 != 0) continue;
                if (p4 * p6 * p8 != 0) continue;
                pointsToDelete.add(x + y * img.width);
            }
        }
        if (!pointsToDelete.isEmpty()) {
            isChanged = true;
            for (Integer idx : pointsToDelete) {
                binaryMap[idx % img.width][idx / img.width] = 0;
            }
        }
        pointsToDelete.clear();
        for (int x = 1; x < img.width - 1; x++) {
            for (int y = 1; y < img.height - 1; y++) {
                if (binaryMap[x][y] == 0) continue;

                int p2 = binaryMap[x + dx[0]][y + dy[0]];
                int p3 = binaryMap[x + dx[1]][y + dy[1]];
                int p4 = binaryMap[x + dx[2]][y + dy[2]];
                int p5 = binaryMap[x + dx[3]][y + dy[3]];
                int p6 = binaryMap[x + dx[4]][y + dy[4]];
                int p7 = binaryMap[x + dx[5]][y + dy[5]];
                int p8 = binaryMap[x + dx[6]][y + dy[6]];
                int p9 = binaryMap[x + dx[7]][y + dy[7]];

                int B = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9;
                if (B < 2 || B > 6) continue;

                int A = 0;
                if (p2 == 0 && p3 == 1) A++;
                if (p3 == 0 && p4 == 1) A++;
                if (p4 == 0 && p5 == 1) A++;
                if (p5 == 0 && p6 == 1) A++;
                if (p6 == 0 && p7 == 1) A++;
                if (p7 == 0 && p8 == 1) A++;
                if (p8 == 0 && p9 == 1) A++;
                if (p9 == 0 && p2 == 1) A++;
                if (A != 1) continue;
                if (p2 * p4 * p8 != 0) continue;
                if (p2 * p6 * p8 != 0) continue;

                pointsToDelete.add(x + y * img.width);
            }
        }
        if (!pointsToDelete.isEmpty()) {
            isChanged = true;
            for (Integer idx : pointsToDelete) {
                binaryMap[idx % img.width][idx / img.width] = 0;
            }
        }
    }

    for (int x = 1; x < img.width - 1; x++) {
        for (int y = 1; y < img.height - 1; y++) {
            if (binaryMap[x][y] == 1) {
                // 保持原有的坐标中心化变换逻辑
                allPoints.add(new Complex(x - img.width / 2, y - height / 2));
            }
        }
    }
    print(allPoints.size());
    sortedAllPoints.add(allPoints.get(0));
    allPoints.remove(0);   
    //接下来是这个最短临近距离排序
    //这里是O(N^2) 没一点办法
    while(!allPoints.isEmpty()){
        float minDis=Float.MAX_VALUE;
        Complex tmp=allPoints.get(0);
        for(Complex p: allPoints){
            float dis=sortedAllPoints.get(sortedAllPoints.size()-1).distSq(p);
            if(dis<minDis){
                tmp=p;
                minDis=dis;
            }
        } 
        allPoints.remove(tmp);
        sortedAllPoints.add(tmp);
    }

    print(allPoints.size());
    //接下来是为了防止联通不同图像的切分
    for(int i=0;i<sortedAllPoints.size();i++){
        List<Complex> sortedSubPoints=new ArrayList();
        sortedSubPoints.add(sortedAllPoints.get(i++));
        while(i<sortedAllPoints.size()&&sortedAllPoints.get(i).distSq(sortedSubPoints.get(sortedSubPoints.size()-1))<MAX_DIST){
            sortedSubPoints.add(sortedAllPoints.get(i++));
        }
        i--;
        if(sortedSubPoints.size()>MIN_POINT_NUM) sortedPoints.add(sortedSubPoints);
    }


    // //接下来是重新的间隔采样
    // for(int i=0;i<sortedPoints.size();i++){
    //     int target=sortedPoints.get(i).size();
    //     int tmp=1;
    //     while(tmp<target) tmp<<=1;
    //     tmp>>=1;
    //     sortedPoints.set(i,resample(sortedPoints.get(i),512));
    //     // 然后就是这个FFT了
    //     FFT(sortedPoints.get(i));
    // }


    // //然后注册旋转圆并排序
    // for(int i=0;i<sortedPoints.size();i++){
    //     List<Circle> subCircleList=new ArrayList();
    //     for(int j=0;j<sortedPoints.get(i).size();j++){
    //         if(sqrt(sortedPoints.get(i).get(j).real*sortedPoints.get(i).get(j).real+sortedPoints.get(i).get(j).image*sortedPoints.get(i).get(j).image)/sortedPoints.get(i).size()>0.01) subCircleList.add(new Circle(j,sortedPoints.get(i).get(j),sortedPoints.get(i).size()));
    //     }
    //     Collections.sort(subCircleList, new AmplitudeComparator());
    //     circleList.add(subCircleList); 
    // }
}
int drawIndex=0;
int lineIndex=0;
void draw(){
    strokeWeight(3);
    noFill();
    strokeJoin(ROUND);
    strokeCap(ROUND);
    stroke(0);
    int speed = 30; 
    translate(img.width/2, img.height/2);
    for (int k = 0; k < speed; k++) {
        if(lineIndex==sortedPoints.size()) break;
        if (drawIndex < sortedPoints.get(lineIndex).size() - 1) {
            Complex p1 = sortedPoints.get(lineIndex).get(drawIndex);
            Complex p2 = sortedPoints.get(lineIndex).get(drawIndex+1);
            line((float)p1.real, (float)p1.image, (float)p2.real, (float)p2.image);
            drawIndex++;
            if(lineIndex<sortedPoints.size()&&drawIndex==sortedPoints.get(lineIndex).size()-1){
                drawIndex=0;
                lineIndex++;
                if(lineIndex==sortedPoints.size()) break;
            }
            if(lineIndex==sortedPoints.size()) break;
        }
    }
}

// int currentShapeIndex = 0;         // 当前画到了第几个图形
// float time = 0;                    // 当前图形的时间进度 (0 ~ 2PI)
// List<List<PVector>> finishedTrails = new ArrayList(); // 存已经画好的轨迹
// List<PVector> currentTrail = new ArrayList();         // 存当前正在画的轨迹

// void draw() {
//     translate(img.width/2, img.height/2);
//     background(20); 
//     strokeWeight(4);
//     noFill();
//     strokeJoin(ROUND);
//     strokeCap(ROUND);
//     stroke(0, 255, 255); 
    
//     // 绘制所有已完成的轨迹
//     for (List<PVector> trail : finishedTrails) {
//         beginShape();
//         for (PVector p : trail) {
//             vertex(p.x, p.y);
//         }
//         endShape();
//     }
    
//     // 加速逻辑：每帧计算多次更新
//     int stepsPerFrame = 4; // 这里的数值决定加速倍率，20表示比原来快20倍
    
//     for (int k = 0; k < stepsPerFrame; k++) {
//         if (currentShapeIndex >= circleList.size()) break;

//         List<Circle> circles = circleList.get(currentShapeIndex);
//         float x = 0;
//         float y = 0;
        
//         // 纯计算逻辑，不进行绘制
//         for(int i = 0; i < circles.size(); i++){
//             Circle c = circles.get(i);
//             c.theta = c.p + c.f * time; 
//             x += (float)(c.a * cos((float)c.theta));
//             y += (float)(c.a * sin((float)c.theta));
//         }
        
//         // 添加点到当前轨迹
//         currentTrail.add(new PVector(x, y));
        
//         // 更新时间
//         time += drawSpeed;
        
//         // 检查当前图形是否绘制完毕
//         if (time >= TWO_PI) {
//             finishedTrails.add(new ArrayList(currentTrail));
//             currentTrail.clear();
//             time = 0;
//             currentShapeIndex++;
//         }
//     }

//     // 绘制当前时刻的圆和线（仅在最后一帧状态下绘制一次，节省开销）
//     strokeWeight(1);
//     if (currentShapeIndex < circleList.size()) {
//         List<Circle> circles = circleList.get(currentShapeIndex);
//         float x = 0;
//         float y = 0;
//         for(int i = 0; i < circles.size(); i++){
//             Circle c = circles.get(i);
//             float prevX = x;
//             float prevY = y;
//             // 重新计算当前显示时刻的坐标以用于绘图

//             c.theta = c.p + c.f * time; 
//             x += (float)(c.a * cos((float)c.theta));
//             y += (float)(c.a * sin((float)c.theta));
//             stroke(255, 255, 51); 
//             ellipse(prevX, prevY, (float)c.a*2, (float)c.a*2);
//             stroke(255, 255, 255); 
//             line(prevX, prevY, x, y);      

//         }
        
//         // 绘制当前正在生成的轨迹片段
//         strokeWeight(4);
//         stroke(0, 255, 255);
//         beginShape();
//         for (PVector p : currentTrail) {
//             vertex(p.x, p.y);
//         }
//         endShape();
//     }
// }
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
                Complex v=a.get(i+j+len/2).mul(w);
                a.set(i+j,u.add(v));
                a.set(i+j+len/2,u.sub(v));
                w=w.mul(wlen);
            }
        }
    }
}

List<Complex> resample(List<Complex> points, int m) {
    List<Complex> newPoints = new LinkedList<Complex>();
    if (points == null || points.isEmpty()) return newPoints;
    if (points.size() == 1) {
        for(int i=0; i<m; i++) newPoints.add(points.get(0));
        return newPoints;
    }
    float[] dists = new float[points.size()];
    dists[0] = 0;
    float totalLength = 0;
    for (int i = 1; i < points.size(); i++) {
        Complex p1 = points.get(i - 1);
        Complex p2 = points.get(i);
        float d = sqrt(p1.distSq(p2)); 
        totalLength += d;
        dists[i] = totalLength;
    }
    float step = totalLength / (float) m;
    int currentIdx = 0; 
    for (int k = 0; k < m; k++) {
        float targetDist = k * step;
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
            float newImg  = p1.image + (p2.image - p1.image) * alpha;
            
            newPoints.add(new Complex(newReal, newImg));
        } else {
            newPoints.add(points.get(points.size() - 1));
        }
    }
    return newPoints;
}