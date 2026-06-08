const backendUrl = process.env.BACKEND_URL || 'http://localhost:5000'

const nextConfig = {
	reactStrictMode: true,
	async rewrites() {
		return [
			{
				source: '/api/:path*',
				destination: `${backendUrl}/api/:path*`,
			},
		]
	},
}

module.exports = nextConfig
