//a
import funkin.backend.chart.Chart;
import Reflect;

importScript("GameJolt API/old gamejolt");

/**
    Internal Variables, changable so that mods can have even more difficulty levels if
**/
var _minDiff:Int = 1;
var _maxDiff:Int = 3; // changable in the future

var _maxHours:Int = 48;
var _minHours:Int = 1;
var _defualtHours:Int = 24;
public function new_challenge(name:String, ?diff:Int = 1, ?time_hours:Int = 0) {
    if (diff == null) diff = _minDiff;
    if (time_hours == null) time_hours = _defualtHours;
    // because classes are unstable until rev+428-55
    var obj = {
        _songName: null, // internal use
        name: name,
        diff: diff,
        time_hours: time_hours,
    };

    // functions
    obj.setName = function(name:String) {
        if (name == null) return obj;
        obj.name = name;
        return obj;
    };
    obj.setDiff = function(diff:Int) {
        if (diff == null) return obj;

        if (diff < _minDiff) diff = _minDiff;
        else if (diff > _maxDiff) diff = _maxDiff;

        obj.diff = diff;
        return obj;
    };
    obj.setTimeLimit = function(time_hours:Int) {
        if (time_hours == null) {
            obj.time_hours = _defualtHours;
            return obj;
        }

        if (time_hours < _minHours) time_hours = _minHours;
        else if (time_hours > _maxHours) time_hours = _maxHours;

        obj.time_hours = time_hours;
        return obj;
    };
    obj.setSongName = function(songName:String) {
        if (songName == null) return obj;
        obj._songName = StringTools.replace(songName.toLowerCase(), " ", "-");
        return obj;
    };
    obj.__itself = function() {
        return new_challenge(obj.name, obj.diff, obj.time_hours);
    };

    // force update within bounds
    obj.setDiff(diff);
    obj.setName(name);
    obj.setTimeLimit(time_hours);

    return obj;
}

// higher = more chance for Global | Lower = more Specific
public static var global_amount_percent:Float = 50.0;

var global_Challenges:Array<Dynamic> = [
    new_challenge("Beat ${song_name}"),
];
public function add_global_challenge(chall:Dynamic) {
    global_Challenges.push(chall);
}

/**
    Data format:
    [   // the `meta.name`, not `meta.displayName`
        "song_name" => [
            new_challenge();
        ]
    ]

    Its a map that contains the random challenges for each song
**/
var songSpecific_Challenges:Map<String, Array<Dynamic>> = [];
public function add_songSpecific_challenge(chall:Dynamic, song:String) {
    songSpecific_Challenges[song].push(chall);
}

var replace_strings:Array<String> = [
    "${song_name}", 
];

// TODO: Make it so a setting can toggle difficulty Challenges to be a specific difficulty array.
// So for example: if you want the easiest difficulty, its usually the first index of the array.
// so harder difficulties are the next index, and so on.

// for now it will use the hardest difficulty for that song (array.length-1 OR if it contains "hard" in the array)
function get_random_global(meta, ?exclude:Array<Int>) {
    if (exclude == null) exclude = [];

    var _random = FlxG.random.int(0, global_Challenges.length-1, exclude);
    var challenge = global_Challenges[_random].__itself();

    return set_challenge_data(challenge, meta, _random, "global");
}

function get_random_songSpecific(meta, ?exclude:Array<Int>) {
    if (meta == null) return null;
    if (exclude == null) exclude = [];
    
    var random_songChallenge = songSpecific_Challenges[meta.song];
    var _random = FlxG.random.int(0, random_songChallenge.length-1, exclude);
    var challenge = random_songChallenge[_random].__itself();

    return set_challenge_data(challenge, meta, _random, "songSpecific");
}

function set_challenge_data(challenge:Dynamic, meta:Dynamic, _random:Int, ?_type:String = "global") {
    if (_type == null) _type = "global";
    for (_replace in replace_strings) {
        challenge.name = switch(_replace) {
            case replace_strings[0]: StringTools.replace(challenge.name, _replace, (meta.displayName == null) ? meta.name : meta.displayName);
            default: challenge;
        };
    }
    challenge.setSongName(meta.name);

    return {
        _challData: challenge,
        random: _random,
        type: _type,
        songName: meta.name,
    };
}

public function get_randomChallenge(meta, ?exclude:Array<Int>) {
    var _length:Int = 0;
    for (_key in songSpecific_Challenges.keys()) _length++;
    var percentReal = (_length == 0) ? 100 : global_amount_percent;
    return (FlxG.random.bool(percentReal)) ? get_random_global(meta, exclude) : get_random_songSpecific(meta, exclude);
}
var defualt_challenge:Dynamic = {
    isChallenge: false,
    getChallenge: function() { return null; },
    getChallengeID: function() { return null; },
    getModName: function() { return null; }
};
defualt_challenge.__reset = (itself) -> { itself = Reflect.copy(defualt_challenge); }
public static var ljarcade_challenge = Reflect.copy(defualt_challenge);