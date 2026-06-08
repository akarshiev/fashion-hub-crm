module.exports = {
  apps: [
    {
      name: 'crm-backend',
      cwd: './backend',
      script: 'src/server.js',
      env: {
        NODE_ENV: 'production',
        PORT: 5000,
      },
      instances: 1,
      autorestart: true,
      max_memory_restart: '256M',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
      error_file: '/var/log/crm/backend-error.log',
      out_file: '/var/log/crm/backend-out.log',
    },
    {
      name: 'crm-frontend',
      cwd: './frontend',
      script: 'node_modules/.bin/next',
      args: 'start',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
      instances: 1,
      autorestart: true,
      max_memory_restart: '512M',
      log_date_format: 'YYYY-MM-DD HH:mm:ss',
      error_file: '/var/log/crm/frontend-error.log',
      out_file: '/var/log/crm/frontend-out.log',
    },
  ],
};
