import java.util.LinkedList;
import java.util.List;


final int poolSize=5;
//定义复数点数组
List<Complex> points=new LinkedList();
List<Complex> sortedPoints=new LinkedList();
void setup(){
    //加载图片像素(不要我写这个函数真是太好了)
    PImage img= loadImage("../img/Tester2.jpg");
    img.loadPixels();
    // size(img.width,img.height);
    surface.setSize(img.width/poolSize, img.height/poolSize);


    float [][] grayTable=new float [img.width][img.height];
    float [][] gradientTable=new float [img.width][img.height];
    float [][] pooledTable=new float [img.width/poolSize+5][img.height/poolSize+5];
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
    //池化防止双层线
    for(int x=0;x<img.width-poolSize;x+=poolSize){
        for(int y=1;y<img.height-poolSize;y+=poolSize){
            float G=0;
            for(int p=x;p<x+poolSize;p++){
                for(int q=y;q<y+poolSize;q++){
                    G=max(G,gradientTable[p][q]);
                }
            }   
            pooledTable[x/poolSize][y/poolSize]=G;
        }
    }
    //此处可简化(但是为了清晰性保留)(反正只是乘常数)
    for(int i=0;i<img.width/poolSize;i++){
        for(int j=0;j<img.height/poolSize;j++){
            if(pooledTable[i][j]>100000) points.add(new Complex(i,j));
        }
    }


    print(points.size());
    sortedPoints.add(points.get(0));
    points.remove(0);   
    //接下来是这个最短临近距离排序
    //这里是O(N^2) 没一点办法
    while(!points.isEmpty()){
        float minDis=Float.MAX_VALUE;
        Complex tmp=points.get(0);
        for(Complex p: points){
            float dis=sortedPoints.get(sortedPoints.size()-1).distSq(p);
            if(dis<minDis){
                tmp=p;
                minDis=dis;
            }
        }
        points.remove(tmp);
        sortedPoints.add(tmp);
    }

}
int drawIndex = 0;
void draw(){
    stroke(0);
    int speed = 10; 
    
    for (int k = 0; k < speed; k++) {
        if (drawIndex < sortedPoints.size() - 1) {
            Complex p1 = sortedPoints.get(drawIndex);
            Complex p2 = sortedPoints.get(drawIndex + 1);
            
            line((float)p1.real, (float)p1.image, (float)p2.real, (float)p2.image);
            
            drawIndex++;
        }
    }
}


class Complex{
    private float real;
    private float image;
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