import { useState, useEffect } from 'react';
import axios from 'axios';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Users, BookOpen, LayoutGrid, Sparkles } from 'lucide-react';

const Dashboard = () => {
    const [stats, setStats] = useState({
        total_users: 0,
        lessons_completed_this_week: 0,
        active_lessons: 0,
        new_signups_today: 0,
        daily_users_data: [],
        weekly_lessons_data: []
    });

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const res = await axios.get('http://127.0.0.1:8000/api/accounts/admin/stats/');
                setStats(res.data);
            } catch (err) {
                console.error("Failed to fetch stats", err);
            }
        };
        fetchStats();
    }, []);

    return (
        <div>
            <div className="page-header">
                <h1>Welcome, Admin!</h1>
                <p>Here's an overview of your platform's performance.</p>
            </div>

            <div className="stats-grid">
                <div className="stat-card">
                    <div className="stat-header">
                        <span>Total Users</span>
                        <Users size={20} color="#64748b" />
                    </div>
                    <div className="stat-value">{stats.total_users.toLocaleString()}</div>
                    <div className="stat-trend trend-up">↗ +15.8% vs last month</div>
                </div>
                <div className="stat-card">
                    <div className="stat-header">
                        <span>Lessons Completed This Week</span>
                        <BookOpen size={20} color="#64748b" />
                    </div>
                    <div className="stat-value">{stats.lessons_completed_this_week.toLocaleString()}</div>
                    <div className="stat-trend trend-up">↗ +8.2% vs last month</div>
                </div>
                <div className="stat-card">
                    <div className="stat-header">
                        <span>Active Lessons</span>
                        <LayoutGrid size={20} color="#64748b" />
                    </div>
                    <div className="stat-value">{stats.active_lessons.toLocaleString()}</div>
                    <div className="stat-trend trend-down">↘ -2.1% vs last month</div>
                </div>
                <div className="stat-card">
                    <div className="stat-header">
                        <span>New Signups Today</span>
                        <Sparkles size={20} color="#64748b" />
                    </div>
                    <div className="stat-value">{stats.new_signups_today.toLocaleString()}</div>
                    <div className="stat-trend trend-up">↗ +25.0% vs last month</div>
                </div>
            </div>

            <div className="charts-grid">
                <div className="chart-card">
                    <h3>Weekly Lessons Completed</h3>
                    <ResponsiveContainer width="100%" height="85%">
                        <LineChart data={stats.weekly_lessons_data}>
                            <CartesianGrid strokeDasharray="3 3" vertical={false} />
                            <XAxis dataKey="name" axisLine={false} tickLine={false} />
                            <YAxis hide />
                            <Tooltip />
                            <Line type="monotone" dataKey="lessons" stroke="#ef4444" strokeWidth={3} dot={false} />
                        </LineChart>
                    </ResponsiveContainer>
                </div>
                <div className="chart-card">
                    <h3>New Users Daily</h3>
                    <ResponsiveContainer width="100%" height="85%">
                        <BarChart data={stats.daily_users_data}>
                            <XAxis dataKey="name" axisLine={false} tickLine={false} />
                            <YAxis hide />
                            <Tooltip cursor={{ fill: '#f1f5f9' }} />
                            <Bar dataKey="users" fill="#000" radius={[4, 4, 0, 0]} />
                        </BarChart>
                    </ResponsiveContainer>
                </div>
            </div>
        </div>
    )
}
export default Dashboard;
