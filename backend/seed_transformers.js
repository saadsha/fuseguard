import mongoose from 'mongoose';
import { Transformer } from './models/Transformer.js';

const MONGO_URI = 'mongodb://127.0.0.1:53326/';

const seedTransformers = async () => {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('Connected to DB');

        // Clear existing just in case
        await Transformer.deleteMany({});

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
                transformerId: 'TX-SIM-2',
                location: 'Industrial Park Beta',
                status: 'Healthy',
                voltageThreshold: 400,
                currentThreshold: 150,
                currentVoltage: 380.0,
                currentAmperage: 120.0,
                fuses: [
                    { fuseId: 'F1', status: 'Healthy', rating: 200 },
                    { fuseId: 'F2', status: 'Healthy', rating: 200 }
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
        console.log('Successfully seeded 3 Transformers (TX-SIM-1, TX-SIM-2, TX-REAL-1)');
        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

seedTransformers();
