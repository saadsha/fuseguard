import fetch from 'node-fetch';

const registerEngineer = async () => {
    try {
        const res = await fetch('http://127.0.0.1:5000/api/auth/register', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                name: 'Test Engineer',
                email: 'engineer@fuseguard.com',
                password: 'password123',
                role: 'Engineer'
            })
        });
        const data = await res.json();
        console.log("Engineer user created:");
        console.log(data);
    } catch (err) {
        console.error("Error creating engineer:", err);
    }
}

registerEngineer();
