public abstract class Material {
    Vector3 albedo = new Vector3(0.9, 0.9, 0.9);
    Shader shader;

    Material() {
        // TODO HW4
        // In the Material, pass the relevant attribute variables and uniform variables
        // you need.
        // In the attribute variables, include relevant variables about vertices,
        // and in the uniform, pass other necessary variables.
        // Please note that a Material will be bound to the corresponding Shader.
    }

    abstract Vector4[][] vertexShader(Triangle triangle, Matrix4 M);

    abstract Vector4 fragmentShader(Vector3 position, Vector4[] varing);

    void attachShader(Shader s) {
        shader = s;
    }
}

public class DepthMaterial extends Material {
    DepthMaterial() {
        shader = new Shader(new DepthVertexShader(), new DepthFragmentShader());
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;
        Vector4[][] r = shader.vertex.main(new Object[] { position }, new Object[] { MVP });
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        return shader.fragment.main(new Object[] { position });
    }
}

public class PhongMaterial extends Material {
    Vector3 Ka = new Vector3(0.1, 0.1, 0.1);
    float Kd = 0.7;
    float Ks = 0.4;
    float m = 32;

    PhongMaterial() {
        albedo = new Vector3(1.0, 0.5, 0.5); // Brighter reddish color
        shader = new Shader(new PhongVertexShader(), new PhongFragmentShader());
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;
        Vector3[] normal = triangle.normal;
        Vector4[][] r = shader.vertex.main(new Object[] { position, normal }, new Object[] { MVP, M });
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {

        return shader.fragment
                .main(new Object[] { position, varing[0].xyz(), varing[1].xyz(), albedo, new Vector3(Kd, Ks, m), Ka });
    }

}

public class FlatMaterial extends Material {
    Vector3 Ka = new Vector3(0.1, 0.1, 0.1);
    float Kd = 0.7;
    float Ks = 0.4;
    float m = 32;

    FlatMaterial() {
        albedo = new Vector3(1.0, 0.5, 0.5); // Brighter reddish color
        shader = new Shader(new FlatVertexShader(), new FlatFragmentShader());
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;

        Vector4[][] r = shader.vertex.main(new Object[] { position }, new Object[] { MVP, M });
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        return shader.fragment.main(new Object[] { position, varing[0].xyz(), varing[1].xyz(), albedo, new Vector3(Kd, Ks, m), Ka });
    }
}

public class GouraudMaterial extends Material {
    Vector3 Ka = new Vector3(0.1, 0.1, 0.1);
    float Kd = 0.7;
    float Ks = 0.4;
    float m = 32;

    GouraudMaterial() {
        albedo = new Vector3(1.0, 0.5, 0.5); // Brighter reddish color
        shader = new Shader(new GouraudVertexShader(), new GouraudFragmentShader());
    }

    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;
        Vector3[] normal = triangle.normal;

        Vector4[][] r = shader.vertex.main(new Object[] { position, normal }, new Object[] { MVP, M, basic_light, main_camera, Ka, Kd, Ks, m, albedo });
        return r;
    }

    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        return shader.fragment.main(new Object[] { position, varing[0] });
    }
}


public enum MaterialEnum {
    DM, FM, GM, PM;
}
