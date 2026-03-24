import { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Restore session from localStorage on mount
        const token = localStorage.getItem('admin_access_token');
        const savedUser = localStorage.getItem('admin_user');
        if (token && savedUser) {
            setUser(JSON.parse(savedUser));
        }
        setLoading(false);
    }, []);

    const login = (userData, tokens) => {
        localStorage.setItem('admin_access_token', tokens.access);
        localStorage.setItem('admin_refresh_token', tokens.refresh);
        localStorage.setItem('admin_user', JSON.stringify(userData));
        setUser(userData);
    };

    const logout = () => {
        localStorage.removeItem('admin_access_token');
        localStorage.removeItem('admin_refresh_token');
        localStorage.removeItem('admin_user');
        setUser(null);
    };

    const getToken = () => localStorage.getItem('admin_access_token');

    return (
        <AuthContext.Provider value={{ user, login, logout, getToken, loading }}>
            {children}
        </AuthContext.Provider>
    );
}

export function useAuth() {
    return useContext(AuthContext);
}
