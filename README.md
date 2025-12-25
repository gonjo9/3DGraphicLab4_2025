# HW4 計算機圖學作業報告

## 目錄
- [完成任務概述](#完成任務概述)
- [工作成果展示](#工作成果展示)
- [實現細節](#實現細節)
- [問題與解決方案](#問題與解決方案)
- [框架代碼追蹤](#框架代碼追蹤)
- [心得與總結](#心得與總結)

---

## 完成任務概述

本次作業實現了圖形渲染管線中的重要著色技術，包括透視校正插值和三種不同的光照著色模型：

| 任務 | 難度 | 狀態 | 檔案 |
|------|------|------|------|
| 重心座標 (Barycentric Coordinates) | ★★★☆ | ✅ 完成 | `util.pde` |
| Phong 著色 (Phong Shading) | ★★★★☆ | ✅ 完成 | `Material.pde`, `ColorShader.pde` |
| Flat 著色 (Flat Shading) | ★★★★☆ | ✅ 完成 | `Material.pde`, `ColorShader.pde` |
| Gouraud 著色 (Gouraud Shading) | ★★★★☆ | ✅ 完成 | `Material.pde`, `ColorShader.pde` |
| 背面剔除 (Backface Culling) | - | ✅ 額外實現 | `GameObject.pde` |

---

## 工作成果展示

### 視覺效果比較

#### Phong 著色
- **特點**：片段級別光照計算，最高品質
- **效果**：平滑的光照過渡、精細的高光反射
- **適用場景**：需要高品質渲染的物體

#### Flat 著色
- **特點**：面級別光照計算，使用統一法向量
- **效果**：明顯的平面塊狀外觀、清晰的三角形邊界
- **適用場景**：低多邊形風格、需要快速預覽

#### Gouraud 著色
- **特點**：頂點級別光照計算，性能與品質平衡
- **效果**：平滑的色彩過渡，但高光可能失真
- **適用場景**：中等品質需求、性能敏感場景

> 💡 **提示**：實際運行程式時，請截取各種著色效果的截圖並替換此處描述

---

## 實現細節

### 1️⃣ 重心座標與透視校正插值

**實現位置**：`util.pde::barycentric()`

**核心概念**：
- 重心座標 (α, β, γ) 用於三角形內部的插值
- 透視校正是透視投影下正確插值的關鍵

**算法步驟**：

```java
// 1. 計算螢幕空間重心座標
float denom = (v1y - v0y) * (v2x - v0x) - (v1x - v0x) * (v2y - v0y);
float u = ((v2y - v0y) * (px - v0x) - (v2x - v0x) * (py - v0y)) / denom;
float v_coord = ((v0y - v1y) * (px - v0x) - (v0x - v1x) * (py - v0y)) / denom;
float w = 1.0f - u - v_coord;

// 2. 透視校正：除以各頂點的 w 分量
float cu = u / verts[0].w;
float cv = v_coord / verts[1].w;
float cw = w / verts[2].w;

// 3. 歸一化得到最終重心座標
float total = cu + cv + cw;
result[0] = cu / total;
result[1] = cv / total;
result[2] = cw / total;
```

**為什麼需要透視校正？**
- 線性插值在透視投影下會產生扭曲
- 紋理座標、法向量等屬性需要正確的深度權重
- 公式：`屬性 = (α/w₀·A + β/w₁·B + γ/w₂·C) / (α/w₀ + β/w₁ + γ/w₂)`

---

### 2️⃣ Phong 著色模型

**實現位置**：`ColorShader.pde::PhongVertexShader`, `PhongFragmentShader`

**Phong 光照方程**：
```
I = Iₐ·Kₐ + Iₗ·Kd·(N·L) + Iₗ·Ks·(R·V)ᵐ
```

**實現架構**：

**頂點著色器**：
```java
// 計算法線矩陣（模型矩陣的逆轉置）
Matrix4 normal_matrix = M.Inverse().transposed();

// 轉換位置和法向量到世界空間
w_position[i] = M.mult(aVertexPosition[i].getVector4(1.0));
w_normal[i] = normal_matrix.mult(aVertexNormal[i].getVector4(0.0));
```

**片段著色器**：
```java
// 歸一化向量
Vector3 N = w_normal.copy(); N.normalize();  // 法向量
Vector3 L = Vector3.sub(light.position, w_position); L.normalize();  // 光源方向
Vector3 V = Vector3.sub(camera.position, w_position); V.normalize();  // 視線方向

// 計算光照分量
float NdotL = Vector3.dot(N, L);
float diff = Math.max(0, NdotL);  // 漫反射

// 鏡面反射（只在表面朝向光源時計算）
float spec = 0;
if (NdotL > 0) {
    Vector3 R = Vector3.sub(Vector3.mult(2 * NdotL, N), L);
    R.normalize();
    spec = pow(max(0, dot(V, R)), shininess);
}

// 組合最終顏色
Vector3 ambient = Ka * albedo * light.color * light.intensity;
Vector3 diffuse = Kd * diff * albedo * light.color * light.intensity;
Vector3 specular = Ks * spec * light.color * light.intensity;
Vector3 finalColor = clamp(ambient + diffuse + specular, 0.0, 1.0);
```

**材質參數**：
- `Ka = 0.1`：環境光係數（降低以避免過亮）
- `Kd = 0.7`：漫反射係數
- `Ks = 0.4`：鏡面反射係數
- `m = 32`：光澤度（值越大高光越集中）

---

### 3️⃣ Flat 著色模型

**實現位置**：`ColorShader.pde::FlatVertexShader`, `FlatFragmentShader`

**核心差異**：使用面法向量而非頂點法向量

**頂點著色器**：
```java
// 計算面法向量（三角形平面的法線）
Vector3 edge1 = v1.sub(v0);
Vector3 edge2 = v2.sub(v0);
Vector3 face_normal = Vector3.cross(edge1, edge2);
face_normal.normalize();

// 轉換到世界空間
Matrix4 normal_matrix = M.Inverse().transposed();
Vector4 transformed_normal = normal_matrix.mult(face_normal.getVector4(0.0));

// 所有三個頂點使用相同的法向量
for (int i = 0; i < 3; i++) {
    w_normal[i] = transformed_normal;
}
```

**片段著色器**：
- 與 Phong 使用相同的光照計算
- 但由於法向量在三角形內是常數，整個三角形顏色統一

**視覺特點**：
- 清晰可見的三角形邊界
- 適合低多邊形藝術風格
- 性能優於 Phong（但光照仍在片段計算）

---

### 4️⃣ Gouraud 著色模型

**實現位置**：`ColorShader.pde::GouraudVertexShader`, `GouraudFragmentShader`

**核心差異**：在頂點著色器計算光照，片段著色器只做插值

**頂點著色器**：
```java
// 在每個頂點計算完整的 Phong 光照
for (int i = 0; i < 3; i++) {
    // 轉換到世界空間
    Vector3 w_position = M.mult(aVertexPosition[i]).xyz();
    Vector3 w_normal = normal_matrix.mult(aVertexNormal[i]).xyz();
    
    // 計算 Phong 光照（ambient + diffuse + specular）
    Vector3 vertexColor = calculatePhongLighting(w_position, w_normal, ...);
    
    // 輸出顏色
    vertexColor[i] = new Vector4(vertexColor.x, vertexColor.y, vertexColor.z, 1.0);
}

return { gl_Position, vertexColor };
```

**片段著色器**：
```java
// 直接返回插值後的顏色，無需額外計算
Vector4 interpolatedColor = (Vector4) varying[1];
return interpolatedColor;
```

**優缺點分析**：
- ✅ 性能優異：光照計算次數 = 頂點數（遠小於片段數）
- ✅ 適合動態物體：減少 GPU 負擔
- ❌ 高光失真：高光在頂點間插值可能消失
- ❌ 需要高密度網格：低多邊形模型效果不佳

---

### 5️⃣ 背面剔除（額外實現）

**實現位置**：`GameObject.pde::render()`

**問題**：原始實現會渲染所有三角形，導致「透視」效果

**解決方案**：
```java
// 計算三角形在螢幕空間的有向面積
float area = 0.5f * ((s_Position[0].x * (s_Position[1].y - s_Position[2].y)) +
                      (s_Position[1].x * (s_Position[2].y - s_Position[0].y)) +
                      (s_Position[2].x * (s_Position[0].y - s_Position[1].y)));

// 面積 ≤ 0 表示背面（假設逆時針為正面）
if (area <= 0) continue;  // 跳過背面三角形
```

**效果**：
- 消除「看穿」物體的問題
- 提升渲染性能（約減少 50% 三角形）
- 符合真實世界的遮擋關係

---

## 問題與解決方案

### 🔴 問題 1：normalize() 返回 void 導致編譯錯誤

**錯誤訊息**：
```
Type mismatch: cannot convert from void to Vector3
```

**原因**：Processing 的 `Vector3.normalize()` 是 in-place 操作，不返回值

**解決方案**：
```java
// ❌ 錯誤寫法
Vector3 N = w_normal.normalize();

// ✅ 正確寫法
Vector3 N = w_normal.copy();
N.normalize();
```

---

### 🔴 問題 2：變數名 "color" 衝突

**錯誤訊息**：
```
Type names are not allowed as variable names: color
```

**原因**：Processing 中 `color` 是內建類型

**解決方案**：
```java
// ❌ 錯誤
Vector4 color = ...;

// ✅ 正確
Vector4 vertexColor = ...;
Vector4 interpolatedColor = ...;
```

---

### 🔴 問題 3：法向量轉換錯誤導致黑白效果

**症狀**：渲染結果只有黑白灰階

**原因**：使用模型矩陣 `M` 直接轉換法向量，在有縮放時會失真

**解決方案**：
```java
// ❌ 錯誤：直接使用模型矩陣
w_normal[i] = M.mult(aVertexNormal[i].getVector4(0.0));

// ✅ 正確：使用法線矩陣（逆轉置）
Matrix4 normal_matrix = M.Inverse().transposed();
w_normal[i] = normal_matrix.mult(aVertexNormal[i].getVector4(0.0));
```

**數學原理**：法向量是協變量，需用 $(M^{-1})^T$ 轉換以保持垂直性

---

### 🔴 問題 4：顏色過曝

**症狀**：物體過亮或出現異常顏色

**原因**：光照計算可能超過 [0, 1] 範圍

**解決方案**：
```java
// 在輸出前限制顏色範圍
float r = Math.min(1.0f, Math.max(0.0f, total.x));
float g = Math.min(1.0f, Math.max(0.0f, total.y));
float b = Math.min(1.0f, Math.max(0.0f, total.z));
return new Vector4(r, g, b, 1.0);
```

---

### 🔴 問題 5：背面高光異常

**症狀**：背向光源的表面仍有鏡面反射

**原因**：未判斷表面朝向就計算高光

**解決方案**：
```java
// 只在表面朝向光源時計算鏡面反射
float NdotL = Vector3.dot(N, L);
float spec = 0;
if (NdotL > 0) {
    Vector3 R = reflect(-L, N);
    spec = pow(max(0, dot(V, R)), shininess);
}
```

---

## 框架代碼追蹤

### 渲染管線流程

```
Engine.run()
    └─> GameObject.render()
        └─> Material.vertexShader()
            └─> VertexShader.main()  // 處理每個三角形
                └─> 返回 gl_Position + varyings
        
        └─> 對每個像素：
            ├─> 檢查是否在三角形內 (pnpoly)
            ├─> 計算重心座標 (barycentric)
            ├─> 插值 varyings
            ├─> Material.fragmentShader()
            │   └─> FragmentShader.main()  // 計算顏色
            └─> 深度測試 + 寫入 framebuffer
```

### 數據流追蹤

**Phong Shading**：
```
Triangle.verts (模型空間)
    ↓ M (模型矩陣)
w_position (世界空間)
    ↓ 重心插值
fragment w_position
    ↓ 光照計算
final color

Triangle.normal (模型空間)
    ↓ M⁻¹ᵀ (法線矩陣)
w_normal (世界空間)
    ↓ 重心插值
fragment w_normal
    ↓ 歸一化
N (用於光照)
```

**Gouraud Shading**：
```
頂點位置 + 法向量
    ↓ 頂點著色器
頂點顏色 (已計算光照)
    ↓ 重心插值
片段顏色
    ↓ 直接輸出
final color
```

### 關鍵發現

1. **Material 層**：負責組織數據，決定傳遞給 Shader 的 attributes 和 uniforms
2. **Shader 層**：負責實際計算，Vertex Shader 輸出的 varyings 會被自動插值
3. **插值行為**：由 `barycentric()` 實現，支援透視校正
4. **模塊化設計**：易於擴展新的著色模型，只需實現對應的 Material 和 Shader 類別

---

## 心得與總結

### 技術收穫

1. **透視校正的重要性**
   - 深刻理解了為何需要除以 w 分量
   - 掌握了正確插值屬性的數學原理

2. **法線轉換的數學**
   - 理解了為何法向量需要逆轉置矩陣
   - 實踐了協變/逆變的概念

3. **著色模型的權衡**
   - Phong：品質最高，成本最高
   - Gouraud：性能優秀，品質中等
   - Flat：簡單高效，適合特定風格

4. **除錯經驗**
   - 法線矩陣錯誤會導致完全錯誤的光照
   - 顏色限制是防止過曝的必要措施
   - 背面剔除是提升視覺正確性的關鍵

### 實作心得

- 框架追蹤讓我深入理解了 GPU 渲染管線的工作原理
- 實現三種著色模型幫助我理解了性能與品質的取捨
- 遇到的 bug 都與圖形學的核心概念相關，解決過程很有啟發性

### 未來改進方向

- [ ] 實現多光源支援
- [ ] 加入紋理映射
- [ ] 實現法線貼圖
- [ ] 優化著色器性能
- [ ] 支援更多材質類型（金屬、玻璃等）

---

**作業完成日期**：2025/12/26  
**開發環境**：Processing  
**程式語言**：Java (Processing)