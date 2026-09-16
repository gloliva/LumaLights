// Imports
@import "config.ck"
@import "lights.ck"
@import "utils.ck"

// Chugin imports
@import "HashMap"


// Read config file
Config config(me.dir() + "/config.json");


// Init DMX
DMX dmx;
dmx.protocol(config.getProtocol());
dmx.port(config.getPort());
// For Enttec Open DMX USB, RTS must be disabled
false => dmx.rts;

if (!dmx.init()) {
    cherr <= "ERROR: Serial device could not initialize." <= IO.nl();
    me.exit();
}


// Set up lights
ParLight lights[0];
for (int i; i < config.numLights(); i++) {
    config.lightsConfig.get(i) @=> HashMap lightConfig;

    ParLight light(
        dmx,
        lightConfig.getInt("dmxChannel"),
        lightConfig.getInt("numChannels"),
        lightConfig.getInt("masterChannel"),
        lightConfig.getInt("redChannel")
    );

    lights << light;
    light.print();
}


// Lighting parameters
int heldNotes[lights.size()][0];
14 => int LIGHT_TARGET_MODE;
15 => int LIGHT_MODE_CHANNEL;


class LightingTarget {
    0 => static int INDIVIDUAL;
    1 => static int ALL;
}
LightingTarget.INDIVIDUAL => int activeLightingTarget;


class LightingModes {
    0 => static int MANUAL_FADE;
    1 => static int MANUAL_SNAP;
    2 => static int STROBE;

    // Aftertouch effects
    3 => static int AFTERTOUCH_STROBE;

    [
        LightingModes.MANUAL_FADE,
        LightingModes.MANUAL_SNAP,
        LightingModes.STROBE,
        LightingModes.AFTERTOUCH_STROBE,
    ] @=> static int ALL_MODES[];
}
LightingModes.MANUAL_FADE => int activeLightingMode;

// Events
Event startStrobe;
Event startAftertouch;


// Init MIDI
MidiIn min;
MidiMsg msg;
if (!min.open("Lumatone")) {
    cherr <= "ERROR: Unable to open Lumatone. Is it connected? Run `chuck --probe` to check." <= IO.nl();
    me.exit();
}


// Midi parameters
50 => int modWheelValue;



class MidiMessage {
    0x80 => static int NOTE_OFF;
    0x90 => static int NOTE_ON;
    0xA0 => static int POLYPHONIC_AFTERTOUCH;
    0xB0 => static int CONTROL_CHANGE;
    0xC0 => static int PROGRAM_CHANGE;
    0xD0 => static int CHANNEL_AFTERTOUCH;
    0xE0 => static int PITCH_WHEEL;
}


// Set static colors
[
    @(255, 0, 0),
    @(255, 128, 0),
    @(255, 255, 0),
    @(170, 255, 0),
    @(0, 255, 0),
    @(0, 255, 128),
    @(0, 255, 255),
    @(0, 128, 255),
    @(0, 0, 255),
    @(127, 0, 255),
    @(255, 0, 255),
    @(255, 0, 127),
] @=> vec3 colors[];
vec3 activeColors[lights.size()];


// Aftertouch handling
0 => int aftertouchEnabled;
int activeAftertouch[lights.size()];


// Strobe handling
int strobeEnabled[lights.size()];
SqrOsc strobeState[lights.size()];
for (SqrOsc strobe : strobeState) {
    1::second => strobe.period;
    strobe => blackhole;
}


// Send DMX information on schedule
fun void send() {
    while (true) {
        dmx.send();
        30::ms => now;
    }
} spork ~ send();


fun void addNote(int heldNotes[], int note) {
    heldNotes << note;
}


fun void removeNote(int heldNotes[], int note) {
    for (heldNotes.size() - 1 => int i; i >= 0; i--) {
        if (heldNotes[i] == note) {
            heldNotes.popOut(i);
            break;
        }
    }
}


fun int getLastNote(int heldNotes[]) {
    if (heldNotes.size() == 0) {
        return -1;
    }

    return heldNotes[-1];
}


fun void strobeMode() {
    while (true) {
        startStrobe => now;

        while (activeLightingMode == LightingModes.STROBE) {
            for (int lightId; lightId < lights.size(); lightId++) {
                if (strobeEnabled[lightId]) {
                    Utils.scalef(modWheelValue, 0, 127, 1000, 61) => float strobeMs;
                    <<< "Strobe MS:", strobeMs >>>;

                    strobeMs::ms => strobeState[lightId].period;
                    if (strobeState[lightId].last() > 0) {
                        lights[lightId].setMaster(100);
                    } else {
                        lights[lightId].setMaster(0);
                    }
                }
            }
            1::ms => now;
        }
    }
} spork ~ strobeMode();


fun void aftertouchEffects() {
    while (true) {
        if (aftertouchEnabled) {
            for (int lightId; lightId < lights.size(); lightId++) {
                Std.scalef(activeAftertouch[lightId], 0, 127, 300, 50)::ms => strobeState[lightId].period;

                if (strobeEnabled[lightId]) {
                    if (strobeState[lightId].last() > 0) {
                        lights[lightId].setMaster(100);
                    } else {
                        lights[lightId].setMaster(0);
                    }
                }
            }
        }
        25::ms => now;
    }
} spork ~ aftertouchEffects();


