import fetch from 'node-fetch';
import fs from 'fs';

async function testFaults() {
    const loginRes = await fetch('http://localhost:5000/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'admin@fuseguard.com', password: 'password123' })
    });
    const auth = await loginRes.json();

    const faultsRes = await fetch('http://localhost:5000/api/faults', {
        headers: { 'Authorization': `Bearer ${auth.token}` }
    });
    const faults = await faultsRes.json();
    fs.writeFileSync('faults_output.json', JSON.stringify(faults, null, 2));
    console.log('Wrote faults to faults_output.json');
}

testFaults();
