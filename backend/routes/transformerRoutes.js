import express from 'express';
import { Transformer } from '../models/Transformer.js';
import { protect, adminCheck } from '../middleware/authMiddleware.js';

const router = express.Router();

// @desc    Get all transformers
// @route   GET /api/transformers
// @access  Private (All authenticated users can view)
router.get('/', protect, async (req, res) => {
    try {
        const transformers = await Transformer.find({});
        res.json(transformers);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Create a transformer
// @route   POST /api/transformers
// @access  Private/Admin
router.post('/', protect, adminCheck, async (req, res) => {
    try {
        const { transformerId, location, voltageThreshold, currentThreshold, fuses } = req.body;

        const transformerExists = await Transformer.findOne({ transformerId });
        if (transformerExists) {
            return res.status(400).json({ message: 'Transformer ID already exists' });
        }

        const newTransformer = new Transformer({
            transformerId,
            location,
            voltageThreshold,
            currentThreshold,
            fuses: fuses || [] // Format: [{ fuseId: 'F1', status: 'Healthy' }]
        });

        const createdTransformer = await newTransformer.save();
        res.status(201).json(createdTransformer);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Update a transformer
// @route   PUT /api/transformers/:id
// @access  Private/Admin
router.put('/:id', protect, adminCheck, async (req, res) => {
    try {
        const { transformerId, location, voltageThreshold, currentThreshold, fuses } = req.body;

        const transformer = await Transformer.findById(req.params.id);

        if (transformer) {
            transformer.transformerId = transformerId || transformer.transformerId;
            transformer.location = location || transformer.location;
            transformer.voltageThreshold = voltageThreshold || transformer.voltageThreshold;
            transformer.currentThreshold = currentThreshold || transformer.currentThreshold;
            if (fuses) {
                transformer.fuses = fuses;
            }

            const updatedTransformer = await transformer.save();
            res.json(updatedTransformer);
        } else {
            res.status(404).json({ message: 'Transformer not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Delete a transformer
// @route   DELETE /api/transformers/:id
// @access  Private/Admin
router.delete('/:id', protect, adminCheck, async (req, res) => {
    try {
        const transformer = await Transformer.findById(req.params.id);

        if (transformer) {
            await transformer.deleteOne();
            res.json({ message: 'Transformer removed' });
        } else {
            res.status(404).json({ message: 'Transformer not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

export default router;
