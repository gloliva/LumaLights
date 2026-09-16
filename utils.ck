public class Utils {
    fun static float scalef(float value, float inMin, float inMax, float outMin, float outMax) {
        (value - inMin) / (inMax - inMin) => float t;
        outMin * Math.pow(outMax / outMin, t) => float result;
        return result;
    }
}
