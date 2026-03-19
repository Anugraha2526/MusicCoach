import { useState, useEffect } from 'react';
import axios from 'axios';
import { Download, Edit, Trash2 } from 'lucide-react';

const Users = () => {
    const [users, setUsers] = useState([]);

    useEffect(() => {
        const fetchUsers = async () => {
            try {
                const res = await axios.get('http://127.0.0.1:8000/api/accounts/admin/users/');
                setUsers(res.data);
            } catch (err) {
                console.error("Failed to fetch users", err);
            }
        };
        fetchUsers();
    }, []);

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
                        <select>
                            <option>All Statuses</option>
                            <option>Active</option>
                            <option>Inactive</option>
                            <option>Pending</option>
                        </select>
                        <input type="text" placeholder="Search users..." />
                    </div>
                    <div style={{ display: 'flex', gap: '10px' }}>
                        <button className="btn-outline"><Download size={16} /> Export</button>
                        <button className="btn-primary">New User</button>
                    </div>
                </div>
                <div style={{ padding: '20px' }}>
                    <h2 style={{ margin: '0 0 20px 0', fontSize: '1.2rem' }}>User Accounts</h2>
                    <table>
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Status</th>
                                <th>Lessons Completed</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {users.map((u, i) => (
                                <tr key={u.id}>
                                    <td>
                                        <div className="user-info">
                                            <div className="user-initial" style={{ backgroundColor: ['#ef4444', '#3b82f6', '#10b981', '#a855f7'][i % 4] }}>
                                                {u.name.charAt(0).toUpperCase()}
                                            </div>
                                            {u.name}
                                        </div>
                                    </td>
                                    <td>{u.email}</td>
                                    <td>
                                        <span className={`status-badge status-${u.status.toLowerCase()}`}>
                                            {u.status}
                                        </span>
                                    </td>
                                    <td>{u.lessons_completed}</td>
                                    <td>
                                        <div style={{ display: 'flex', gap: '10px' }}>
                                            <button className="action-btn"><Edit size={16} /></button>
                                            <button className="action-btn delete"><Trash2 size={16} /></button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                            {users.length === 0 && (
                                <tr>
                                    <td colSpan="5" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No users found or loading...</td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', marginTop: '15px', gap: '10px', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                <span>Showing 1 - {users.length} of {users.length} users</span>
                <button className="btn-outline" style={{ padding: '5px 10px' }} disabled>Previous</button>
                <button className="btn-outline" style={{ padding: '5px 10px' }} disabled>Next</button>
            </div>
        </div>
    )
}
export default Users;
