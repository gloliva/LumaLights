public class MidiRecorder {
    4 => int sequenceSize;
    0 => int activeSequence;
    MidiRecord records[4][0];

    fun void updateActiveSequence(int diff) {
        (this.activeSequence + diff) % this.sequenceSize => this.activeSequence;
        if (this.activeSequence < 0) {
            this.sequenceSize + this.activeSequence => this.activeSequence;
        }
        <<< "New active sequence:", this.activeSequence >>>;
    }

    fun void addSequence() {
        sequenceSize + 1 => this.sequenceSize;
    }

    fun void deleteSequence() {

    }

    fun void resetSequence() {
        this.records[this.activeSequence].reset();
    }

    fun void playSequence() {

    }

    fun void addRecord(MidiMsg msg, dur timeSincePrev) {
        MidiRecord record(msg.data1, msg.data2, msg.data3, timeSincePrev);
        this.records[this.activeSequence] << record;
    }
}


public class MidiRecord {
    int msg;
    int note;
    int vel;
    dur timeSincePrev;

    fun @construct(int data1, int data2, int data3, dur timeSincePrev) {
        data1 => this.msg;
        data2 => this.note;
        data3 => this.vel;
        timeSincePrev => this.timeSincePrev;
    }
}
