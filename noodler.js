inlets = 4;

/*

0.	Bang - pick a new note. Note -> 0, consonance value -> 1.
	Reset - Output note=0 oct=5, reset curNote and curOct
1.	0.0 - 1.0: interval choice articulation point
2.	up/down prob.
3.	set pcset

*/

outlets = 3;

pcSetArray = [
	[[0, 1, 2, 3, 4], -5.884],
	[[0, 1, 2, 3, 5], -3.216],
	[[0, 2, 3, 4, 6], -3.095],
	[[0, 1, 2, 3, 6], -3.087],
	[[0, 1, 2, 4, 6], -2.449],
	[[0, 1, 2, 3, 7], -2.441],
	[[0, 1, 2, 4, 5], -2.248],
	[[0, 2, 4, 6, 8], -1.69],
	[[0, 1, 2, 6, 8], -1.674],
	[[0, 1, 2, 6, 7], -1.666],
	[[0, 1, 2, 4, 8], -1.481],
	[[0, 1, 2, 5, 6], -1.473],
	[[0, 1, 3, 4, 6], -1.065],
	[[0, 1, 2, 4, 7], -0.419],
	[[0, 1, 3, 5, 6], -0.419],
	[[0, 2, 3, 6, 8], -0.298],
	[[0, 1, 3, 6, 7], -0.29],
	[[0, 1, 3, 4, 7], -0.0969999999999997],
	[[0, 1, 3, 5, 7], 0.219],
	[[0, 1, 2, 5, 7], 0.227],
	[[0, 2, 3, 4, 7], 0.42],
	[[0, 2, 4, 5, 8], 0.541],
	[[0, 1, 4, 5, 7], 0.549],
	[[0, 1, 2, 5, 8], 0.549],
	[[0, 1, 3, 6, 9], 1.086],
	[[0, 1, 4, 6, 8], 1.187],
	[[0, 1, 5, 6, 8], 1.195],
	[[0, 3, 4, 5, 8], 1.388],
	[[0, 1, 3, 4, 8], 1.388],
	[[0, 1, 4, 7, 8], 1.517],
	[[0, 2, 3, 5, 8], 1.603],
	[[0, 2, 3, 5, 7], 2.12],
	[[0, 2, 4, 6, 9], 2.241],
	[[0, 1, 3, 6, 8], 2.249],
	[[0, 1, 4, 5, 8], 2.356],
	[[0, 1, 4, 6, 9], 2.571],
	[[0, 1, 3, 5, 8], 3.088],
	[[0, 2, 4, 7, 9], 4.788]
]

var huronTable = [1.428, -1.428, -0.582, 0.594, 0.386, 1.240, -0.453, 1.240, 0.386, 0.594, -0.582, -1.428];

var pcSet = [0, 2, 4, 7, 9];
var setHuron = 4.788;
var pcHuron = [2.0, 0.594, 1.240, 1.240, -0.582];
pcHuron = getHuron(pcSet);

var curPos = 0;
var curOct = 5;
var previousNote = 60;
var noteOffset = 0;

var intCurve = 0.5;
var upDownThresh = 0.5;

var needsReset = 1;

// The separation of reset() and resetVars() may seem baroque, but it is for timing reasons.
// reset() needs to be called at the end of a trial, while resetVars() needs to be called
// at the beginning. reset() just sets a flag so on the first note of a trial, everything 
// gets set. The vars can't be reset beforehand because during the intervening period the 
// pcSet may change.
function reset()
{
	needsReset = 1;
	
	/*
	post("Setting needsReset");
	post();
	*/
}

function resetVars()
{
	curPos = 0;
	curOct = 5;
	noteOffset = 0;
	
	// Select a random note offset:
	noteOffset = Math.floor(12*Math.random());
	
	octBias = 12 * curOct;												// Always: 12 * 5 = 60
	note = octBias + pcSet[curPos] + noteOffset;  // Always: 60 + 0 + noteOffset
	previousNote = note;  												// The initial previous note is the 0 of the pcSet.
	
	/*
	post("Resetting");
	post();
	*/
}

function playNote()
{	
	outlet(2, huronTable[Math.abs(note - previousNote)]);
	outlet(1, pcHuron[curPos]);
	outlet(0, note);
	previousNote = note;
}

function selectNextNote()
{
	interval = 0;
	intChoice = intervalCurve(Math.random());
	
	// Choose an interval:
	
	if(intChoice <= 0.25) {
		interval = 1;
	} else if(intChoice > 0.25 && intChoice <= 0.50) {
		interval = 2;
	} else if(intChoice > 0.50 && intChoice <= 0.75) {
		interval = 3;
	} else if(intChoice > 0.75 && intChoice <= 1.0) {
		interval = 4;
	}
	
	// Choose a direction:
	
	upDown = Math.random();
	if(upDown <= upDownThresh) {
		interval = interval * -1;
	}
	
	if((interval + curPos) > 4) {
		curOct += 1;
	} else if ((interval + curPos) < 0) {
		curOct -= 1;
	}
	
	// Loop at the extreme high and low edges:
	if(curOct == 0) {
		curOct = 1;
	} else if (curOct == 10) {
		curOct = 9;
	}
	
	if((curPos + interval) < 0) {
		curPos = 5 + (curPos + interval);
	} else {
		curPos = (curPos + interval) % 5;
	}
	
	octBias = 12 * curOct;
	note = octBias + pcSet[curPos] + noteOffset;
	
	/*
	post("interval: ");
	post(interval);
	post(" ");
	post(intChoice);
	post();
	post("curPos: ");
	post(curPos);
	post();
	post("curOct: ");
	post(curOct);
	post();
	post("note: ");
	post(note);
	post();
	*/
}

function bang()
{
	if(needsReset == 1) {
		needsReset = 0;
		resetVars();
	}
	selectNextNote();
	playNote();
}

function msg_float(f)
{
	if(inlet == 0) {
		// do nothing
	} else if(inlet == 1) {
		intCurve = f;
	} else if(inlet == 2) {
		upDownThresh = f;
	}
}

function msg_int(i) 
{
	if(inlet == 3) {
		pcSet = pcSetArray[i][0];
		setHuron = pcSetArray[i][1];
		pcHuron = getHuron(pcSet);
		//outlet(2, setHuron);
	}
}

function getHuron(pcs)
{
	newHuron = [0.0, 0.0, 0.0, 0.0, 0.0];
	for (var i=0; i<5; i++) {
		newHuron[i] = huronTable[pcs[i]];
	}
	return(newHuron);
}


function intervalCurve(x)
{
	a = intCurve;
	if(x<=a) {
		return((1.0 - a)/(0.0 - a))*x + 1;
	} else {
		return((0.0 - a)/(1.0 - a))*(x-1.0);
	}
}