import fetch from 'node-fetch';

const registerUser = async () => {
    try {
        const res = await fetch('http://localhost:5000/api/auth/register', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                name: 'Test Admin',
                email: 'admin@fuseguard.com',
                password: 'password123',
                role: 'Admin'
            })
        });
        const data = await res.json();
        console.log(data);
    } catch (err) {
        console.error(err);
    }
}

registerUser();
