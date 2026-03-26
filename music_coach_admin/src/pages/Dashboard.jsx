import { useState, useEffect } from 'react';
import api from '../api/axios';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import { Users, BookOpen, Sparkles } from 'lucide-react';

const Dashboard = () => {
    const [stats, setStats] = useState({
        total_users: 0,
        total_lessons_completed: 0,
        piano_lessons_completed: 0,
        vocal_lessons_completed: 0,
        new_signups_today: 0,
        daily_users_data: [],
        lesson_breakdown_data: []
    });

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const res = await api.get('accounts/admin/stats/');
                setStats(res.data);
            } catch (err) {
                console.error("Failed to fetch stats", err);
            }
        };
        fetchStats();
    }, []);

    return (
        <div>
            <div className="page-header" style={{
                marginBottom: '32px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between'
            }}>
                <div>
                    <h1 style={{ margin: '0 0 8px 0', fontSize: '1.8rem', fontWeight: '700', color: 'var(--text-main)', letterSpacing: '-0.02em' }}>Welcome back, Admin</h1>
                    <p style={{ margin: 0, color: 'var(--text-muted)', fontSize: '1.05rem' }}>Here's what's happening on your platform today.</p>
                </div>
            </div>

            <div className="stats-grid">
                <div className="stat-card">
                    <div className="stat-header">
                        <span>Total Users</span>
                        <Users size={20} color="#64748b" />
                    </div>
                    <div className="stat-value">{stats.total_users.toLocaleString()}</div>
                    <div className="stat-trend trend-up">Registered accounts on the platform</div>
                </div>
                <div className="stat-card">
                    <div className="stat-header">
                        <span>Total Lessons Completed</span>
                        <BookOpen size={20} color="#64748b" />
                    </div>
                    <div className="stat-value">{stats.total_lessons_completed.toLocaleString()}</div>
                    <div className="stat-trend" style={{ color: '#64748b' }}>
                        🎹 Piano: {stats.piano_lessons_completed} &nbsp;|&nbsp; 🎤 Vocal: {stats.vocal_lessons_completed}
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-header">
                        <span>New Signups Today</span>
                        <Sparkles size={20} color="#64748b" />
                    </div>
                    <div className="stat-value">{stats.new_signups_today.toLocaleString()}</div>
                    <div className="stat-trend trend-up">Users joined today</div>
                </div>
            </div>

            <div className="charts-grid">
                <div className="chart-card">
                    <h3>New Users (Last 7 Days)</h3>
                    <ResponsiveContainer width="100%" height="85%">
                        <BarChart data={stats.daily_users_data}>
                            <XAxis dataKey="name" axisLine={false} tickLine={false} />
                            <YAxis hide allowDecimals={false} />
                            <Tooltip cursor={{ fill: '#f1f5f9' }} />
                            <Bar dataKey="users" fill="#2563eb" radius={[4, 4, 0, 0]} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>
                <div className="chart-card">
                    <h3>Lessons Completed by Type</h3>
                    <ResponsiveContainer width="100%" height="85%">
                        <BarChart data={stats.lesson_breakdown_data} layout="vertical">
                            <CartesianGrid strokeDasharray="3 3" horizontal={false} />
                            <XAxis type="number" hide allowDecimals={false} />
                            <YAxis type="category" dataKey="name" axisLine={false} tickLine={false} width={50} />
                            <Tooltip />
                            <Bar dataKey="lessons" radius={[0, 6, 6, 0]}>
                                {stats.lesson_breakdown_data.map((entry, index) => (
                                    <Cell key={index} fill={index === 0 ? '#2563eb' : '#a855f7'} />
                                ))}
                            </Bar>
                        </BarChart>
                    </ResponsiveContainer>
                </div>
            </div>
        </div>
    )
}
export default Dashboard;
