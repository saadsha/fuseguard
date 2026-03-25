import express from 'express';
import { Transformer } from '../models/Transformer.js';
import { FaultLog } from '../models/FaultLog.js';


const router = express.Router();

// @desc    Receive telemetry from NodeMCU
// @route   POST /api/iot/data
// @access  Public (In production, use an API Key/Token here)
router.post('/data', async (req, res) => {
    try {
        const { transformerId, currentVoltage, currentAmperage, fuseData } = req.body;
        // Expected fuseData format: [{ fuseId: 'F1', continuity: true/false }]

        const transformer = await Transformer.findOne({ transformerId });

        if (!transformer) {
            return res.status(404).json({ message: 'Transformer not found' });
        }

        let hasFault = false;
        let faultMessages = [];

        // Check thresholds
        // if (currentVoltage > transformer.voltageThreshold) {
        //   hasFault = true;
        //   faultMessages.push('Overvoltage');
        // }

        // Update individual fuse statuses
        const updatedFuses = transformer.fuses.map(fuse => {
            const incomingFuseData = fuseData.find(f => f.fuseId === fuse.fuseId);

            let newStatus = fuse.status;
            if (incomingFuseData) {
                newStatus = incomingFuseData.continuity ? 'Healthy' : 'Blown';

                if (newStatus === 'Blown') {
                    hasFault = true;
                    // Only log it if it was PREVIOUSLY healthy (prevent spamming the DB every 5 seconds)
                    if (fuse.status === 'Healthy') {
                        faultMessages.push(`Fuse ${fuse.fuseId} Blown`);
                        FaultLog.create({
                            transformerId: transformer._id,
                            fuseId: fuse.fuseId,
                            faultType: 'Blown Fuse'
                        }).catch(err => console.error("Error creating fault log:", err));
                    }
                }
            }
            return {
                ...fuse.toObject(),
                status: newStatus,
                lastUpdated: Date.now()
            };
        });

        transformer.currentVoltage = currentVoltage;
        transformer.currentAmperage = currentAmperage;
        transformer.fuses = updatedFuses;
        transformer.status = hasFault ? 'Fault' : 'Healthy';

        await transformer.save();

        // Broadcast the update via web sockets
        const io = req.app.get('io');
        if (io) {
            io.emit('transformerUpdate', transformer);
        }

        res.status(200).json({ message: 'Data received and processed', status: transformer.status });
    } catch (error) {
        console.error('IoT Data Error:', error);
        res.status(500).json({ message: 'Server error parsing IoT data' });
    }
});

export default router;
