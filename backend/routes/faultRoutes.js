import express from 'express';
import { FaultLog } from '../models/FaultLog.js';
import { protect, engineerCheck } from '../middleware/authMiddleware.js';

const router = express.Router();

// @desc    Get all fault logs
// @route   GET /api/faults
// @access  Private
router.get('/', protect, async (req, res) => {
    try {
        const faults = await FaultLog.find({}).populate('transformerId', 'transformerId location');
        res.json(faults);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Update fault status to Resolved
// @route   PUT /api/faults/:id/resolve
// @access  Private/Engineer
router.put('/:id/resolve', protect, engineerCheck, async (req, res) => {
    try {
        const fault = await FaultLog.findById(req.params.id);

        if (fault) {
            fault.status = 'Resolved';
            fault.resolvedBy = req.user._id;
            fault.resolvedAt = Date.now();

            const updatedFault = await fault.save();
            res.json(updatedFault);
        } else {
            res.status(404).json({ message: 'Fault log not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

export default router;
