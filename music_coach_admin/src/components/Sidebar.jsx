import { NavLink, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Users, BookOpen, LogOut } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const Sidebar = () => {
    const { user, logout } = useAuth();
    const navigate = useNavigate();

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    return (
        <aside className="sidebar">
            <div className="sidebar-logo">
                <LayoutDashboard size={24} />
                Admin Dashboard
            </div>
            <div className="sidebar-nav">
                <NavLink to="/" end className={({ isActive }) => isActive ? "nav-item active" : "nav-item"}>
                    <LayoutDashboard size={20} /> Dashboard
                </NavLink>
                <NavLink to="/users" className={({ isActive }) => isActive ? "nav-item active" : "nav-item"}>
                    <Users size={20} /> Users
                </NavLink>
                <NavLink to="/lessons" className="nav-item">
                    <BookOpen size={20} /> Lessons
                </NavLink>
            </div>
            <div className="sidebar-footer">
                {user && (
                    <div className="sidebar-user">
                        <div className="sidebar-user-avatar">
                            {(user.username || user.email || 'A')[0].toUpperCase()}
                        </div>
                        <div className="sidebar-user-info">
                            <span className="sidebar-user-name">{user.username || user.email}</span>
                            <span className="sidebar-user-role">{user.role}</span>
                        </div>
                    </div>
                )}
                <button className="logout-btn" onClick={handleLogout}>
                    <LogOut size={18} /> Sign Out
                </button>
            </div>
        </aside>
    );
};
export default Sidebar;
