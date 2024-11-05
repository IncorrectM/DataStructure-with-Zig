import * as fs from 'fs';
import * as path from 'path';
import * as childProcess from 'child_process';
import * as crypto from 'crypto';
import { argv } from 'bun';

// 代码段信息
interface CodeBlock {
    type: string;       // 代码块类型，例如 "zig" 或 "zig -singleFile"
    content: string;    // 代码块内容
    line: number;       // 代码块开始的行号
}

/**
 * 执行Zig代码并返回输出。
 * @param code 要执行的Zig代码
 * @param singleFile 是否将代码保存为单独的文件再执行
 * @returns 执行结果的输出
 */
async function executeZigCode(code: string, singleFile = false): Promise<string> {
    return new Promise((resolve, reject) => {
        const fullCode = singleFile ? code : `const std = @import("std");\npub fn main() !void {\n ${code} \n}`;
        
        const md5Sum = crypto.createHash('md5').update(fullCode).digest('hex'); // 计算代码的MD5值
        const tempFileName = `tmp-${md5Sum.substring(0, 6)}.zig`; // 使用MD5值的前6个字符作为文件名
        const tempFilePath = path.join(__dirname, '/tmp', tempFileName); // 创建临时文件路径
        const cacheFilePath = path.join(__dirname, '/tmp/cache', `tmp-${md5Sum.substring(0, 6)}.txt`); // 缓存文件路径

        // 检查缓存文件是否存在
        if (fs.existsSync(cacheFilePath)) {
            console.log(`Found cache file ${cacheFilePath}.`);
            const cachedOutput = fs.readFileSync(cacheFilePath, 'utf-8');
            resolve(cachedOutput);
            return;
        }

        fs.writeFileSync(tempFilePath, fullCode); // 将代码写入临时文件
        const command = `zig run ${tempFilePath}`; // 使用临时文件执行Zig代码

        let result = '';
        console.log(`Executing temp file ${tempFilePath}.`);
        console.log(`\t>>> ${fullCode.replaceAll('\n', '\n\t>>> ')}`)
        childProcess.exec(command, null, (error, stdout, stderr) => {
            if (error) {
                reject(error.message); // 如果有错误，拒绝Promise
            } else {
                if (stdout.length === 0) {
                    result += '$stdout returns nothing.\n';
                } else {
                    result += '$stdout:\n';
                    result += stdout.toString();
                }

                if (stderr.length === 0) {
                    result += '$stderr returns nothing.\n';
                } else {
                    result += '$stderr:\n';
                    result += stderr.toString();
                }
                console.log(`Got:\n\t>>> ${result.replaceAll('\n', '\n\t>>> ')}`);
                fs.writeFileSync(cacheFilePath, result); // 将输出结果写入缓存文件
                resolve(result); // 返回执行结果的标准输出
            }
        });
    });
}

/**
 * 处理Markdown文件中的Zig代码块。
 * @param filePath 输入的Markdown文件路径
 */
async function processMarkdown(filePath: string) {
    const content = fs.readFileSync(filePath, 'utf-8').split('\n'); // 读取文件内容并按行分割
    let inCodeBlock = false; // 标记是否在代码块中
    let currentBlock: CodeBlock | null = null; // 当前处理的代码块

    // 遍历每一行，查找代码块并立即处理
    let result = '';
    for (let i = 0; i < content.length; i++) {
        const line = content[i];
        if (!inCodeBlock && line.startsWith('```')) {
            const match = line.match(/^```(zig(?: -\w+)?)(?: \{\d+\})?$/); // 匹配Zig代码块的开始
            if (match) {
                inCodeBlock = true;
                currentBlock = {
                    type: match[1],
                    content: '',
                    line: i,
                };
            }
        } else if (inCodeBlock && line === '```') {
            inCodeBlock = false;
            if (currentBlock) {
                // 向result中输出zig代码块和结果代码块（如果需要的话）
                const { type, content, line } = currentBlock;
                result += `\`\`\`zig\n${currentBlock.content}\n\`\`\`\n`;
                if (type.includes('-skip')) {
                    // 不添加结果代码块
                    continue;
                } else if (type.includes('zig')) {
                    // 执行代码
                    const output = await executeZigCode(content, type.includes('-singleFile'));
                    result += `\n\`\`\`ansi\n${output}\n\`\`\`\n`;
                }
                currentBlock = null;
            }
        } else if (inCodeBlock) {
            if (currentBlock) {
                currentBlock.content += line + '\n'; // 添加代码内容
            }
        } else {
            result += line + '\n';
        }
    }

    const outputPath = filePath.replace('.z.md', '.md');
    fs.writeFileSync(outputPath, result);
    console.log(`Markdown file save ${outputPath}.`)
}

function printUsage(exit: boolean = false) {
    console.log('Usage: bun <command>');
    console.log('           run       <input file>')
    if (exit) {
        process.exit(65);
    }
}

const args = process.argv.slice(2);

// 指定输入文件路径
if (args.length <= 0) {
    printUsage(true);
}

const command = args[0];
if (command === 'run') {
    if (args.length <= 1) {
        console.log('Too less arguments.');
        printUsage(true);
    }
    console.log(`Processing ${args[1]}`);
    const inputFilePath = args[1];
    processMarkdown(inputFilePath).catch(err => console.error(err)); // 处理文件并捕获任何错误
} else {
    console.log(`Unknown command ${command}`);
    printUsage();
}