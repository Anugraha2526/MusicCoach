import Sidebar from './Sidebar';
import { Outlet } from 'react-router-dom';
import { Search, Bell } from 'lucide-react';

const Layout = () => {
    return (
        <div className="app-container">
            <Sidebar />
            <main className="main-content">
                <header className="topbar">
                    <div className="search-bar">
                        <Search size={18} />
                        <input type="text" placeholder="Search..." />
                    </div>
                    <div className="user-profile">
                        <Bell size={20} style={{ cursor: 'pointer' }} />
                        <div className="avatar">A</div>
                    </div>
                </header>
                <div className="page-content">
                    <Outlet />
                </div>
            </main>
        </div>
    );
};
export default Layout;
