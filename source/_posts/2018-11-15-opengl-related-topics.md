---
title: opengl学习笔记
date: 2018-11-15 22:53:55
tags: [opengl]
---

topics relating opengl stuff
![](https://api1.reindeer36.shop/static/imgs/scenery151110074347.jpg)

<!--more-->
[本文多数代码来自这个系列](https://github.com/doggycoder/AndroidOpenGLDemo)

首先，[不要学旧的版本](https://medium.com/@wrongway4you/opengl-learning-in-2018-d556d96d7e7)。
It is much better to start from the “modern” OpenGL versions: Learn OpenGL >3.0.

opengl device support on android

* OpenGL ES 1.0 & 1.1 since Android 1.0 (API 4)
* OpenGL ES 2.0 since Android 2.2 (API 8)
* OpenGL ES 3.0 since Android 4.3 (API 18) (almost)
* OpenGL ES 3.1 since Android 5.0 (API 21)

OpenGL ES is a variant of OpenGL’s specifications for embedded system. 
> Graphics progamming for OpenGL ES 2.0 and 3.0 is largely similar, with version 3.0 representing a superset of the 2.0 API with additional features. Programming for the OpenGL ES 1.0/1.1 API versus OpenGL ES 2.0 and 3.0 differs significantly(2.0和3.0的语法差不多，3.0就是加了点特性。1.0和他俩的语法不同，不要学)
总的来讲，2.0和3.0要比1.0的性能好，能够对硬件有更自由的掌控（the API provides a great deal of control over the graphics rendering pipeline.），但是语法要复杂些。


## Android提供了很多用于和OPENGL环境交互的class
开发者使用java环境  -> 描述绘制图形 -> graphics rendering pipeline
最简单的View是GLSurfaceView，实现渲染的逻辑在GLSurfaceView.Renderer中。如果想要只在view的布局一部分中使用gl功能的请使用TextureView，For real, do-it-yourself developers, it is also possible to build up an OpenGL ES view using SurfaceView, but this requires writing quite a bit of additional code。

GLSurfaceView.Renderer
```java
    public interface Renderer {
        void onSurfaceCreated(GL10 gl, EGLConfig config);
        void onSurfaceChanged(GL10 gl, int width, int height);
        void onDrawFrame(GL10 gl);
    }
```
render就这么三个方法，这三个方法都在一条叫做GLThread的线程上被调用

## 检查当前设备的opengles版本:
在GLSurfaceView.Renderer的onSurfaceCreated中添加
```java
// Create a minimum supported OpenGL ES context, then check:
String version = gl.glGetString(GL10.GL_VERSION);
Log.w(TAG, "Version: " + version );
// The version format is displayed as: "OpenGL ES <major>.<minor>"
// followed by optional content provided by the implementation.
```
我在一台5.1的设备上打印出来的是"OpenGL ES 3.1"这么几个字。

## 坐标系
> By default, OpenGL ES assumes a coordinate system where [0,0,0] (X,Y,Z) specifies the center of the GLSurfaceView frame, [1,1,0] is the top right corner of the frame and [-1,-1,0] is bottom left corner of the frame
opengl使用三维坐标系，右手坐标，屏幕中心为原点，z轴垂直于屏幕，往上是正数。屏幕中心往右走是x轴正轴，屏幕中心往上走是y轴正轴。



## culling
（就是告诉opengl完全忽略掉背面，不要浪费时间去渲染看不见的地方）
Face culling is an option for the OpenGL environment which allows the rendering pipeline to ignore (not calculate or draw) the back face of a shape, saving time, memory and processing cycles:（好处就是节省时间和运算量）
比方说完全忽略掉背面
```java
// enable face culling feature
gl.glEnable(GL10.GL_CULL_FACE);
// specify which faces to not draw
gl.glCullFace(GL10.GL_BACK);
```
还有，默认的作图顺序是**逆时针**的


## Texture compression
能够极大的节约内存，并充分利用内存带宽提升性能
包括这么几个:
ETC1 compression format(但不支持有alpha channel，就是带透明度的)
The ETC2/EAC texture compression formats (支持带alpha channel)

查看当前设备支持的OpenGL extensions(entension就是标准之外的，部分厂商硬件支持的特性)
```java
 // Get the list of extensions.
        String extensionList = GLES10.glGetString(GLES10.GL_EXTENSIONS);
        if (!TextUtils.isEmpty(extensionList)) {
            // The list of extensions comes from the driver separated by spaces.
            // Split them apart and add them into a Set for deduping purposes.
            for (String extension : extensionList.split(" ")) {
                glExtensions.add(extension);
            }
        }
```

[OpenGL ES 2.0过程及理解](https://blog.csdn.net/junzia/article/details/52793354 )
OpenGL ES 2.0渲染过程为： 
读取顶点数据——执行顶点着色器——组装图元——光栅化图元——执行片元着色器——写入帧缓冲区——显示到屏幕上。
OpenGL作为本地库直接运行在硬件上，没有虚拟机，也没有垃圾回收或者内存压缩。在Java层定义图像的数据需要能被OpenGL存取，因此，需要把内存从Java堆复制到本地堆。
顶点着色器是针对每个顶点都会执行的程序，是确定每个顶点的位置。同理，片元着色器是针对每个片元都会执行的程序，确定每个片元的颜色。
着色器需要进行编译，然后链接到OpenGL程序中。一个OpenGL的程序就是把一个顶点着色器和一个片段着色器链接在一起变成单个对象。


### 定义shape
点，线，三角形，这三个是opengl的图形基础，其他任何集合图形都可以用三角形拼凑出来。
[根据官方文档](https://developer.android.com/training/graphics/opengl/shapes)，开发者需要往opengl传一个float的array作为要绘制的对象的坐标，在java里用ArrayBuffer比较好(这部分内存是传到硬件层的)。
官方文档上这样定义了一个三角形
```java
public class Triangle {

    private FloatBuffer vertexBuffer;

    // number of coordinates per vertex in this array
    static final int COORDS_PER_VERTEX = 3;
    static float triangleCoords[] = {   // in counterclockwise order:
             0.0f,  0.622008459f, 0.0f, // top
            -0.5f, -0.311004243f, 0.0f, // bottom left
             0.5f, -0.311004243f, 0.0f  // bottom right
    }; //逆时针走向

    // Set color with red, green, blue and alpha (opacity) values
    float color[] = { 0.63671875f, 0.76953125f, 0.22265625f, 1.0f };

    public Triangle() {
        // initialize vertex byte buffer for shape coordinates
        ByteBuffer bb = ByteBuffer.allocateDirect(
                // (number of coordinate values * 4 bytes per float)
                triangleCoords.length * 4);
        // use the device hardware's native byte order
        bb.order(ByteOrder.nativeOrder()); //字节序

        // create a floating point buffer from the ByteBuffer
        vertexBuffer = bb.asFloatBuffer();
        // add the coordinates to the FloatBuffer
        vertexBuffer.put(triangleCoords);
        // set the buffer to read the first coordinate
        vertexBuffer.position(0);
    }
}
```

正方形就可以由两个三角形拼在一起组成
```java
public class Square {

    private FloatBuffer vertexBuffer;
    private ShortBuffer drawListBuffer;

    // number of coordinates per vertex in this array
    static final int COORDS_PER_VERTEX = 3;
    static float squareCoords[] = {
            -0.5f,  0.5f, 0.0f,   // top left
            -0.5f, -0.5f, 0.0f,   // bottom left
             0.5f, -0.5f, 0.0f,   // bottom right
             0.5f,  0.5f, 0.0f }; // top right

    private short drawOrder[] = { 0, 1, 2, 0, 2, 3 }; // order to draw vertices

    public Square() {
        // initialize vertex byte buffer for shape coordinates
        ByteBuffer bb = ByteBuffer.allocateDirect(
        // (# of coordinate values * 4 bytes per float)
                squareCoords.length * 4);
        bb.order(ByteOrder.nativeOrder());
        vertexBuffer = bb.asFloatBuffer();
        vertexBuffer.put(squareCoords);
        vertexBuffer.position(0);

        // initialize byte buffer for the draw list
        ByteBuffer dlb = ByteBuffer.allocateDirect(
        // (# of coordinate values * 2 bytes per short)
                drawOrder.length * 2);
        dlb.order(ByteOrder.nativeOrder());
        drawListBuffer = dlb.asShortBuffer();
        drawListBuffer.put(drawOrder);
        drawListBuffer.position(0);
    }
}
```

### 绘制定义的shape
首先在onSurfaceCreated里面创建要绘制的shape对象
```java
   private Triangle mTriangle;
    private Square   mSquare;

    public void onSurfaceCreated(GL10 unused, EGLConfig config) {
        ...
        // initialize a triangle
        mTriangle = new Triangle();
        // initialize a square
        mSquare = new Square();
    }
```

接下来就是比较麻烦的地方了，必须要定义这几样东西
- Vertex Shader - OpenGL ES graphics code for rendering the vertices of a shape.（顶点着色器）
- Fragment Shader - OpenGL ES code for rendering the face of a shape with colors or textures.(片元着色器)
- Program - An OpenGL ES object that contains the shaders you want to use for drawing one or more shapes.

至少需要一个vertex shader去画shape，一个fragment shader去画shape的颜色，这俩被编译并添加到opengles program中，后者将被用来画这个shape

```java
public class Triangle {
    
    private final String vertexShaderCode =
        "attribute vec4 vPosition;" +
        "void main() {" +
        "  gl_Position = vPosition;" +
        "}";

    private final String fragmentShaderCode =
        "precision mediump float;" +
        "uniform vec4 vColor;" +
        "void main() {" +
        "  gl_FragColor = vColor;" +
        "}";

    ...
}

public static int loadShader(int type, String shaderCode){

    // create a vertex shader type (GLES20.GL_VERTEX_SHADER)
    // or a fragment shader type (GLES20.GL_FRAGMENT_SHADER)
    int shader = GLES20.glCreateShader(type);

    // add the source code to the shader and compile it
    GLES20.glShaderSource(shader, shaderCode);
    GLES20.glCompileShader(shader); //编译shader并link program很耗费cpu，所以只要做一次，一般放在shape的构造函数里面

    return shader;
}
```

所以最后Triangle的代码变成这样
```js
// number of coordinates per vertex in this array
const val COORDS_PER_VERTEX = 3
var triangleCoords = floatArrayOf(     // in counterclockwise order:
    0.0f, 0.622008459f, 0.0f,      // top
    -0.5f, -0.311004243f, 0.0f,    // bottom left
    0.5f, -0.311004243f, 0.0f      // bottom right
)

class Triangle {

    // Set color with red, green, blue and alpha (opacity) values
    val color = floatArrayOf(0.63671875f, 0.76953125f, 0.22265625f, 1.0f)

    private var vertexBuffer: FloatBuffer =
    // (number of coordinate values * 4 bytes per float)
        ByteBuffer.allocateDirect(triangleCoords.size * 4).run {
            // use the device hardware's native byte order
            order(ByteOrder.nativeOrder())

            // create a floating point buffer from the ByteBuffer
            asFloatBuffer().apply {
                // add the coordinates to the FloatBuffer
                put(triangleCoords)
                // set the buffer to read the first coordinate
                position(0)
            }
        }


    private var mProgram: Int

    private val vertexShaderCode =
        "attribute vec4 vPosition;" +
                "void main() {" +
                "  gl_Position = vPosition;" +
                "}"

    private val fragmentShaderCode =
        "precision mediump float;" +
                "uniform vec4 vColor;" +
                "void main() {" +
                "  gl_FragColor = vColor;" +
                "}"

    private val vertexCount: Int = triangleCoords.size / COORDS_PER_VERTEX
    private val vertexStride: Int = COORDS_PER_VERTEX * 4 // 4 bytes per vertex
    init {

        val vertexShader: Int = loadShader(GLES20.GL_VERTEX_SHADER, vertexShaderCode)
        val fragmentShader: Int = loadShader(GLES20.GL_FRAGMENT_SHADER, fragmentShaderCode)

        // create empty OpenGL ES Program
        mProgram = GLES20.glCreateProgram().also {

            // add the vertex shader to program
            GLES20.glAttachShader(it, vertexShader)

            // add the fragment shader to program
            GLES20.glAttachShader(it, fragmentShader)

            // creates OpenGL ES program executables
            GLES20.glLinkProgram(it)
        }
    }


    private var mPositionHandle: Int = 0
    private var mColorHandle: Int = 0

    fun loadShader(type: Int, shaderCode: String): Int {

        // create a vertex shader type (GLES20.GL_VERTEX_SHADER)
        // or a fragment shader type (GLES20.GL_FRAGMENT_SHADER)
        return GLES20.glCreateShader(type).also { shader ->

            // add the source code to the shader and compile it
            GLES20.glShaderSource(shader, shaderCode)
            GLES20.glCompileShader(shader)
        }
    }

    fun draw() {
        // Add program to OpenGL ES environment
        GLES20.glUseProgram(mProgram)

        // get handle to vertex shader's vPosition member
        mPositionHandle = GLES20.glGetAttribLocation(mProgram, "vPosition").also {

            // Enable a handle to the triangle vertices
            GLES20.glEnableVertexAttribArray(it)

            // Prepare the triangle coordinate data
            GLES20.glVertexAttribPointer(
                it,
                COORDS_PER_VERTEX,
                GLES20.GL_FLOAT,
                false,
                vertexStride,
                vertexBuffer
            )

            // get handle to fragment shader's vColor member
            mColorHandle = GLES20.glGetUniformLocation(mProgram, "vColor").also { colorHandle ->

                // Set color for drawing the triangle
                GLES20.glUniform4fv(colorHandle, 1, color, 0)
            }

            // Draw the triangle
            GLES20.glDrawArrays(GLES20.GL_TRIANGLES, 0, vertexCount)

            // Disable vertex array
            GLES20.glDisableVertexAttribArray(it)
        }
    }
}
```

### 接下来是 Apply projection and camera views
Projection 就是根据设备的实际屏幕尺寸调节绘制坐标
Camera View 就是根据一个假想的camera视角调节坐标


### 着色器语言GLSL
写到这里，基本的流程就是在onSurfaceCreated中去loadShader，而shaderCode一般是这样的。
```s
uniform mat4 vMatrix;
varying vec4 vColor;
attribute vec4 vPosition;

void main(){
    gl_Position=vMatrix*vPosition;
    if(vPosition.z!=0.0){
        vColor=vec4(0.0,0.0,0.0,1.0);
    }else{
        vColor=vec4(0.9,0.9,0.9,1.0);
    }
}
```

这是一门高级的图形化编程语言，其源于应用广泛的C语言，主要特性包括:
- GLSL是一种面向过程的语言，和Java的面向对象是不同的。
- GLSL的基本语法与C/C++基本相同。
- 它完美的支持向量和矩阵操作。
- 它是通过限定符操作来管理输入输出类型的。
- GLSL提供了大量的内置函数来提供丰富的扩展功能。

### 顶点着色器的内建变量
gl_Position：顶点坐标
gl_PointSize：点的大小，没有赋值则为默认值1，通常设置绘图为点绘制才有意义。

### 片元着色器的内建变量
输入变量
gl_FragCoord：当前片元相对窗口位置所处的坐标。
gl_FragFacing：bool型，表示是否为属于光栅化生成此片元的对应图元的正面。
输出变量
gl_FragColor：当前片元颜色
gl_FragData：vec4类型的数组。向其写入的信息，供渲染管线的后继过程使用。


### 内置函数:
纹理采样函数
纹理采样函数有texture2D、texture2DProj、texture2DLod、texture2DProjLod、textureCube、textureCubeLod及texture3D、texture3DProj、texture3DLod、texture3DProjLod等。

向量在GPU中由硬件支持运算，比CPU快的多。
[总的来说这门语言要比其他编程语言简单些](https://blog.csdn.net/junzia/article/details/52830604)



### 用OpenGL ES显示图片
纹理(texture):
在理解纹理映射时，可以将纹理看做应用在物体表面的像素颜色。在真实世界中，纹理表示一个对象的颜色、图案以及触觉特征。纹理只表示对象表面的彩色图案，它不能改变对象的几何形式。更进一步的说，它只是一种高强度的计算行为。

比如一张矩形的图片是由两个三角形拼起来的，左下 -> 左上 -> 右下 -> 右上 的顺序就能得到图片的纹理
下面这段代码也不是很懂，照着注释看吧
```java
  @Override
    public void onDrawFrame(GL10 gl) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT|GLES20.GL_DEPTH_BUFFER_BIT);
        GLES20.glUseProgram(mProgram);
        onDrawSet(); // 在这里添加模糊，暖色调，冷色调等滤镜效果
        GLES20.glUniform1i(hIsHalf,isHalf?1:0);
        GLES20.glUniform1f(glHUxy,uXY);
        GLES20.glUniformMatrix4fv(glHMatrix,1,false,mMVPMatrix,0);
        GLES20.glEnableVertexAttribArray(glHPosition);
        GLES20.glEnableVertexAttribArray(glHCoordinate);
        GLES20.glUniform1i(glHTexture, 0);
        textureId=createTexture();
        GLES20.glVertexAttribPointer(glHPosition,2,GLES20.GL_FLOAT,false,0,bPos);
        GLES20.glVertexAttribPointer(glHCoordinate,2,GLES20.GL_FLOAT,false,0,bCoord);
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP,0,4);
    }

    public abstract void onDrawSet();
    public abstract void onDrawCreatedSet(int mProgram);

    private int createTexture(){
        int[] texture=new int[1];
        if(mBitmap!=null&&!mBitmap.isRecycled()){
            //生成纹理
            GLES20.glGenTextures(1,texture,0);
            //生成纹理
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D,texture[0]);
            //设置缩小过滤为使用纹理中坐标最接近的一个像素的颜色作为需要绘制的像素颜色
            GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER,GLES20.GL_NEAREST);
            //设置放大过滤为使用纹理中坐标最接近的若干个颜色，通过加权平均算法得到需要绘制的像素颜色
            GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D,GLES20.GL_TEXTURE_MAG_FILTER,GLES20.GL_LINEAR);
            //设置环绕方向S，截取纹理坐标到[1/2n,1-1/2n]。将导致永远不会与border融合
            GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_S,GLES20.GL_CLAMP_TO_EDGE);
            //设置环绕方向T，截取纹理坐标到[1/2n,1-1/2n]。将导致永远不会与border融合
            GLES20.glTexParameterf(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_WRAP_T,GLES20.GL_CLAMP_TO_EDGE);
            //根据以上指定的参数，生成一个2D纹理
            GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, mBitmap, 0); 
            return texture[0];
        }
        return 0;
    }
```
显示图片的关键代码:
GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, mBitmap, 0);

滤镜这些特效本质上是在onDrawFrame里面去调用这两个函数
```java
GLES20.glUniform1i(hChangeType,filter.getType());
GLES20.glUniform3fv(hChangeColor,1,filter.data(),0);
```
所以，滤镜(filter)效果对应的片元着色器可以这样写:
GLSL语言
```c
precision mediump float;

uniform sampler2D vTexture;
uniform int vChangeType;
uniform vec3 vChangeColor;
uniform int vIsHalf;
uniform float uXY;      //屏幕宽高比

varying vec4 gPosition;

varying vec2 aCoordinate;
varying vec4 aPos;

void modifyColor(vec4 color){
    color.r=max(min(color.r,1.0),0.0);
    color.g=max(min(color.g,1.0),0.0);
    color.b=max(min(color.b,1.0),0.0);
    color.a=max(min(color.a,1.0),0.0);
}

void main(){
    vec4 nColor=texture2D(vTexture,aCoordinate);
    if(aPos.x>0.0||vIsHalf==0){
        if(vChangeType==1){    //黑白图片
            float c=nColor.r*vChangeColor.r+nColor.g*vChangeColor.g+nColor.b*vChangeColor.b;
            gl_FragColor=vec4(c,c,c,nColor.a);
        }else if(vChangeType==2){    //简单色彩处理，冷暖色调、增加亮度、降低亮度等
            vec4 deltaColor=nColor+vec4(vChangeColor,0.0);
            modifyColor(deltaColor);
            gl_FragColor=deltaColor;
        }else if(vChangeType==3){    //模糊处理
            nColor+=texture2D(vTexture,vec2(aCoordinate.x-vChangeColor.r,aCoordinate.y-vChangeColor.r));
            nColor+=texture2D(vTexture,vec2(aCoordinate.x-vChangeColor.r,aCoordinate.y+vChangeColor.r));
            nColor+=texture2D(vTexture,vec2(aCoordinate.x+vChangeColor.r,aCoordinate.y-vChangeColor.r));
            nColor+=texture2D(vTexture,vec2(aCoordinate.x+vChangeColor.r,aCoordinate.y+vChangeColor.r));
            nColor+=texture2D(vTexture,vec2(aCoordinate.x-vChangeColor.g,aCoordinate.y-vChangeColor.g));
            nColor+=texture2D(vTexture,vec2(aCoordinate.x-vChangeColor.g,aCoordinate.y+vChangeColor.g));
            nColor+=texture2D(vTexture,vec2(aCoordinate.x+vChangeColor.g,aCoordinate.y-vChangeColor.g));
            nColor+=texture2D(vTexture,vec2(aCoordinate.x+vChangeColor.g,aCoordinate.y+vChangeColor.g));
            nColor+=texture2D(vTexture,vec2(aCoordinate.x-vChangeColor.b,aCoordinate.y-vChangeColor.b));
            nColor+=texture2D(vTexture,vec2(aCoordinate.x-vChangeColor.b,aCoordinate.y+vChangeColor.b));
            nColor+=texture2D(vTexture,vec2(aCoordinate.x+vChangeColor.b,aCoordinate.y-vChangeColor.b));
            nColor+=texture2D(vTexture,vec2(aCoordinate.x+vChangeColor.b,aCoordinate.y+vChangeColor.b));
            nColor/=13.0;
            gl_FragColor=nColor;
        }else if(vChangeType==4){  //放大镜效果
            float dis=distance(vec2(gPosition.x,gPosition.y/uXY),vec2(vChangeColor.r,vChangeColor.g));
            if(dis<vChangeColor.b){
                nColor=texture2D(vTexture,vec2(aCoordinate.x/2.0+0.25,aCoordinate.y/2.0+0.25));
            }
            gl_FragColor=nColor;
        }else{
            gl_FragColor=nColor;
        }
    }else{
        gl_FragColor=nColor;
    }
```

### 相机预览
利用OpenGLES显示图片处理图片。视频每一帧其实也是一张图片，Camera预览时，每一帧自然也是一幅图片，我们可以把每张图片按照时间顺序显示出来，就完成了Camera预览的实现。
当然不可能把相机每一帧的数据转成一个bitmap来操作，GLES20提供了绑定纹理贴图的函数。
GLES20.java
```
 // C function void glTexImage2D ( GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels )
    public static native void glTexImage2D(
        int target,
        int level,
        int internalformat,
        int width,
        int height,
        int border,
        int format,
        int type,
        java.nio.Buffer pixels
    );
```
完全就是c函数的包装
虽然OpenGLES给我们提供的入口是传入Buffer，然而，它却限制了Buffer的格式为单一通道，或者是RGBA、RGB等格式，而Camera的帧数据却只能为NV21或者YV21的
Android的Camera及Camera2都允许使用SurfaceTexture作为预览载体，但是它们所使用的SurfaceTexture传入的OpenGL texture object name必须为GLES11Ext.GL_TEXTURE_EXTERNAL_OES。这种方式，实际上就是两个OpenGL Thread共享一个Texture，不再需要数据导入导出，从Camera采集的数据直接在GPU中完成转换和渲染。
关键函数是surfaceTexture.updateTexImage()，每当摄像头有新的数据来时，我们需要通过surfaceTexture.updateTexImage()更新预览上的图像。


### 图片处理
冷色调、暖色调、复古、黑白这些滤镜效果其实就是把hex color的ARGB channel调整一下。
```xml
<color name="bg_color">#FF88269F</color>
```
黑白图片是怎么来的？
黑白图片上，每个像素点的RGB三个通道值应该是相等的。知道了这个，将彩色图片处理成黑白图片就非常简单了。我们直接获取像素点的RGB三个通道，相加然后除以3作为处理后每个通道的值就可以得到一个黑白图片了。这是均值的方式是常见黑白图片处理的一种方法。类似的还有权值方法（给予RGB三个通道不同的比例）、只取绿色通道等方式。 
与之类似的，冷色调的处理就是单一增加蓝色通道的值，暖色调的处理可以增加红绿通道的值。还有其他复古、浮雕等处理也都差不多。

类似的滤镜效果还有：
胶片效果：
就是把RGBA的A,R,G,B全部用255减掉
即：
A = 255 - A
R = 255 -R
G = 255 - G
B = 255 - B

但是实际上用取反操作符(~)就可以了
因为ARGB正好是4个byte(1个int)
比方说
1111， 取反(位非)之后变成11111110 11111110 11111110 11111110
也就是255减去的效果

[这个RGBA的顺序不能搞错](https://en.wikipedia.org/wiki/RGBA_color_space)
In OpenGL and Portable Network Graphics (PNG), the RGBA (byte-order) is used, where the colors are stored in memory such that R is at the lowest address, G after it, B after that, and A last. On a little endian architecture this is equivalent to ABGR (word-order).

就是说，opengl和png数据中,byte array的顺序从内存低地址到高地址依次是RGBA，在小端上会掉头

[Android 关于美颜/滤镜 从OpenGl录制视频的一种方案](https://www.jianshu.com/p/12f06da0a4ec)有这样的操作byte[]的代码，需要指出的是。
java平台上，因为有jvm的存在，所以是大端。所以这下面的代码才成立
```java
int[] pixelData = new int[width * height];

int offset = 0;
int index = 0;
for (int i = 0; i < height; ++i) {
    for (int j = 0; j < width; ++j) {
        int pixel = 0;
        pixel |= (data[offset] & 0xff) << 16;     // R
        pixel |= (data[offset + 1] & 0xff) << 8;  // G
        pixel |= (data[offset + 2] & 0xff);       // B
        pixel |= (data[offset + 3] & 0xff) << 24; // A
        pixelData[index++] = pixel;
        offset += pixelStride;
    }
    offset += rowPadding;
}
```


图片模糊
图片模糊处理相对上面的色调处理稍微复杂一点，通常图片模糊处理是采集周边多个点，然后利用这些点的色彩和这个点自身的色彩进行计算，得到一个新的色彩值作为目标色彩。模糊处理有很多算法，类似高斯模糊、径向模糊等等。


### YUV格式解释(相机返回的是YUV格式的图像数据)
> RGB图像大家都了解，RGB图像分为了三个颜色分量，R红色分量，G绿色分量，B蓝色分量。而YUV图像，也是分为了三个分量，Y亮度分量，用来表示明亮度，也叫灰阶值，U分量和V分量是色值分量，用来表示图像色彩与饱和度，其中U分量也叫Cb，表示的图像蓝色偏移量，V分量也叫Cr，用来表示图像红色部分偏移量，所以YUV有时也写作YCbCr。
YUV图像把亮度和色度分开了，避免了亮度和色度的相互干扰，可以在降低色度采样率的情况下，保持图像的视觉质量。
```
RGB转YUV:

Y = 0.299 R + 0.587 G + 0.114 B

U = - 0.1687 R - 0.3313 G + 0.5 B + 128

V = 0.5 R - 0.4187 G - 0.0813 B + 128

YUV转RGB:

R = Y + 1.402 (V - 128)

G = Y - 0.34414 (U - 128) - 0.71414 (V - 128)

B = Y + 1.772 (U - 128)
```

Camera可以通过setPreviewFormat()方法来设置预览图像的数据格式，推荐选择的有ImageFormat.NV21和ImageFormat.YV12，默认是NV21。NV21属于YUV图像.
[Android Camera2 API YUV_420_888 to JPEG](https://stackoverflow.com/questions/40090681/android-camera2-api-yuv-420-888-to-jpeg)

[YuvImage.compressToJpeg](https://developer.android.com/reference/android/graphics/YuvImage.html#compressToJpeg(android.graphics.Rect,%20int,%20java.io.OutputStream)) android sdk提供了将yuv转为jpg的方法
```
public boolean compressToJpeg (Rect rectangle, 
                int quality, 
                OutputStream stream)
```
将一个YuvImage压缩成jpeg，存到一个outputStream中。**这个方法借助Android的JNI，实现了非常高效率的JPEG格式文件写入（比Bitmap.compress()效率都要高不少）**

## 参考
[opengles guide on android](https://developer.android.com/guide/topics/graphics/opengl)
[Android利用硬解硬编和OpenGLES来高效的处理MP4视频](https://blog.csdn.net/junzia/article/details/77924629)
[第三方实例](https://github.com/aiyaapp/AiyaEffectsAndroid)
[利用 FFmpeg 在 Android 上做视频编辑](https://blog.csdn.net/tanningzhong/article/details/77989686)
[2018年还在更新的](https://github.com/JimSeker/opengl)
[硬件解码视频范例](https://www.polarxiong.com/archives/Android-MediaCodec%E8%A7%86%E9%A2%91%E6%96%87%E4%BB%B6%E7%A1%AC%E4%BB%B6%E8%A7%A3%E7%A0%81-%E9%AB%98%E6%95%88%E7%8E%87%E5%BE%97%E5%88%B0YUV%E6%A0%BC%E5%BC%8F%E5%B8%A7-%E5%BF%AB%E9%80%9F%E4%BF%9D%E5%AD%98JPEG%E5%9B%BE%E7%89%87-%E4%B8%8D%E4%BD%BF%E7%94%A8OpenGL.html)