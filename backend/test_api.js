import fetch from 'node-fetch';

const testAPI = async () => {
    try {
        const loginRes = await fetch('http://localhost:5000/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: 'admin@fuseguard.com', password: 'password123' })
        });
        const loginData = await loginRes.json();
        const token = loginData.token;

        const txRes = await fetch('http://localhost:5000/api/transformers', {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const txData = await txRes.json();
        console.log("Transformers API Output:");
        console.log(JSON.stringify(txData, null, 2));
    } catch (e) {
        console.error(e);
    }
}
testAPI();
