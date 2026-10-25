public class Sampler {
    SndBuf bufs[12];

    fun @construct() {
        for (SndBuf buf : this.bufs) {
            0.3 => buf.gain;
            buf => dac;
        }
    }

    fun void load(string paths[]) {
        for (int i; i < paths.size(); i++) {
            this.bufs[i] @=> SndBuf buf;
            paths[i] => buf.read;
            0. => buf.rate;

            if( !buf.ready() ) {
                cherr <= "ERROR: Unable to load sample from path: \"" + paths[i] + "\"" <= IO.nl();
            }
        }
    }

    fun void play(int sampleIdx) {
        this.bufs[sampleIdx] @=> SndBuf buf;
        0 => buf.phase;
        1. => buf.rate;
    }
}
