import { useState, useEffect } from 'react';

const ModuleModal = ({ isOpen, onClose, onSave, module, instruments, modules = [] }) => {
    const [formData, setFormData] = useState({
        title: '',
        description: '',
        instrument: '',
        order: 1,
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const filteredInstruments = instruments.filter(inst => {
        const name = inst.name.toLowerCase();
        return name.includes('piano') || name.includes('vocal');
    });

    useEffect(() => {
        if (module) {
            setFormData({
                title: module.title || '',
                description: module.description || '',
                instrument: module.instrument || '',
                order: module.order || 1,
            });
        } else {
            setFormData({ 
                title: '', 
                description: '', 
                instrument: filteredInstruments?.[0]?.id || '', 
                order: 1 
            });
        }
        setError('');
    }, [module, isOpen, instruments]);

    if (!isOpen) return null;

    const handleChange = (e) => {
        const val = e.target.type === 'number' ? parseInt(e.target.value) || 0 : e.target.value;
        setFormData({ ...formData, [e.target.name]: val });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        const isDuplicate = modules.some(m => 
            String(m.instrument) === String(formData.instrument) && 
            parseInt(m.order) === parseInt(formData.order) &&
            (module ? m.id !== module.id : true)
        );

        if (isDuplicate) {
            setError(`A Level with order ${formData.order} already exists for this instrument.`);
            setLoading(false);
            return;
        }

        try {
            await onSave(formData, module ? module.id : null);
            onClose();
        } catch (err) {
            setError(err.response?.data?.detail || JSON.stringify(err.response?.data) || 'An error occurred.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="modal-content lesson-modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '500px', maxHeight: '90vh', overflow: 'auto' }}>
                <h2>{module ? 'Edit Module (Level)' : 'Add New Module (Level)'}</h2>
                {error && <div className="login-error">{error}</div>}
                <form onSubmit={handleSubmit} className="modal-form">
                    <div className="form-row">
                        <div className="form-group">
                            <label>Instrument</label>
                            <select name="instrument" value={formData.instrument} onChange={handleChange} required>
                                <option value="">Select instrument...</option>
                                {filteredInstruments.map(inst => (
                                    <option key={inst.id} value={inst.id}>{inst.name}</option>
                                ))}
                            </select>
                        </div>
                        <div className="form-group">
                            <label>Level / Order</label>
                            <input type="number" name="order" value={formData.order} onChange={handleChange} min={1} required />
                        </div>
                    </div>

                    <div className="form-group">
                        <label>Title <span style={{ fontWeight: 400, color: 'var(--text-muted)' }}>(Max 200 chars)</span></label>
                        <input name="title" value={formData.title} onChange={handleChange} placeholder="e.g. Masterclass" required />
                    </div>

                    <div className="form-group">
                        <label>Description <span style={{ fontWeight: 400, color: 'var(--text-muted)' }}>(Optional)</span></label>
                        <textarea name="description" value={formData.description} onChange={handleChange} rows={3} placeholder="Brief description of this level's focus..." style={{
                            width: '100%', fontSize: '0.9rem', border: '1px solid var(--border)', borderRadius: '6px', padding: '8px', boxSizing: 'border-box'
                        }} />
                    </div>

                    <div className="modal-actions" style={{ marginTop: '20px' }}>
                        <button type="button" className="btn-outline" onClick={onClose}>Cancel</button>
                        <button type="submit" className="btn-primary" disabled={loading}>
                            {loading ? 'Saving...' : module ? 'Update Module' : 'Create Module'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default ModuleModal;
