import { useState, useEffect } from 'react';

const LESSON_TYPES = [
    { value: 'theory', label: 'Theory' },
    { value: 'practice', label: 'Practice' },
    { value: 'quiz', label: 'Quiz' },
];

const SEQUENCE_TYPES = [
    { value: 'listen', label: 'Listen & Repeat (Simon Says)' },
    { value: 'learn', label: 'Learn Note' },
    { value: 'identify', label: 'Identify Note (Drag & Drop)' },
    { value: 'read', label: 'Sight Reading' },
    { value: 'play', label: 'Play at Own Pace' },
    { value: 'perform', label: 'Perform (Scored)' },
    { value: 'tap', label: 'Tap Mode' },
    { value: 'place', label: 'Place Note' },
];

const formatSequenceArray = (array, timeSig) => {
    if (!Array.isArray(array) || array.length === 0) return '[]';
    
    let elementsPerBar = 8; // Default 4/4 assumes 2 elements per beat (8th notes)
    if (timeSig) {
        const parts = timeSig.split('/');
        if (parts.length === 2) {
            const beats = parseInt(parts[0]) || 4;
            const beatType = parseInt(parts[1]) || 4;
            if (beatType === 4) elementsPerBar = beats * 2;
            else if (beatType === 8) elementsPerBar = beats;
        }
    }

    let result = '[\n  ';
    for (let i = 0; i < array.length; i++) {
        result += JSON.stringify(array[i]);
        if (i < array.length - 1) {
            result += ', ';
        }
        if ((i + 1) % elementsPerBar === 0 && i < array.length - 1) {
            result += '\n  ';
        }
    }
    result += '\n]';
    return result;
};

