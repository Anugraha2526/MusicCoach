import { useState, useEffect } from 'react';

const UserModal = ({ isOpen, onClose, onSave, user }) => {
    const [formData, setFormData] = useState({
        username: '',
        email: '',
        first_name: '',
        last_name: '',
        role: 'user',
        is_active: true,
        password: ''
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (user) {
            setFormData({
                username: user.username || '',
                email: user.email || '',
                first_name: user.first_name || '',
                last_name: user.last_name || '',
                role: user.role || 'user',
                is_active: user.is_active,
                password: ''
            });
        } else {
            setFormData({
                username: '',
                email: '',
                first_name: '',
                last_name: '',
                role: 'user',
                is_active: true,
                password: ''
            });
        }
        setError('');
    }, [user, isOpen]);

    if (!isOpen) return null;

    const handleChange = (e) => {
        const value = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
        setFormData({ ...formData, [e.target.name]: value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        // Remove empty password if editing so we don't accidentally update it to blank
        const submitData = { ...formData };
        if (user && !submitData.password) {
            delete submitData.password;
        }

        try {
            await onSave(submitData, user ? user.id : null);
            onClose();
        } catch (err) {
            setError(err.response?.data?.detail || err.response?.data?.username?.[0] || 'An error occurred.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                <h2>{user ? 'Edit User' : 'Add New User'}</h2>
                {error && <div className="login-error">{error}</div>}
                <form onSubmit={handleSubmit} className="modal-form">
                    <div className="form-row">
                        <div className="form-group">
                            <label>Username</label>
                            <input name="username" value={formData.username} onChange={handleChange} required />
                        </div>
                        <div className="form-group">
                            <label>Email</label>
                            <input type="email" name="email" value={formData.email} onChange={handleChange} required />
                        </div>
                    </div>

                    <div className="form-row">
                        <div className="form-group">
                            <label>First Name</label>
                            <input name="first_name" value={formData.first_name} onChange={handleChange} />
                        </div>
                        <div className="form-group">
                            <label>Last Name</label>
                            <input name="last_name" value={formData.last_name} onChange={handleChange} />
                        </div>
                    </div>

                    <div className="form-row">
                        <div className="form-group">
                            <label>Role</label>
                            <select name="role" value={formData.role} onChange={handleChange}>
                                <option value="user">User</option>
                                <option value="admin">Admin</option>
                            </select>
                        </div>
                        <div className="form-group">
                            <label>Password {user && <span className="helper-text">(Leave blank to keep current)</span>}</label>
                            <input type="password" name="password" value={formData.password} onChange={handleChange} minLength={8} required={!user} />
                        </div>
                    </div>

                    <div className="form-group checkbox-group">
                        <label>
                            <input type="checkbox" name="is_active" checked={formData.is_active} onChange={handleChange} />
                            Account is Active
                        </label>
                    </div>

                    <div className="modal-actions">
                        <button type="button" className="btn-outline" onClick={onClose}>Cancel</button>
                        <button type="submit" className="btn-primary" disabled={loading}>
                            {loading ? 'Saving...' : 'Save User'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
};
export default UserModal;
