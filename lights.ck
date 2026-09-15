public class LightType {
    0 => static int SKLYDRON;
    1 => static int UKING;
}


public class ParLight {
    DMX dmx;

    int dmxChannel;
    int numChannels;

    int masterFaderChannel;
    int redChannel;
    int greenChannel;
    int blueChannel;

    //

    fun @construct(DMX dmx, int dmxChannel, int numChannels, int masterFaderChannel, int redChannel) {
        dmx @=> this.dmx;
        dmxChannel => this.dmxChannel;
        numChannels => this.numChannels;
        dmxChannel + masterFaderChannel - 1 => this.masterFaderChannel;
        dmxChannel + redChannel - 1 => this.redChannel;
        this.redChannel + 1 => this.greenChannel;
        this.greenChannel + 1 => this.blueChannel;
    }

    fun void setMaster(int val) {
        this.dmx.channel(this.masterFaderChannel, val);
    }

    fun void fadeMaster(int val, int fadeMs) {
        this.dmx.fade(this.masterFaderChannel, val, fadeMs);
    }

    fun void setColor(vec3 color) {
        [color.x$int, color.y$int, color.z$int] @=> int values[];
        this.dmx.channels(this.redChannel, values);
    }

    fun void print() {
        chout <= "Light:" <= IO.nl();
        chout <= "\tDMX Channel: " + this.dmxChannel <= IO.nl();
        chout <= "\tNumber of Channels: " + this.numChannels <= IO.nl();
        chout <= "\tMaster Fader Channel: " + this.masterFaderChannel <= IO.nl();
        chout <= "\tRGB Channels: (" + this.redChannel + ", " + this.greenChannel + ", " + this.blueChannel + ")" <= IO.nl();
    }
}
