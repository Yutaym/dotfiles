// markdown-to-pdf.js
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 入力ファイルの取得
const inputFile = process.argv[2];
if (!inputFile) {
    console.error("Error: Markdown file is required");
    process.exit(1);
}

// 入力ファイルのディレクトリを取得
const inputDir = path.dirname(inputFile);

// Markdownと同じディレクトリに一時ディレクトリを作成
const tempDir = path.join(inputDir, 'mermaid_temp');
if (!fs.existsSync(tempDir)) fs.mkdirSync(tempDir);

// 出力ファイル名の設定
const outputFile = path.join(inputDir, path.basename(inputFile, '.md') + '.pdf');

// Mermaidの処理
const markdown = fs.readFileSync(inputFile, 'utf8');
const mermaidRegex = /```mermaid([\s\S]*?)```/g;
let modifiedMarkdown = markdown;
let match;
let diagramCount = 0;

while ((match = mermaidRegex.exec(markdown)) !== null) {
    const mermaidCode = match[1].trim();
    const diagramFile = path.join(tempDir, `diagram_${diagramCount}.svg`);
    const mmdFile = path.join(tempDir, `diagram_${diagramCount}.mmd`);
    fs.writeFileSync(mmdFile, mermaidCode);

    try {
        // Mermaid CLIを使用してSVGを生成
        execSync(`mmdc -i "${mmdFile}" -o "${diagramFile}"`);
        console.log(`Generated: ${diagramFile}`);
        // Markdown内のMermaidコードを画像に置き換え
        modifiedMarkdown = modifiedMarkdown.replace(match[0], `![Diagram](./mermaid_temp/diagram_${diagramCount}.svg)`);
    } catch (error) {
        console.error("Error generating diagram:", error.message);
        process.exit(1);
    }

    diagramCount++;
}

// 修正版Markdownの保存
const tempMarkdown = inputFile.replace('.md', '_temp.md');
fs.writeFileSync(tempMarkdown, modifiedMarkdown);

// Markdown to PDF変換
try {
    execSync(`markdown-pdf "${tempMarkdown}" -o "${outputFile}"`);
    console.log(`PDF generated: ${outputFile}`);
} catch (error) {
    console.error("Error generating PDF:", error.message);
    process.exit(1);
}

// 一時ファイルの削除
fs.unlinkSync(tempMarkdown);
console.log("Temporary files cleaned up.");
