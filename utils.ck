public class Utils {
    fun static float scalef(float value, float inMin, float inMax, float outMin, float outMax) {
        (value - inMin) / (inMax - inMin) => float t;
        outMin * Math.pow(outMax / outMin, t) => float result;
        return result;
    }

    fun static string joinPath(string prefix, string filename) {
        if (prefix.charAt2(prefix.length() - 1) != "/") {
            return prefix + "/" + filename;
        }

        return prefix + filename;
    }
}