const LessonModal = ({ isOpen, onClose, onSave, lesson, modules }) => {
    const [formData, setFormData] = useState({
        module: '',
        title: '',
        lesson_type: 'practice',
        order: 1,
    });
    const [sequences, setSequences] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (lesson) {
            setFormData({
                module: lesson.module || '',
                title: lesson.title || '',
                lesson_type: lesson.lesson_type || 'practice',
                order: lesson.order || 1,
            });
            setSequences(
                (lesson.sequences || []).map(s => ({
                    sequence_type: s.sequence_type,
                    order: s.order,
                    notes: formatSequenceArray(s.notes, s.time_signature || '4/4'),
                    lyrics: s.lyrics ? formatSequenceArray(s.lyrics, s.time_signature || '4/4') : '',
                    time_signature: s.time_signature || '4/4',
                }))
            );
        } else {
            setFormData({ module: modules?.[0]?.id || '', title: '', lesson_type: 'practice', order: 1 });
            setSequences([]);
        }
        setError('');
    }, [lesson, isOpen, modules]);

    if (!isOpen) return null;

    const handleChange = (e) => {
        const val = e.target.type === 'number' ? parseInt(e.target.value) || 0 : e.target.value;
        setFormData({ ...formData, [e.target.name]: val });
    };

    const handleSeqChange = (idx, field, value) => {
        const updated = [...sequences];
        updated[idx] = { ...updated[idx], [field]: value };
        setSequences(updated);
    };

    const addSequence = () => {
        setSequences([...sequences, {
            sequence_type: 'listen',
            order: sequences.length + 1,
            notes: '[\n  "C3", "=", "-", "-", "-", "-", "-", "-"\n]',
            lyrics: '',
            time_signature: '4/4',
        }]);
    };

    const removeSequence = (idx) => {
        setSequences(sequences.filter((_, i) => i !== idx));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        // Parse sequence notes/lyrics from JSON strings
        let parsedSequences;
        try {
            parsedSequences = sequences.map((s, i) => {
                let notes;
                try { notes = JSON.parse(s.notes); } catch { throw new Error(`Sequence ${i + 1}: Invalid JSON in notes`); }
                let lyrics = null;
                if (s.lyrics && s.lyrics.trim()) {
                    try { lyrics = JSON.parse(s.lyrics); } catch { throw new Error(`Sequence ${i + 1}: Invalid JSON in lyrics`); }
                }
                return {
                    sequence_type: s.sequence_type,
                    order: parseInt(s.order) || i + 1,
                    notes,
                    lyrics,
                    time_signature: s.time_signature || '4/4',
                };
            });
        } catch (parseErr) {
            setError(parseErr.message);
            setLoading(false);
            return;
        }

        const payload = {
            ...formData,
            sequences: parsedSequences,
        };

        try {
            await onSave(payload, lesson ? lesson.id : null);
            onClose();
        } catch (err) {
            setError(err.response?.data?.detail || JSON.stringify(err.response?.data) || 'An error occurred.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="modal-overlay" onClick={onClose}>
            <div className="modal-content lesson-modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '780px', maxHeight: '90vh', overflow: 'auto' }}>
                <h2>{lesson ? 'Edit Lesson' : 'Add New Lesson'}</h2>
                {error && <div className="login-error">{error}</div>}
                <form onSubmit={handleSubmit} className="modal-form">
                    <div className="form-row">
                        <div className="form-group">
                            <label>Module</label>
                            <select name="module" value={formData.module} onChange={handleChange} required>
                                <option value="">Select module...</option>
                                {modules.map(m => (
                                    <option key={m.id} value={m.id}>{m.title} ({m.instrument_name})</option>
                                ))}
                            </select>
                        </div>
                        <div className="form-group">
                            <label>Order</label>
                            <input type="number" name="order" value={formData.order} onChange={handleChange} min={1} required />
                        </div>
                    </div>

                    <div className="form-row">
                        <div className="form-group">
                            <label>Title</label>
                            <input name="title" value={formData.title} onChange={handleChange} required placeholder="e.g. Introduction to Piano" />
                        </div>
                        <div className="form-group">
                            <label>Lesson Type</label>
                            <select name="lesson_type" value={formData.lesson_type} onChange={handleChange}>
                                {LESSON_TYPES.map(t => (
                                    <option key={t.value} value={t.value}>{t.label}</option>
                                ))}
                            </select>
                        </div>
                    </div>

                    <div style={{ borderTop: '1px solid var(--border)', marginTop: '20px', paddingTop: '20px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                            <h3 style={{ margin: 0, fontSize: '1.05rem' }}>Practice Sequences</h3>
                            <button type="button" className="btn-primary" onClick={addSequence}
                                style={{ fontSize: '0.85rem', padding: '6px 14px' }}>
                                + Add Sequence
                            </button>
                        </div>

                        {sequences.length === 0 && (
                            <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', textAlign: 'center', padding: '20px' }}>
                                No sequences added yet. Click "Add Sequence" to create one.
                            </p>
                        )}

                        {sequences.map((seq, idx) => (
                            <div key={idx} style={{
                                border: '1px solid var(--border)',
                                borderRadius: '10px',
                                padding: '16px',
                                marginBottom: '14px',
                                background: '#fafbfc',
                                position: 'relative',
                            }}>
                                <button type="button" onClick={() => removeSequence(idx)}
                                    style={{
                                        position: 'absolute', top: '8px', right: '10px',
                                        background: 'none', border: 'none', color: 'var(--danger)',
                                        cursor: 'pointer', fontSize: '1.1rem', fontWeight: 'bold',
                                    }}>✕</button>
                                <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '10px', fontWeight: 600 }}>
                                    Sequence #{idx + 1}
                                </div>
                                <div className="form-row">
                                    <div className="form-group">
                                        <label>Type</label>
                                        <select value={seq.sequence_type}
                                            onChange={e => handleSeqChange(idx, 'sequence_type', e.target.value)}>
                                            {SEQUENCE_TYPES.map(t => (
                                                <option key={t.value} value={t.value}>{t.label}</option>
                                            ))}
                                        </select>
                                    </div>
                                    <div className="form-group" style={{ flex: '0 0 80px' }}>
                                        <label>Order</label>
                                        <input type="number" value={seq.order}
                                            onChange={e => handleSeqChange(idx, 'order', e.target.value)} min={1} />
                                    </div>
                                    <div className="form-group" style={{ flex: '0 0 90px' }}>
                                        <label>Time Sig.</label>
                                        <input value={seq.time_signature}
                                            onChange={e => handleSeqChange(idx, 'time_signature', e.target.value)}
                                            placeholder="4/4" />
                                    </div>
                                </div>
                                <div className="form-group" style={{ marginTop: '8px' }}>
                                    <label>Notes <span style={{ fontWeight: 400, color: 'var(--text-muted)' }}>(JSON array, e.g. ["C", "D", "E"])</span></label>
                                    <textarea value={seq.notes}
                                        onChange={e => handleSeqChange(idx, 'notes', e.target.value)}
                                        rows={8}
                                        style={{
                                            width: '100%', fontFamily: 'monospace', fontSize: '0.85rem',
                                            border: '1px solid var(--border)', borderRadius: '6px',
                                            padding: '8px', resize: 'vertical', boxSizing: 'border-box',
                                            whiteSpace: 'pre',
                                        }}
                                    />
                                </div>
                                <div className="form-group" style={{ marginTop: '8px' }}>
                                    <label>Lyrics <span style={{ fontWeight: 400, color: 'var(--text-muted)' }}>(Optional JSON array, same length as notes)</span></label>
                                    <textarea value={seq.lyrics}
                                        onChange={e => handleSeqChange(idx, 'lyrics', e.target.value)}
                                        rows={4}
                                        placeholder='Leave empty if no lyrics'
                                        style={{
                                            width: '100%', fontFamily: 'monospace', fontSize: '0.85rem',
                                            border: '1px solid var(--border)', borderRadius: '6px',
                                            padding: '8px', resize: 'vertical', boxSizing: 'border-box',
                                            whiteSpace: 'pre',
                                        }}
                                    />
                                </div>
                            </div>
                        ))}
                    </div>

                    <div className="modal-actions">
                        <button type="button" className="btn-outline" onClick={onClose}>Cancel</button>
                        <button type="submit" className="btn-primary" disabled={loading}>
                            {loading ? 'Saving...' : lesson ? 'Update Lesson' : 'Create Lesson'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default LessonModal;
