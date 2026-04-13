import Sidebar from './Sidebar';
import { Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Layout = () => {
    const { user } = useAuth();
    const initial = user ? (user.username || user.email || 'A')[0].toUpperCase() : 'A';

    return (
        <div className="app-container">
            <Sidebar />
            <main className="main-content">
                <header className="topbar">

                    <div className="user-profile">
                        <div className="avatar">{initial}</div>
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
