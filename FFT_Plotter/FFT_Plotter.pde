import java.util.ArrayList;
import java.util.List;

//定义复数点数组
List<Complex> points=new ArrayList();
void setup(){
    smooth(8);
    //加载图片像素(不要我写这个函数真是太好了)
    PImage img= loadImage("../img/Tester2.jpg");
    img.loadPixels();
    // size(img.width,img.height);
    surface.setSize(img.width, img.height);
    float [][] grayTable=new float [img.width][img.height];

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
            
            if(Gx*Gx+Gy*Gy>100000){
                points.add(new Complex(x,y));
            }
        }
    }

}

void draw(){
    background(255);
    stroke(0,100);
    for(int i=0;i<points.size();i++){
        point(points.get(i).real,points.get(i).image);
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
}