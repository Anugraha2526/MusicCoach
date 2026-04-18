import { useState, useEffect } from 'react';
import { Edit, Trash2, Plus, ChevronDown, ChevronRight, Music, Mic } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import LessonModal from '../components/LessonModal';
import ModuleModal from '../components/ModuleModal';
import api from '../api/axios';

const Lessons = () => {
    const [modules, setModules] = useState([]);
    const [expandedModules, setExpandedModules] = useState({});
    const [instrumentFilter, setInstrumentFilter] = useState('all');
    const [instruments, setInstruments] = useState([]);
    
    // Modals state
    const [isLessonModalOpen, setIsLessonModalOpen] = useState(false);
    const [editingLesson, setEditingLesson] = useState(null);
    const [isModuleModalOpen, setIsModuleModalOpen] = useState(false);
    const [editingModule, setEditingModule] = useState(null);
    
    const { getToken } = useAuth();
    const token = getToken();

    const fetchModules = async () => {
        try {
            const res = await api.get('accounts/admin/modules/');
            setModules(res.data);
        } catch (err) {
            console.error("Failed to fetch modules", err);
        }
    };

    const fetchInstruments = async () => {
        try {
            const res = await api.get('accounts/admin/instruments/');
            setInstruments(res.data);
            if (res.data.length > 0 && instrumentFilter === 'piano') { // removed to use 'all' by default
            }
        } catch (err) {
            console.error("Failed to fetch instruments", err);
        }
    };

    useEffect(() => {
        if (token) {
            fetchModules();
            fetchInstruments();
        }
    }, [token]);

    const toggleModule = (id) => {
        setExpandedModules(prev => ({ ...prev, [id]: !prev[id] }));
    };

    const filteredModules = instrumentFilter === 'all'
        ? modules
        : modules.filter(m => m.instrument_name?.toLowerCase().includes(instrumentFilter));

    const handleSaveLesson = async (data, id) => {
        if (id) {
            await api.put(`accounts/admin/lessons/${id}/`, data);
        } else {
            await api.post('accounts/admin/lessons/', data);
        }
        fetchModules();
    };

    const handleDeleteLesson = async (lesson) => {
        if (window.confirm(`Delete "${lesson.title}"? This will also remove all its sequences from the database.`)) {
            try {
                await api.delete(`accounts/admin/lessons/${lesson.id}/`);
                fetchModules();
            } catch (err) {
                alert("Failed to delete lesson.");
                console.error(err);
            }
        }
    };

    const handleSaveModule = async (data, id) => {
        if (id) {
            await api.put(`accounts/admin/modules/${id}/`, data);
        } else {
            await api.post('accounts/admin/modules/', data);
        }
        fetchModules();
    };

    const handleDeleteModule = async (e, module) => {
        e.stopPropagation();
        if (window.confirm(`Delete Level: "${module.title || 'Level ' + module.order}"? This will also permanently remove ALL lessons and sequences inside it.`)) {
            try {
                await api.delete(`accounts/admin/modules/${module.id}/`);
                fetchModules();
            } catch (err) {
                alert("Failed to delete module.");
                console.error(err);
            }
        }
    };

    const openCreateLessonModal = () => {
        setEditingLesson(null);
        setIsLessonModalOpen(true);
    };

    const openEditLessonModal = (lesson) => {
        setEditingLesson(lesson);
        setIsLessonModalOpen(true);
    };

    const openCreateModuleModal = () => {
        setEditingModule(null);
        setIsModuleModalOpen(true);
    };

    const openEditModuleModal = (e, module) => {
        e.stopPropagation();
        setEditingModule(module);
        setIsModuleModalOpen(true);
    };

    const getInstrumentIcon = (name) => {
        if (!name) return null;
        if (name.toLowerCase().includes('piano')) return <Music size={16} style={{ color: '#4f46e5' }} />;
        if (name.toLowerCase().includes('vocal')) return <Mic size={16} style={{ color: '#a855f7' }} />;
        return null;
    };

    const getSeqTypeBadge = (type) => {
        const colors = {
            listen: '#3b82f6', learn: '#10b981', identify: '#f59e0b',
            read: '#6366f1', play: '#ec4899', perform: '#ef4444',
            tap: '#14b8a6', place: '#8b5cf6',
        };
        return (
            <span style={{
                display: 'inline-block',
                padding: '2px 8px',
                borderRadius: '12px',
                fontSize: '0.7rem',
                fontWeight: 600,
                color: 'white',
                background: colors[type] || '#64748b',
                marginRight: '4px',
            }}>
                {type}
            </span>
        );
    };

    return (
        <div>
            <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                    <h1 style={{ fontSize: '1.2rem', fontWeight: 500, color: 'var(--text-muted)' }}>
                        Manage all lesson modules, lessons, and practice sequences.
                    </h1>
                </div>
            </div>

            <div className="table-container">
                <div className="table-header-actions">
                    <div className="table-search">
                        <select value={instrumentFilter} onChange={e => setInstrumentFilter(e.target.value)}>
                            <option value="all">All Instruments</option>
                            <option value="piano">Piano</option>
                            <option value="vocal">Vocal</option>
                        </select>
                    </div>
                    <div style={{ display: 'flex', gap: '8px' }}>
                        <button className="btn-outline" onClick={openCreateModuleModal}
                            style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                            <Plus size={16} /> New Level
                        </button>
                        <button className="btn-primary" onClick={openCreateLessonModal}
                            style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                            <Plus size={16} /> New Lesson
                        </button>
                    </div>
                </div>

                <div style={{ padding: '20px' }}>
                    {filteredModules.length === 0 && (
                        <p style={{ textAlign: 'center', color: 'var(--text-muted)', padding: '40px' }}>
                            No modules found.
                        </p>
                    )}

                    {filteredModules.map(mod => (
                        <div key={mod.id} style={{
                            border: '1px solid var(--border)',
                            borderRadius: '12px',
                            marginBottom: '16px',
                            overflow: 'hidden',
                        }}>
                            {/* Module Header */}
                            <div
                                onClick={() => toggleModule(mod.id)}
                                style={{
                                    display: 'flex', alignItems: 'center', gap: '12px',
                                    padding: '16px 20px',
                                    background: '#f8fafc',
                                    cursor: 'pointer',
                                    userSelect: 'none',
                                    borderBottom: expandedModules[mod.id] ? '1px solid var(--border)' : 'none',
                                }}
                            >
                                {expandedModules[mod.id] ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
                                {getInstrumentIcon(mod.instrument_name)}
                                <div style={{ flex: 1 }}>
                                    <span style={{ fontWeight: 600, fontSize: '1rem' }}>Level {mod.order}: {mod.title || 'Untitled'}</span>
                                    <span style={{ color: 'var(--text-muted)', marginLeft: '12px', fontSize: '0.85rem' }}>
                                        {mod.lesson_count} lesson{mod.lesson_count !== 1 ? 's' : ''}
                                    </span>
                                </div>
                                <span style={{
                                    fontSize: '0.75rem', padding: '3px 10px',
                                    borderRadius: '12px', fontWeight: 500,
                                    background: mod.instrument_name?.toLowerCase().includes('piano') ? '#ede9fe' : '#fce7f3',
                                    color: mod.instrument_name?.toLowerCase().includes('piano') ? '#4f46e5' : '#a855f7',
                                }}>
                                    {mod.instrument_name || 'Unknown'}
                                </span>
                                <div style={{ display: 'flex', gap: '8px', marginLeft: '15px' }}>
                                    <button className="action-btn" onClick={(e) => openEditModuleModal(e, mod)} title="Edit Level">
                                        <Edit size={16} />
                                    </button>
                                    <button className="action-btn delete" onClick={(e) => handleDeleteModule(e, mod)} title="Delete Level">
                                        <Trash2 size={16} />
                                    </button>
                                </div>
                            </div>

                            {/* Lessons Table */}
                            {expandedModules[mod.id] && (
                                <table>
                                    <thead>
                                        <tr>
                                            <th style={{ width: '50px' }}>#</th>
                                            <th>Title</th>
                                            <th>Type</th>
                                            <th>Sequences</th>
                                            <th style={{ width: '100px' }}>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {mod.lessons.map(lesson => (
                                            <tr key={lesson.id}>
                                                <td style={{ fontWeight: 500, color: 'var(--text-muted)' }}>{lesson.order}</td>
                                                <td style={{ fontWeight: 500 }}>{lesson.title}</td>
                                                <td>
                                                    <span style={{
                                                        textTransform: 'capitalize', fontSize: '0.85rem',
                                                        padding: '3px 10px', borderRadius: '12px',
                                                        background: lesson.lesson_type === 'theory' ? '#dbeafe' : lesson.lesson_type === 'practice' ? '#dcfce7' : '#fef3c7',
                                                        color: lesson.lesson_type === 'theory' ? '#1d4ed8' : lesson.lesson_type === 'practice' ? '#166534' : '#92400e',
                                                        fontWeight: 500,
                                                    }}>
                                                        {lesson.lesson_type}
                                                    </span>
                                                </td>
                                                <td>
                                                    {lesson.sequences.length === 0 ? (
                                                        <span style={{ color: 'var(--text-muted)', fontSize: '0.85rem' }}>None</span>
                                                    ) : (
                                                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '3px' }}>
                                                            {lesson.sequences.map((s, i) => (
                                                                <span key={i}>{getSeqTypeBadge(s.sequence_type)}</span>
                                                            ))}
                                                        </div>
                                                    )}
                                                </td>
                                                <td>
                                                    <div style={{ display: 'flex', gap: '10px' }}>
                                                        <button className="action-btn" onClick={() => openEditLessonModal(lesson)}>
                                                            <Edit size={16} />
                                                        </button>
                                                        <button className="action-btn delete" onClick={() => handleDeleteLesson(lesson)}>
                                                            <Trash2 size={16} />
                                                        </button>
                                                    </div>
                                                </td>
                                            </tr>
                                        ))}
                                        {mod.lessons.length === 0 && (
                                            <tr>
                                                <td colSpan="5" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>
                                                    No lessons in this module.
                                                </td>
                                            </tr>
                                        )}
                                    </tbody>
                                </table>
                            )}
                        </div>
                    ))}
                </div>
            </div>

            <LessonModal
                isOpen={isLessonModalOpen}
                onClose={() => setIsLessonModalOpen(false)}
                onSave={handleSaveLesson}
                lesson={editingLesson}
                modules={modules}
            />

            <ModuleModal
                isOpen={isModuleModalOpen}
                onClose={() => setIsModuleModalOpen(false)}
                onSave={handleSaveModule}
                module={editingModule}
                instruments={instruments}
                modules={modules}
            />
        </div>
    );
};

export default Lessons;
