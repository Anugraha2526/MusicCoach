import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Dashboard />} />
          <Route path="users" element={<Users />} />
          {/* Placeholders for future pages */}
          <Route path="lessons" element={<div style={{ padding: '20px' }}>Lessons Page Coming Soon</div>} />
          <Route path="settings" element={<div style={{ padding: '20px' }}>Settings Page Coming Soon</div>} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
export default App;
