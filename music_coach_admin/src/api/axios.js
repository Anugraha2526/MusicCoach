import axios from 'axios';

const api = axios.create({
    baseURL: 'http://127.0.0.1:8000/api/',
});

// Attach access token to every outgoing request
api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('admin_access_token');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => Promise.reject(error)
);

// Listen for 401 Unauthorized responses to attempt token refresh
api.interceptors.response.use(
    (response) => response,
    async (error) => {
        const originalRequest = error.config;

        // If the error is 401 and we haven't already tried to refresh
        if (error.response?.status === 401 && !originalRequest._retry) {
            originalRequest._retry = true;
            try {
                const refreshToken = localStorage.getItem('admin_refresh_token');
                if (!refreshToken) throw new Error('No refresh token available');

                // Call the backend refresh endpoint
                const { data } = await axios.post('http://127.0.0.1:8000/api/accounts/token/refresh/', {
                    refresh: refreshToken
                });

                // Update the localStorage tokens
                localStorage.setItem('admin_access_token', data.access);
                if (data.refresh) {
                    localStorage.setItem('admin_refresh_token', data.refresh);
                }

                // Retry the original failed request with the new token
                originalRequest.headers.Authorization = `Bearer ${data.access}`;
                return api(originalRequest);
            } catch (refreshErr) {
                // If refresh fails (e.g., refresh token is also expired), clear session & force login
                localStorage.removeItem('admin_access_token');
                localStorage.removeItem('admin_refresh_token');
                localStorage.removeItem('admin_user');
                window.location.href = '/login';
                return Promise.reject(refreshErr);
            }
        }

        return Promise.reject(error);
    }
);

export default api;
