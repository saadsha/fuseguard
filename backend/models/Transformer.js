import mongoose from 'mongoose';

const fuseSchema = new mongoose.Schema({
    fuseId: { type: String, required: true }, // E.g., F1, F2
    status: { type: String, enum: ['Healthy', 'Blown'], default: 'Healthy' },
    lastUpdated: { type: Date, default: Date.now }
});

const transformerSchema = new mongoose.Schema({
    transformerId: { type: String, required: true, unique: true },
    location: { type: String, required: true },
    voltageThreshold: { type: Number, required: true },
    currentThreshold: { type: Number, required: true },
    currentVoltage: { type: Number, default: 0 },
    currentAmperage: { type: Number, default: 0 },
    fuses: [fuseSchema],
    status: { type: String, enum: ['Healthy', 'Fault'], default: 'Healthy' },
}, { timestamps: true });

export const Transformer = mongoose.model('Transformer', transformerSchema);
