public class PhongVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Vector4[] gl_Position = new Vector4[3];
        Vector4[] w_position = new Vector4[3];
        Vector4[] w_normal = new Vector4[3];

        // Compute normal matrix: (M)^{-1}^T
        Matrix4 normal_matrix = M.Inverse().transposed();

        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
            w_position[i] = M.mult(aVertexPosition[i].getVector4(1.0));
            w_normal[i] = normal_matrix.mult(aVertexNormal[i].getVector4(0.0));
        }

        Vector4[][] result = { gl_Position, w_position, w_normal };

        return result;
    }
}

public class PhongFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector3 w_position = (Vector3) varying[1];
        Vector3 w_normal = (Vector3) varying[2];
        Vector3 albedo = (Vector3) varying[3];
        Vector3 kdksm = (Vector3) varying[4];
        Vector3 ka = (Vector3) varying[5];
        Light light = basic_light;
        Camera cam = main_camera;

        // Normalize vectors
        Vector3 N = w_normal.copy();
        N.normalize();
        Vector3 L = Vector3.sub(light.transform.position, w_position);
        L.normalize();
        Vector3 V = Vector3.sub(cam.transform.position, w_position);
        V.normalize();

        // Diffuse
        float diff = Math.max(0, Vector3.dot(N, L));

        // Specular
        float NdotL = Vector3.dot(N, L);
        Vector3 R = Vector3.sub(Vector3.mult(2 * NdotL, N), L);
        R.normalize();
        float spec = (float) Math.pow(Math.max(0, Vector3.dot(V, R)), kdksm.z);

        // Ambient
        Vector3 ambient = new Vector3(
            ka.x * albedo.x * light.light_color.x * light.intensity,
            ka.y * albedo.y * light.light_color.y * light.intensity,
            ka.z * albedo.z * light.light_color.z * light.intensity
        );

        // Diffuse component
        float diff_scale = kdksm.x * diff * light.intensity;
        Vector3 diffuse = new Vector3(
            light.light_color.x * diff_scale * albedo.x,
            light.light_color.y * diff_scale * albedo.y,
            light.light_color.z * diff_scale * albedo.z
        );

        // Specular component
        float spec_scale = kdksm.y * spec * light.intensity;
        Vector3 specular = new Vector3(
            light.light_color.x * spec_scale,
            light.light_color.y * spec_scale,
            light.light_color.z * spec_scale
        );

        // Total color
        Vector3 total = Vector3.add(Vector3.add(ambient, diffuse), specular);

        return new Vector4(total.x, total.y, total.z, 1.0);
    }
}

public class FlatVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Vector4[] gl_Position = new Vector4[3];
        Vector4[] w_position = new Vector4[3];
        Vector4[] w_normal = new Vector4[3];

        // Compute face normal
        Vector3 v0 = aVertexPosition[0];
        Vector3 v1 = aVertexPosition[1];
        Vector3 v2 = aVertexPosition[2];
        Vector3 edge1 = v1.sub(v0);
        Vector3 edge2 = v2.sub(v0);
        Vector3 face_normal = Vector3.cross(edge1, edge2);
        face_normal.normalize();

        // Compute normal matrix
        Matrix4 normal_matrix = M.Inverse().transposed();
        Vector4 transformed_normal = normal_matrix.mult(face_normal.getVector4(0.0));
        Vector3 world_normal = transformed_normal.xyz();

        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
            w_position[i] = M.mult(aVertexPosition[i].getVector4(1.0));
            // All vertices get the same face normal
            w_normal[i] = world_normal.getVector4(0.0);
        }

        Vector4[][] result = { gl_Position, w_position, w_normal };

        return result;
    }
}

