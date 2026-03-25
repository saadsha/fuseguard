import fetch from 'node-fetch';

const API_URL = 'http://localhost:5000/api/iot/data';

const transformers = [
    { id: 'TX-SIM-1', fuses: ['F1', 'F2', 'F3'] },
    { id: 'TX-SIM-2', fuses: ['F1', 'F2'] }
];

async function simulateData() {
    for (const t of transformers) {

        // Simulate some variance in voltage and current
        const volts = 230 + (Math.random() * 20 - 10);
        const amps = 50 + (Math.random() * 20 - 10);

        // 10% chance of a fuse blowing in the simulation
        const fuseData = t.fuses.map(f => ({
            fuseId: f,
            continuity: Math.random() > 0.05 // 95% healthy
        }));

        const payload = {
            transformerId: t.id,
            currentVoltage: parseFloat(volts.toFixed(2)),
            currentAmperage: parseFloat(amps.toFixed(2)),
            fuseData: fuseData
        };

        try {
            console.log(`Sending data for ${t.id}...`);
            const res = await fetch(API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            const data = await res.json();
            console.log(`Response: ${data.message} | Status: ${data.status}`);
        } catch (err) {
            console.error(`Error sending for ${t.id}:`, err.message);
        }
    }
}

// Run every 5 seconds
console.log('Starting IoT NodeMCU Simulator...');
setInterval(simulateData, 5000);
simulateData();
