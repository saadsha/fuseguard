import express from 'express';
import { User } from '../models/User.js';
import { protect, adminCheck } from '../middleware/authMiddleware.js';

const router = express.Router();

// @desc    Get all users
// @route   GET /api/users
// @access  Private/Admin
router.get('/', protect, adminCheck, async (req, res) => {
    try {
        const users = await User.find({}).select('-password');
        res.json(users);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Get total user count
// @route   GET /api/users/count
// @access  Private/Admin
router.get('/count', protect, adminCheck, async (req, res) => {
    try {
        const count = await User.countDocuments({});
        res.json({ count });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// @desc    Delete user
// @route   DELETE /api/users/:id
// @access  Private/Admin
router.delete('/:id', protect, adminCheck, async (req, res) => {
    try {
        const user = await User.findById(req.params.id);

        if (user) {
            await user.deleteOne();
            res.json({ message: 'User removed' });
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

export default router;