public class FlatFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector3 w_position = (Vector3) varying[1];
        Vector3 w_normal = (Vector3) varying[2];
        Vector3 albedo = (Vector3) varying[3];
        Vector3 kdksm = (Vector3) varying[4];
        Vector3 ka = (Vector3) varying[5];
        Light light = basic_light;
        Camera cam = main_camera;

        // Normalize vectors
        Vector3 N = w_normal.copy();
        N.normalize();
        Vector3 L = Vector3.sub(light.transform.position, w_position);
        L.normalize();
        Vector3 V = Vector3.sub(cam.transform.position, w_position);
        V.normalize();

        // Diffuse
        float diff = Math.max(0, Vector3.dot(N, L));

        // Specular
        float NdotL = Vector3.dot(N, L);
        Vector3 R = Vector3.sub(Vector3.mult(2 * NdotL, N), L);
        R.normalize();
        float spec = (float) Math.pow(Math.max(0, Vector3.dot(V, R)), kdksm.z);

        // Ambient
        Vector3 ambient = new Vector3(
            ka.x * albedo.x * light.light_color.x * light.intensity,
            ka.y * albedo.y * light.light_color.y * light.intensity,
            ka.z * albedo.z * light.light_color.z * light.intensity
        );

        // Diffuse component
        float diff_scale = kdksm.x * diff * light.intensity;
        Vector3 diffuse = new Vector3(
            light.light_color.x * diff_scale * albedo.x,
            light.light_color.y * diff_scale * albedo.y,
            light.light_color.z * diff_scale * albedo.z
        );

        // Specular component
        float spec_scale = kdksm.y * spec * light.intensity;
        Vector3 specular = new Vector3(
            light.light_color.x * spec_scale,
            light.light_color.y * spec_scale,
            light.light_color.z * spec_scale
        );

        // Total color
        Vector3 total = Vector3.add(Vector3.add(ambient, diffuse), specular);
        
        // Clamp to avoid overexposure
        float r = Math.min(1.0f, Math.max(0.0f, total.x));
        float g = Math.min(1.0f, Math.max(0.0f, total.y));
        float b = Math.min(1.0f, Math.max(0.0f, total.z));

        return new Vector4(r, g, b, 1.0);
    }
}

public class GouraudVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M = (Matrix4) uniform[1];
        Light light = (Light) uniform[2];
        Camera cam = (Camera) uniform[3];
        Vector3 ka = (Vector3) uniform[4];
        float kd = (Float) uniform[5];
        float ks = (Float) uniform[6];
        float m_val = (Float) uniform[7];
        Vector3 albedo = (Vector3) uniform[8];

        Vector4[] gl_Position = new Vector4[3];
        Vector4[] vertexColor = new Vector4[3];

        // Compute normal matrix
        Matrix4 normal_matrix = M.Inverse().transposed();

        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));

            // Transform to world space
            Vector4 w_pos4 = M.mult(aVertexPosition[i].getVector4(1.0));
            Vector3 w_position = w_pos4.xyz();
            Vector4 w_norm4 = normal_matrix.mult(aVertexNormal[i].getVector4(0.0));
            Vector3 w_normal = w_norm4.xyz();

            // Normalize
            Vector3 N = w_normal.copy();
            N.normalize();
            Vector3 L = Vector3.sub(light.transform.position, w_position);
            L.normalize();
            Vector3 V = Vector3.sub(cam.transform.position, w_position);
            V.normalize();

            // Diffuse
            float NdotL = Vector3.dot(N, L);
            float diff = Math.max(0, NdotL);

            // Specular - only calculate if surface faces light
            float spec = 0;
            if (NdotL > 0) {
                Vector3 R = Vector3.sub(Vector3.mult(2 * NdotL, N), L);
                R.normalize();
                spec = (float) Math.pow(Math.max(0, Vector3.dot(V, R)), m_val);
            }

            // Ambient
            Vector3 ambient = new Vector3(
                ka.x * albedo.x * light.light_color.x * light.intensity,
                ka.y * albedo.y * light.light_color.y * light.intensity,
                ka.z * albedo.z * light.light_color.z * light.intensity
            );

            // Diffuse component
            float diff_scale = kd * diff * light.intensity;
            Vector3 diffuse = new Vector3(
                light.light_color.x * diff_scale * albedo.x,
                light.light_color.y * diff_scale * albedo.y,
                light.light_color.z * diff_scale * albedo.z
            );

            // Specular component
            float spec_scale = ks * spec * light.intensity;
            Vector3 specular = new Vector3(
                light.light_color.x * spec_scale,
                light.light_color.y * spec_scale,
                light.light_color.z * spec_scale
            );

            // Total color
            Vector3 total = Vector3.add(Vector3.add(ambient, diffuse), specular);
            
            // Clamp to avoid overexposure
            float r = Math.min(1.0f, Math.max(0.0f, total.x));
            float g = Math.min(1.0f, Math.max(0.0f, total.y));
            float b = Math.min(1.0f, Math.max(0.0f, total.z));
            
            vertexColor[i] = new Vector4(r, g, b, 1.0);
        }

        Vector4[][] result = { gl_Position, vertexColor };

        return result;
    }
}



public class GouraudFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        Vector4 interpolatedColor = (Vector4) varying[1];

        return interpolatedColor;
    }
}
