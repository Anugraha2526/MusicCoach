import { useState, useEffect } from 'react';
import { Download, Edit, Trash2, Plus } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import UserModal from '../components/UserModal';
import api from '../api/axios';

const Users = () => {
    const [users, setUsers] = useState([]);
    const [statusFilter, setStatusFilter] = useState('all');
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingUser, setEditingUser] = useState(null);
    const { getToken } = useAuth();
    const token = getToken();

    const fetchUsers = async () => {
        try {
            const res = await api.get('accounts/admin/users/');
            setUsers(res.data);
        } catch (err) {
            console.error("Failed to fetch users", err);
        }
    };

    useEffect(() => {
        if (token) fetchUsers();
    }, [token]);

    const handleSaveUser = async (userData, id) => {
        if (id) {
            await api.patch(`accounts/admin/users/${id}/`, userData);
        } else {
            await api.post('accounts/admin/users/', userData);
        }
        fetchUsers();
    };

    const handleDeleteUser = async (user) => {
        if (window.confirm(`Are you sure you want to delete ${user.email}?`)) {
            try {
                await api.delete(`accounts/admin/users/${user.id}/`);
                fetchUsers();
            } catch (err) {
                alert("Failed to delete user.");
                console.error(err);
            }
        }
    };

    const openCreateModal = () => {
        setEditingUser(null);
        setIsModalOpen(true);
    };

    const openEditModal = (user) => {
        setEditingUser(user);
        setIsModalOpen(true);
    };

    const applyFilter = (list) => {
        if (statusFilter === 'all') return list;
        return list.filter(u => u.is_active === (statusFilter === 'active'));
    };

    const admins = applyFilter(users.filter(u => u.role === 'admin'));
    const students = applyFilter(users.filter(u => u.role !== 'admin'));

    return (
        <div>
            <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between' }}>
                <div>
                    <h1 style={{ fontSize: '1.2rem', fontWeight: 500, color: 'var(--text-muted)' }}>View and manage all user accounts within the platform.</h1>
                </div>
            </div>

            <div className="table-container">
                <div className="table-header-actions">
                    <div className="table-search">
                        <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)}>
                            <option value="all">All Statuses</option>
                            <option value="active">Active</option>
                            <option value="inactive">Inactive</option>
                        </select>
                        <input type="text" placeholder="Search users..." />
                    </div>
                    <div style={{ display: 'flex', gap: '10px' }}>
                        <button className="btn-outline"><Download size={16} /> Export</button>
                        <button className="btn-primary" onClick={openCreateModal} style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                            <Plus size={16} /> New User
                        </button>
                    </div>
                </div>

                <div style={{ padding: '20px' }}>
                    <h2 style={{ margin: '0 0 20px 0', fontSize: '1.2rem' }}>Admin Accounts</h2>
                    <table style={{ marginBottom: '40px' }}>
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Role</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {admins.map((u, i) => (
                                <tr key={u.id}>
                                    <td>
                                        <div className="user-info">
                                            <div className="user-initial" style={{ backgroundColor: ['#ef4444', '#3b82f6', '#10b981', '#a855f7'][i % 4] }}>
                                                {(u.first_name ? u.first_name[0] : (u.username?.[0] || 'U')).toUpperCase()}
                                            </div>
                                            {u.first_name ? `${u.first_name} ${u.last_name || ''}` : u.username}
                                        </div>
                                    </td>
                                    <td>{u.email}</td>
                                    <td><span style={{ textTransform: 'capitalize', fontWeight: 500 }}>{u.role}</span></td>
                                    <td>
                                        <span className={u.is_active ? 'status-badge status-active' : 'status-badge status-inactive'}>
                                            {u.is_active ? 'Active' : 'Inactive'}
                                        </span>
                                    </td>
                                    <td>
                                        <div style={{ display: 'flex', gap: '10px' }}>
                                            <button className="action-btn" onClick={() => openEditModal(u)}><Edit size={16} /></button>
                                            <button className="action-btn delete" onClick={() => handleDeleteUser(u)}><Trash2 size={16} /></button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                            {admins.length === 0 && (
                                <tr>
                                    <td colSpan="5" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No admin accounts found.</td>
                                </tr>
                            )}
                        </tbody>
                    </table>

                    <h2 style={{ margin: '0 0 20px 0', fontSize: '1.2rem' }}>Student Accounts</h2>
                    <table>
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Role</th>
                                <th>Status</th>
                                <th>Piano Lessons</th>
                                <th>Vocal Lessons</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {students.map((u, i) => (
                                <tr key={u.id}>
                                    <td>
                                        <div className="user-info">
                                            <div className="user-initial" style={{ backgroundColor: ['#ef4444', '#3b82f6', '#10b981', '#a855f7'][i % 4] }}>
                                                {(u.first_name ? u.first_name[0] : (u.username?.[0] || 'U')).toUpperCase()}
                                            </div>
                                            {u.first_name ? `${u.first_name} ${u.last_name || ''}` : u.username}
                                        </div>
                                    </td>
                                    <td>{u.email}</td>
                                    <td><span style={{ textTransform: 'capitalize', fontWeight: 500 }}>{u.role}</span></td>
                                    <td>
                                        <span className={u.is_active ? 'status-badge status-active' : 'status-badge status-inactive'}>
                                            {u.is_active ? 'Active' : 'Inactive'}
                                        </span>
                                    </td>
                                    <td>{u.piano_lessons_completed}</td>
                                    <td>{u.vocal_lessons_completed}</td>
                                    <td>
                                        <div style={{ display: 'flex', gap: '10px' }}>
                                            <button className="action-btn" onClick={() => openEditModal(u)}><Edit size={16} /></button>
                                            <button className="action-btn delete" onClick={() => handleDeleteUser(u)}><Trash2 size={16} /></button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                            {students.length === 0 && (
                                <tr>
                                    <td colSpan="7" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No student accounts found.</td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            <UserModal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                onSave={handleSaveUser}
                user={editingUser}
            />
        </div>
    )
}
export default Users;
