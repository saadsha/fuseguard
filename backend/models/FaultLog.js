import mongoose from 'mongoose';

const faultLogSchema = new mongoose.Schema({
    transformerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Transformer', required: true },
    fuseId: { type: String, required: true },
    faultType: { type: String, required: true }, // E.g., 'Blown Fuse', 'Overvoltage'
    status: { type: String, enum: ['Active', 'Resolved'], default: 'Active' },
    resolvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    resolvedAt: { type: Date }
}, { timestamps: true });

export const FaultLog = mongoose.model('FaultLog', faultLogSchema);
