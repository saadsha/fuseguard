import fetch from 'node-fetch';
import readline from 'readline';

const API_URL = 'http://127.0.0.1:5000/api/iot/data';
const transformerId = 'TX-SIM-2'; // Target one of the simulated bots

// Initial hardware states
let currentVoltage = 230.0;
let currentAmperage = 50.0;

// HIGH = Continuity (Healthy). LOW = Break (Blown)
let fuseStates = {
    'F1': 'HIGH',
    'F2': 'HIGH',
    'F3': 'HIGH'
};

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

const sendPayload = async () => {
    const fuseData = [
        { fuseId: 'F1', continuity: fuseStates['F1'] === 'HIGH' },
        { fuseId: 'F2', continuity: fuseStates['F2'] === 'HIGH' },
        { fuseId: 'F3', continuity: fuseStates['F3'] === 'HIGH' }
    ];

    const payload = {
        transformerId,
        currentVoltage,
        currentAmperage,
        fuseData
    };

    try {
        const res = await fetch(API_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        console.log(`\n[API Response]: ${data.message} | Status: ${data.status}\n`);
    } catch (err) {
        console.error(`\n[Error sending data]:`, err.message, '\n');
    }

    promptCommand();
};

const displayStatus = () => {
    console.log('\n--- Current Simulated NodeMCU State ---');
    console.log(`Transformer: ${transformerId}`);
    console.log(`Voltage:     ${currentVoltage}V`);
    console.log(`Amperage:    ${currentAmperage}A`);
    console.log(`Fuse F1:     ${fuseStates['F1']} (Pin D1)`);
    console.log(`Fuse F2:     ${fuseStates['F2']} (Pin D2)`);
    console.log(`Fuse F3:     ${fuseStates['F3']} (Pin D3)`);
    console.log('---------------------------------------\n');
};

const promptCommand = () => {
    console.log('Available Commands:');
    console.log('  1. Toggle Fuse F1 (High/Low)');
    console.log('  2. Toggle Fuse F2 (High/Low)');
    console.log('  3. Toggle Fuse F3 (High/Low)');
    console.log('  4. Set Voltage Spike (e.g. 250V)');
    console.log('  5. Send Payload to API');
    console.log('  6. View Status');
    console.log('  0. Exit');

    rl.question('Select option [0-6]: ', (answer) => {
        switch (answer.trim()) {
            case '1':
                fuseStates['F1'] = fuseStates['F1'] === 'HIGH' ? 'LOW' : 'HIGH';
                console.log(`--> F1 PIN IS NOW ${fuseStates['F1']}`);
                promptCommand();
                break;
            case '2':
                fuseStates['F2'] = fuseStates['F2'] === 'HIGH' ? 'LOW' : 'HIGH';
                console.log(`--> F2 PIN IS NOW ${fuseStates['F2']}`);
                promptCommand();
                break;
            case '3':
                fuseStates['F3'] = fuseStates['F3'] === 'HIGH' ? 'LOW' : 'HIGH';
                console.log(`--> F3 PIN IS NOW ${fuseStates['F3']}`);
                promptCommand();
                break;
            case '4':
                rl.question('Enter new voltage: ', (v) => {
                    const parsed = parseFloat(v);
                    if (!isNaN(parsed)) currentVoltage = parsed;
                    console.log(`--> VOLTAGE SENSOR READING CHANGED TO ${currentVoltage}V`);
                    promptCommand();
                });
                break;
            case '5':
                console.log('--> SENDING HTTP REQUEST TO /api/iot/data...');
                sendPayload(); // Note: sendPayload calls promptCommand inside
                break;
            case '6':
                displayStatus();
                promptCommand();
                break;
            case '0':
                console.log('Exiting interactive simulator.');
                rl.close();
                process.exit(0);
                break;
            default:
                console.log('Invalid command. Try again.');
                promptCommand();
        }
    });
};

console.log('=======================================');
console.log('   INTERACTIVE NODEMCU SIMULATOR CLI   ');
console.log('=======================================');
displayStatus();
promptCommand();
