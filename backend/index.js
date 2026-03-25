import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import dotenv from 'dotenv';
import { createServer } from 'http';
import { Server } from 'socket.io';

// Routes
import authRoutes from './routes/authRoutes.js';
import transformerRoutes from './routes/transformerRoutes.js';
import iotRoutes from './routes/iotRoutes.js';
import faultRoutes from './routes/faultRoutes.js';
import userRoutes from './routes/userRoutes.js';
import { Transformer } from './models/Transformer.js';

dotenv.config();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
    cors: {
        origin: '*', // Allow Flutter web client
        methods: ['GET', 'POST', 'PUT', 'DELETE']
    }
});

app.use(cors());
app.use(express.json());

// Set io instance globally for routes
app.set('io', io);

// Basic route
app.get('/', (req, res) => {
    res.send('FuseGuard API is running');
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/transformers', transformerRoutes);
app.use('/api/iot', iotRoutes);
app.use('/api/faults', faultRoutes);
app.use('/api/users', userRoutes);

import { MongoMemoryServer } from 'mongodb-memory-server';

const PORT = process.env.PORT || 5000;

// MongoDB Connection
const startServer = async () => {
    try {
        let MONGO_URI = process.env.MONGO_URI;

        if (!MONGO_URI) {
            console.log('No MONGO_URI provided, starting in-memory MongoDB instance...');
            const mongoServer = await MongoMemoryServer.create();
            MONGO_URI = mongoServer.getUri();
        }

        await mongoose.connect(MONGO_URI);
        console.log(`Connected to MongoDB at ${MONGO_URI}`);

        // Auto-seed if in-memory
        if (!process.env.MONGO_URI) {
            const count = await Transformer.countDocuments();
            if (count === 0) {
                console.log('Seeding initial data...');
                const transformers = [
                    {
                        transformerId: 'TX-SIM-1',
                        location: 'Downtown Substation Alpha',
                        status: 'Healthy',
                        voltageThreshold: 250,
                        currentThreshold: 60,
                        currentVoltage: 230.5,
                        currentAmperage: 50.2,
                        fuses: [
                            { fuseId: 'F1', status: 'Healthy', rating: 100 },
                            { fuseId: 'F2', status: 'Healthy', rating: 100 },
                            { fuseId: 'F3', status: 'Healthy', rating: 100 }
                        ]
                    },
                    {
                        transformerId: 'TX-REAL-1',
                        location: 'Main Power Grid - Testing Site',
                        status: 'Healthy',
                        voltageThreshold: 250,
                        currentThreshold: 60,
                        currentVoltage: 230.0,
                        currentAmperage: 50.0,
                        fuses: [
                            { fuseId: 'F1', status: 'Healthy', rating: 100 },
                            { fuseId: 'F2', status: 'Healthy', rating: 100 },
                            { fuseId: 'F3', status: 'Healthy', rating: 100 }
                        ]
                    }
                ];
                await Transformer.insertMany(transformers);
                console.log('Auto-seed complete.');
            }
        }

        httpServer.listen(PORT, '0.0.0.0', () => {
            console.log(`Server running on port ${PORT} and bound to 0.0.0.0`);
        });
    } catch (err) {
        console.error('MongoDB connection error:', err);
    }
};

startServer();


// Socket.io for Real-time
io.on('connection', (socket) => {
    console.log('A client connected:', socket.id);

    socket.on('acceptJob', (data) => {
        // Broadcast to all other clients that this job has been accepted
        socket.broadcast.emit('jobAccepted', { transformerId: data.transformerId });
    });

    socket.on('disconnect', () => {
        console.log('Client disconnected:', socket.id);
    });
});

export { io };
