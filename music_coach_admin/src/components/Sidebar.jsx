import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Users, BookOpen, Settings } from 'lucide-react';

const Sidebar = () => {
    return (
        <aside className="sidebar">
            <div className="sidebar-logo">
                <LayoutDashboard size={24} />
                Admin Dashboard
            </div>
            <div className="sidebar-nav">
                <NavLink to="/" className={({ isActive }) => isActive ? "nav-item active" : "nav-item"}>
                    <LayoutDashboard size={20} /> Dashboard
                </NavLink>
                <NavLink to="/users" className={({ isActive }) => isActive ? "nav-item active" : "nav-item"}>
                    <Users size={20} /> Users
                </NavLink>
                <NavLink to="/lessons" className="nav-item">
                    <BookOpen size={20} /> Lessons
                </NavLink>
                <NavLink to="/settings" className="nav-item">
                    <Settings size={20} /> Settings
                </NavLink>
            </div>
        </aside>
    );
}
export default Sidebar;
