# Computer Graphics HW4 – Shading & Rasterization

---

## 1. Barycentric Coordinates + Perspective Correct Interpolation

**核心算法**：  
利用螢幕空間重心座標判斷像素是否位於三角形內，並透過除以各頂點的 `w` 分量進行透視校正插值。

```java
float denom = (v1y - v0y) * (v2x - v0x) - (v1x - v0x) * (v2y - v0y);
float u = ((v2y - v0y) * (px - v0x) - (v2x - v0x) * (py - v0y)) / denom;
float v = ((v0y - v1y) * (px - v0x) - (v0x - v1x) * (py - v0y)) / denom;
float w = 1.0f - u - v;

// Perspective correction
float cu = u / verts[0].w;
float cv = v / verts[1].w;
float cw = w / verts[2].w;
float sum = cu + cv + cw;

result[0] = cu / sum;
result[1] = cv / sum;
result[2] = cw / sum;
```
重點：
螢幕空間線性插值在透視投影下會產生扭曲
所有 varying（position、normal、color）都必須做透視校正

---

## 2. Phong Shading（Fragment-level Lighting）

**核心算法**：
在 Fragment Shader 中對每個像素計算完整光照（Ambient + Diffuse + Specular）。

```java
Vector3 N = w_normal.copy(); 
N.normalize();

Vector3 L = light.position.sub(w_position); 
L.normalize();

Vector3 V = camera.position.sub(w_position); 
V.normalize();

float diff = max(0, dot(N, L));

float spec = 0;
if (diff > 0) {
    Vector3 R = reflect(-L, N);
    spec = pow(max(0, dot(V, R)), shininess);
}
```

重點：
每個 fragment 獨立計算光照
高光最準確、畫面最平滑
計算成本最高

---

## 3. Flat Shading（Face-level Lighting）

**核心算法**：
整個三角形使用同一個「面法向量」，不做法向量插值。

```java
Vector3 edge1 = v1.sub(v0);
Vector3 edge2 = v2.sub(v0);
Vector3 faceNormal = Vector3.cross(edge1, edge2);
faceNormal.normalize();

Matrix4 normalMatrix = M.Inverse().transposed();
Vector4 transformedNormal = normalMatrix.mult(faceNormal.getVector4(0.0));

// 所有頂點共用同一法向量
for (int i = 0; i < 3; i++) {
    w_normal[i] = transformedNormal;
}
```

重點：
法向量在整個三角形內為常數
適合 low-poly 風格或除錯用途

**Tracing the Framework Code（Flat Shading）**
```
Engine.run()
    └─> GameObject.render()
        └─> Material.vertexShader()
            └─> FlatVertexShader.main()
                ├─> 計算三角形面法向量
                ├─> 使用 normal matrix 轉換到世界空間
                └─> 將同一法向量指定給三個頂點

        └─> Rasterization
            ├─> pnpoly：判斷像素是否在三角形內
            ├─> barycentric()：計算（透視校正）重心座標
            └─> varying 插值（但 normal 為常數）

        └─> FlatFragmentShader.main()
            └─> 使用單一法向量計算光照
```

雖然 fragment shader 仍會執行，但 normal 不會改變
視覺上呈現「一個三角形一個顏色」
插值流程仍存在，但對 normal 無影響

## 4. Gouraud Shading（Vertex-level Lighting）

**核心算法**：
在 Vertex Shader 中計算完整 Phong 光照，Fragment Shader 只負責顏色插值與輸出。

```java
for (int i = 0; i < 3; i++) {
    Vector3 w_position = M.mult(aVertexPosition[i]).xyz();
    Vector3 w_normal = normalMatrix.mult(aVertexNormal[i]).xyz();
    
    Vector3 color = calculatePhongLighting(
        w_position, w_normal, light, camera, material
    );

    vertexColor[i] = new Vector4(color, 1.0);
}
```


重點：
光照計算次數 = 頂點數
效能優於 Phong Shading
高光可能在頂點間被插值稀釋甚至消失
低多邊形模型效果較差，高密度網格較佳


一些截圖：
phong
<img width="996" height="625" alt="image" src="https://github.com/user-attachments/assets/c98b92a3-8d8b-419c-bdff-fc1b9e96b6d5" />
flat
<img width="992" height="623" alt="image" src="https://github.com/user-attachments/assets/de6b1bbb-fe65-4e94-90cb-fdc394c31691" />
gourand
<img width="996" height="626" alt="image" src="https://github.com/user-attachments/assets/04dd193d-1c26-453c-8422-a1b714d32b35" />


