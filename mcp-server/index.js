const { Server } = require("@modelcontextprotocol/sdk/server/index.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");
const { CallToolRequestSchema, ListToolsRequestSchema } = require("@modelcontextprotocol/sdk/types.js");
const fs = require("fs");
const path = require("path");

// المسار الذي سيتحكم فيه الذكاء الاصطناعي
const PROJECT_ROOT = "C:/Allmyprojects/astshara";

const server = new Server(
  { name: "astshara-manager", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

// تعريف الأدوات المتاحة لـ HuggingChat
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "read_file",
      description: "قراءة محتوى ملف من المشروع",
      inputSchema: {
        type: "object",
        properties: { relativePath: { type: "string" } },
        required: ["relativePath"],
      },
    },
    {
      name: "write_file",
      description: "تعديل أو إنشاء ملف في المشروع",
      inputSchema: {
        type: "object",
        properties: {
          relativePath: { type: "string" },
          content: { type: "string" }
        },
        required: ["relativePath", "content"],
      },
    },
  ],
}));

// تنفيذ الأوامر
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments } = request.params;
  const fullPath = path.join(PROJECT_ROOT, arguments.relativePath);

  if (name === "read_file") {
    const content = fs.readFileSync(fullPath, "utf8");
    return { content: [{ type: "text", text: content }] };
  }

  if (name === "write_file") {
    fs.writeFileSync(fullPath, arguments.content);
    return { content: [{ type: "text", text: "تم تحديث الملف بنجاح" }] };
  }

  throw new Error("أداة غير معروفة");
});

const transport = new StdioServerTransport();
server.connect(transport);
