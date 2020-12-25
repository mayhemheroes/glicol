const audio = {
    range: {
        low: "-1.0",
        high: "1.0"
    }
}
const range =  {
    sin: audio,
    saw: audio,
    squ: audio,
    noiz: audio,
    sampler: {
        range: {
            low: "depends on the sample",
            high: "depends on the sample"
        }
    },
    imp: {
        range: {
            low: "0.0",
            high: "1.0"
        }
    }
}

const params = {
    // sin: para(["freq"])
    sin: [["freq", "determine the frequency of the sine wave", "modulable"]],
    saw: [["freq", "determine the frequency of the sawtooth wave", "modulable"]],
    squ: [["freq", "determine the frequency of the square wave", "modulable"]],
    mul: [["mul", "determine how much the input signal is multiplied/amplified", "modulable"]],
    add: [["add", "determine how much the input signal is added/shifted", "modulable"]],
    imp: [["freq", "determine the frequency of the impluse signal", "not modulable"]],
    sampler: [["sample_name", "determine which sample to use", "not modulable"]],
}

const about = {
    sin: "outputs sine wave audio signal",
    saw: "outputs sawtooth wave audio signal",
    squ: "outputs sawtooth wave audio signal",
    mul: "multiply the input signal by a constant value",
    add: "add the input signal by a constant value",
    imp: "outputs an impulse signal",
    sampler: "play back the sample based on the value of its input. 1.0 triggers the default pitch. a trigger of value 2.0 will make the playback speed double. note: every non-zero value will trigger the playback once.",
}

const example = {
    sin: ()=>{console.log("%cany_ref_you_like: %csin %c440.0", "color: #C99E00", "color: #8959A8", "color: #3E999F")}
}

export default { about, params, range, example }