// Chugin imports
@import "HashMap"


public class Config {
    HashMap @ configFile;
    HashMap @ dmxConfig;
    HashMap @ lightsConfig;


    fun @construct(string jsonFile) {
        HashMap.fromJsonFile(jsonFile) @=> this.configFile;
        configFile.get("dmx") @=> this.dmxConfig;
        configFile.get("lights") @=> this.lightsConfig;
    }

    fun int getProtocol() {
        if (!this.dmxConfig.has("protocol")) {
            cherr <= "ERROR: Protocol not specified in config file. Specify between ARTNET, SACN, SERIAL, or SERIAL_RAW." <= IO.nl();
            return -1;
        }

        this.dmxConfig.getStr("protocol").upper() => string protocol;
        if (protocol == "ARTNET") {
            return DMX.ARTNET;
        } else if (protocol == "SACN") {
            return DMX.SACN;
        } else if (protocol == "SERIAL") {
            return DMX.SERIAL;
        } else if (protocol == "SERIAL_RAW") {
            return DMX.SERIAL_RAW;
        }

        cherr <= "ERROR: Provided protocol `" +  protocol + "`. Choices must be either ARTNET, SACN, SERIAL, or SERIAL_RAW.";
        return -1;
    }

    fun string getPort() {
        if (!this.dmxConfig.has("port")) {
            cherr <= "ERROR: Port not specified in config file. Run DMX.ports() to see available DMX devices." <= IO.nl();
            return null;
        }

        this.dmxConfig.getStr("port") => string port;
        return port;
    }

    fun int numLights() {
        return this.lightsConfig.intKeys().size();
    }
}