// MIDI Handling
while( true ) {
    min => now;

    while( min.recv(msg) ) {
        // MIDI Note On
        if (msg.data1 >= MidiMessage.NOTE_ON && msg.data1 < MidiMessage.POLYPHONIC_AFTERTOUCH) {
            msg.data1 - MidiMessage.NOTE_ON => int channel;
            if (channel == LIGHT_TARGET_MODE) {
                if (msg.data2 == LightingTarget.INDIVIDUAL) {
                    LightingTarget.INDIVIDUAL => activeLightingTarget;
                } else if (msg.data2 == LightingTarget.ALL) {
                    LightingTarget.ALL => activeLightingTarget;
                }
            } else if (channel == LIGHT_MODE_CHANNEL) {
                if (msg.data2 == LightingModes.MANUAL_FADE) {
                    LightingModes.MANUAL_FADE => activeLightingMode;
                } else if (msg.data2 == LightingModes.MANUAL_SNAP) {
                    LightingModes.MANUAL_SNAP => activeLightingMode;
                } else if (msg.data2 == LightingModes.STROBE) {
                    LightingModes.STROBE => activeLightingMode;
                    startStrobe.broadcast();
                } else if (msg.data2 == LightingModes.AFTERTOUCH_STROBE && activeLightingMode != LightingModes.STROBE) {
                    1 - aftertouchEnabled => aftertouchEnabled;
                    <<< "Aftertouch mode:", aftertouchEnabled >>>;
                }
            } else {
                0 => int startLightId;
                lights.size() => int endLightId;

                if (activeLightingTarget == LightingTarget.INDIVIDUAL) {
                    channel => startLightId;
                    channel + 1 => endLightId;
                }

                // Loop through all lights to targets
                for (startLightId => int lightId; lightId < endLightId; lightId++) {
                    // Add note to held notes
                    lights[lightId] @=> ParLight light;
                    addNote(heldNotes[lightId], msg.data2);

                    // Set Color
                    colors[msg.data2] => vec3 color;
                    light.setColor(color);
                    color => activeColors[lightId];

                    // Fade in if first held note
                    if (heldNotes[lightId].size() == 1) {
                        if (activeLightingMode == LightingModes.MANUAL_FADE) {
                            light.fadeMaster(100, 100);
                        } else if (activeLightingMode == LightingModes.MANUAL_SNAP) {
                            light.setMaster(100);
                        } else if (activeLightingMode == LightingModes.STROBE) {
                            startStrobe.broadcast();
                            1 => strobeEnabled[lightId];
                            0. => strobeState[lightId].phase;
                        }
                    }
                }
            }
        } else if (msg.data1 >= MidiMessage.NOTE_OFF && msg.data1 < MidiMessage.NOTE_ON) {
            msg.data1 - MidiMessage.NOTE_OFF => int channel;
            if (channel == LIGHT_TARGET_MODE || channel == LIGHT_MODE_CHANNEL) continue;

            0 => int startLightId;
            lights.size() => int endLightId;

            if (activeLightingTarget == LightingTarget.INDIVIDUAL) {
                channel => startLightId;
                channel + 1 => endLightId;
            }

            // Loop through all light targets
            for (startLightId => int lightId; lightId < endLightId; lightId++) {
                // Remove note from held notes
                lights[lightId] @=> ParLight light;
                removeNote(heldNotes[lightId], msg.data2);

                // Fade out if no held notes
                heldNotes[lightId].size() => int size;
                if (size == 0) {
                    if (activeLightingMode == LightingModes.MANUAL_FADE) {
                        Std.scalef(modWheelValue, 8, 127, 100, 1000)$int => int fadeMs;
                        light.fadeMaster(0, fadeMs);
                    } else if (activeLightingMode == LightingModes.MANUAL_SNAP) {
                        light.setMaster(0);
                    } else if (activeLightingMode == LightingModes.STROBE) {
                        0 => strobeEnabled[lightId];
                        light.setMaster(0);
                    }
                } else {
                    heldNotes[lightId][size-1] => int currNote;
                    colors[currNote] => vec3 color;
                    light.setColor(color);
                }
            }
        } else if (msg.data1 >= MidiMessage.POLYPHONIC_AFTERTOUCH && msg.data1 < MidiMessage.CONTROL_CHANGE) {
            // Polyphonic Aftertouch
            // data1 == Status + Channel | data2 == Note number | data3 == aftertouch value
            if (!aftertouchEnabled) continue;

            msg.data1 - MidiMessage.POLYPHONIC_AFTERTOUCH => int channel;

            0 => int startLightId;
            lights.size() => int endLightId;

            if (activeLightingTarget == LightingTarget.INDIVIDUAL) {
                channel => startLightId;
                channel + 1 => endLightId;
            }

            for (startLightId => int lightId; lightId < endLightId; lightId++) {
                if (getLastNote(heldNotes[channel]) == msg.data2) {
                    msg.data3 => activeAftertouch[channel];
                    if (msg.data3 > 8) {
                        if (!strobeEnabled[lightId]) {
                            1 => strobeEnabled[lightId];
                            0. => strobeState[lightId].phase;
                        }
                    } else {
                        if (strobeEnabled[lightId]) {
                            0 => strobeEnabled[lightId];
                            0. => strobeState[lightId].phase;
                        }
                    }
                }
            }
        } else if (msg.data1 >= MidiMessage.CONTROL_CHANGE && msg.data1 < MidiMessage.PROGRAM_CHANGE) {
            if (msg.data2 == 1) {
                msg.data3 => modWheelValue;
                <<< "Mod wheel change:", modWheelValue >>>;
            }
        }
    }
}
