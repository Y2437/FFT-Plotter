import java.util.LinkedList;
import java.util.List;
final int ERASE_RADIUS=0;
final int GRAD_BOUND=10000;
final int MAX_DIST=100;
//定义复数点数组
List<Complex> allPoints= new LinkedList();
List<Complex> sortedAllPoints= new LinkedList();
// List<List<Complex>> points=new LinkedList();

List<List<Complex>> sortedPoints=new LinkedList();
void setup(){
    //加载图片像素(不要我写这个函数真是太好了)
    PImage img= loadImage("../img/Tester3.jpg");
    img.loadPixels();
    img.resize(ceil(img.width/2), ceil(img.height/2));
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


    //使用破坏性爬虫方法重写,试图解决双层线问题
    //查找最大的梯度值,仅保留这个梯度值,其余清零
    for(int x = ERASE_RADIUS; x < img.width - ERASE_RADIUS - 1; x++){
        for(int y = ERASE_RADIUS; y < img.height - ERASE_RADIUS - 1; y++){
            if(gradientTable[x][y] > GRAD_BOUND){
                float maxVal = gradientTable[x][y];
                int peakX = x;
                int peakY = y;
                int searchR = ERASE_RADIUS; 
                for(int i = -searchR; i <= searchR; i++){
                    for(int j = -searchR; j <= searchR; j++){
                        if(x+i >= 0 && x+i < img.width && y+j >= 0 && y+j < img.height){
                             if(gradientTable[x+i][y+j] > maxVal){
                                 maxVal = gradientTable[x+i][y+j];
                                 peakX = x + i;
                                 peakY = y + j;
                             }
                        }
                    }
                }
                allPoints.add(new Complex(peakX, peakY));
                for(int p = peakX - ERASE_RADIUS; p <= peakX + ERASE_RADIUS; p++){
                    for(int q = peakY - ERASE_RADIUS; q <= peakY + ERASE_RADIUS; q++){
                        if(p >= 0 && p < img.width && q >= 0 && q < img.height){
                           gradientTable[p][q] = 0;
                        }
                    }
                }   
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
        List<Complex> sortedSubPoints=new LinkedList();
        sortedSubPoints.add(sortedAllPoints.get(i++));
        while(i<sortedAllPoints.size()&&sortedAllPoints.get(i).distSq(sortedSubPoints.get(sortedSubPoints.size()-1))<MAX_DIST){
            sortedSubPoints.add(sortedAllPoints.get(i++));
        }
        i--;
        if(sortedSubPoints.get(sortedSubPoints.size()-1).distSq(sortedSubPoints.get(0))<MAX_DIST){
            sortedSubPoints.add(sortedSubPoints.get(0));
        }
        if(sortedSubPoints.size()>10) sortedPoints.add(sortedSubPoints);
    }
}
int drawIndex=0;
int lineIndex=0;
void draw(){
    stroke(0);
    int speed = 80; 
    
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