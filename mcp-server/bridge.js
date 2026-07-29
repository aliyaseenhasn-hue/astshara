const http = require('http');
const { spawn } = require('child_process');
const path = require('path');

const PORT = 3000;
const SERVER_PATH = path.join(__dirname, 'index.js');

// تشغيل سيرفر الـ MCP (Stdio)
const mcpServer = spawn('node', [SERVER_PATH]);

mcpServer.stderr.on('data', (data) => {
    console.error(`MCP Error: ${data}`);
});

mcpServer.on('close', (code) => {
    console.log(`MCP Server closed with code ${code}`);
    process.exit(code);
});

// إنشاء سيرفر HTTP بسيط لتحويل الطلبات إلى Stdio
const server = http.createServer((req, res) => {
    if (req.method === 'POST') {
        let body = '';
        req.on('data', chunk => { body += chunk.toString(); });
        req.on('end', () => {
            // إرسال الطلب إلى الـ Stdio الخاص بسيرفر الـ MCP
            mcpServer.stdin.write(body + '\n');

            // قراءة الرد من الـ Stdout الخاص بسيرفر الـ MCP
            mcpServer.stdout.once('data', (data) => {
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(data);
            });
        });
    } else {
        res.writeHead(405);
        res.end();
    }
});

server.listen(PORT, () => {
    console.log(`MCP Bridge listening on port ${PORT}`);
});
