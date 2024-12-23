import * as fs from 'fs';
import * as path from 'path';
import * as childProcess from 'child_process';
import * as crypto from 'crypto';

// 代码段信息
interface CodeBlock {
    type: string;       // 代码块类型，例如 "zig" 或 "zig -singleFile"
    content: string;    // 代码块内容
    line: number;       // 代码块开始的行号
    highlightIndex: string | null;  // 代码块中的高亮
}

async function ensureFileExists(path: string) {
    try {
        fs.accessSync(path, fs.constants.F_OK);
    } catch (error) {
        fs.mkdirSync(path, { recursive: true });
        console.log(`Created ${path}.`)
    }
}

async function runZigCodeCommand(code: string, cmd: 'run' | 'test'): Promise<string> {
    return new Promise((resolve, reject) => {
        
        const md5Sum = crypto.createHash('md5').update(code).digest('hex'); // 计算代码的MD5值
        const tempFileName = `tmp-${md5Sum.substring(0, 6)}.zig`; // 使用MD5值的前6个字符作为文件名
        const tempFilePath = path.join(__dirname, '/tmp', tempFileName); // 创建临时文件路径
        const cacheFilePath = path.join(__dirname, '/tmp/cache', `tmp-${md5Sum.substring(0, 6)}.txt`); // 缓存文件路径
        
        // 确保路径存在
        ensureFileExists(path.join(__dirname, '/tmp'));
        ensureFileExists(path.join(__dirname, '/tmp/cache'));

        // 检查缓存文件是否存在
        if (fs.existsSync(cacheFilePath)) {
            console.log(`Found cache file ${cacheFilePath}.`);
            const cachedOutput = fs.readFileSync(cacheFilePath, 'utf-8');
            resolve(cachedOutput);
            return;
        }

        fs.writeFileSync(tempFilePath, code); // 将代码写入临时文件
        const command = `zig ${cmd} ${tempFilePath}`; // 使用临时文件执行Zig代码

        let result = '';
        console.log(`${cmd === 'run' ? 'Executing' : 'Testing'} temp file ${tempFilePath}.`);
        console.log(`\t>>> ${code.replaceAll('\n', '\n\t>>> ')}`)
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
 * 执行Zig代码并返回输出。
 * @param code 要执行的Zig代码
 * @param singleFile 是否将代码保存为单独的文件再执行
 * @returns 执行结果的输出
 */
async function executeZigCode(code: string, singleFile = false): Promise<string> {
    const fullCode = singleFile ? code : `const std = @import("std");\npub fn main() !void {\n ${code} \n}`;
    return runZigCodeCommand(fullCode, 'run');
}

/**
 * 测试Zig代码并返回输出。
 * @param code 要测试的Zig代码
 * @returns 执行结果的输出
 */
async function testZigCode(code: string): Promise<string> {
    return runZigCodeCommand(code, 'test');
}

/**
 * 处理Markdown文件中的Zig代码块。
 * @param filePath 输入的Markdown文件路径
 */
async function processMarkdown(filePath: string) {
    const content = fs.readFileSync(filePath, 'utf-8').split('\n'); // 读取文件内容并按行分割
    let inCodeBlock = false; // 标记是否在代码块中
    let currentBlock: CodeBlock | null = null; // 当前处理的代码块
    let currentTestBlock: CodeBlock | null = null;  // 当前测试的代码块

    const collectedBlocks = new Map<string, CodeBlock>();
    const collectedTestBlocks = new Map<string, CodeBlock>();

    // 遍历每一行，查找代码块并立即处理
    let result = '';
    for (let i = 0; i < content.length; i++) {
        const line = content[i];
        if (!inCodeBlock && line.startsWith('```')) {
            const match = line.match(/^```(zig(?: -\w+)?)/); // 匹配Zig代码块的开始
            if (match) {
                // 判断是否有指定高亮行的{\d}
                const haveIndex = line.match(/\{.*\}/);
                let index: string | null = null;
                if (haveIndex) {
                    index = haveIndex[0];
                }

                inCodeBlock = true;
                currentBlock = {
                    type: match[1],
                    content: '',
                    line: i,
                    highlightIndex: index
                };

                currentTestBlock = {
                    type: match[1],
                    content: '',
                    line: i,
                    highlightIndex: index
                };

                // 判断是否需要收集
                const isCollect = line.match(/^```zig -collect_(\d+|\*)/);
                if (isCollect) {
                    const match = isCollect[0];
                    const collectNum = match.substring(match.indexOf('_') + 1);
                    currentBlock.type = `collect:${collectNum}`;

                    currentTestBlock = null;
                    continue;
                }

                // 判断是否需要执行
                const isExecute = line.match(/^```zig -execute_(\d+|\*)/);
                if (isExecute) {
                    const match = isExecute[0];
                    const executeNum = match.substring(match.indexOf('_') + 1);
                    currentBlock.type = `execute:${executeNum}`;

                    currentTestBlock = null;
                    continue;
                }

                // 判断是否需要收集测试
                const isTestCollect = line.match(/^```zig -test_collect_(\d+|\*)/);
                if (isTestCollect) {
                    const match = isTestCollect[0];
                    const collectNum = match.substring(match.lastIndexOf('_') + 1);
                    currentTestBlock.type = `test-collect:${collectNum}`;
                    
                    currentBlock = null;
                    continue;
                }

                // 判断是否需要测试
                const isTest = line.match(/^```zig -test_(\d+|\*)/);
                if (isTest) {
                    const match = isTest[0];
                    const testNum = match.substring(match.indexOf('_') + 1);
                    currentTestBlock.type = `test:${testNum}`;

                    currentBlock = null;
                    continue;
                }
            } else {
                result += line + '\n';
            }
        } else if (inCodeBlock && line === '```') {
            inCodeBlock = false;
            if (currentBlock) {
                // 向result中输出zig代码块和结果代码块（如果需要的话）
                const { type, content, line, highlightIndex } = currentBlock;
                if (highlightIndex) {
                    result += `\`\`\`zig ${highlightIndex}\n${currentBlock.content}\`\`\`\n`;
                } else {
                    result += `\`\`\`zig\n${currentBlock.content}\`\`\`\n`;
                }

                if (type.includes('-skip')) {
                    // 不添加结果代码块
                    continue;
                
                } else if (type.includes('collect:')) {
                    // 收集代码到一块里再执行
                    const collectNum = type.split(':')[1];
                    const savedBlock = collectedBlocks.get(collectNum);
                    if (savedBlock && currentBlock.line != savedBlock.line) {
                        // 存到一块
                        savedBlock.content += currentBlock.content;
                    } else {
                        collectedBlocks.set(collectNum, currentBlock);
                    }
                
                } else if (type.includes('execute:')) {
                    // 执行保存好的代码并输出
                    const executeNum = type.split(':')[1];
                    if (executeNum === '*') {
                        console.error(`Connot execute public code at line ${line}.`);
                        process.exit(-1);
                    }
                    const savedBlock = collectedBlocks.get(executeNum);
                    // 公共代码块
                    const publicBlock = collectedBlocks.get('*');
                    if (savedBlock) {
                        // 公共代码块总是被放置在所有代码前面
                        const publicCode = publicBlock ? publicBlock.content : '';
                        const output = await executeZigCode(publicCode + savedBlock.content + content,  true);
                        result += `\n\`\`\`ansi\n${output}\`\`\`\n`;
                        // 执行完成后就清除
                        // TODO: 有必要吗？
                        collectedBlocks.delete(executeNum);
                        // 不清除公共代码块
                    } else {
                        console.error(`CodeBlock with execute number ${executeNum} is not saved.`);
                        process.exit(-1);
                    }
                
                } else if (type.includes('zig')) {
                    // 执行代码
                    const output = await executeZigCode(content, type.includes('-singleFile'));
                    result += `\n\`\`\`ansi\n${output}\`\`\`\n`;
                }
                
                currentBlock = null;
                continue;
            }

            if (currentTestBlock) {
                // 向result中输出zig代码块和结果代码块（如果需要的话）
                const { type, content, line, highlightIndex } = currentTestBlock;
                if (highlightIndex) {
                    result += `\`\`\`zig ${highlightIndex}\n${content}\`\`\`\n`;
                } else {
                    result += `\`\`\`zig\n${content}\`\`\`\n`;
                }
                if (type.includes('-skip')) {
                    // 不添加结果代码块
                    continue;
                
                } else if (type.includes('test-collect:')) {
                    // 收集代码到一块里再执行
                    const collectNum = type.split(':')[1];
                    const savedTestBlock = collectedTestBlocks.get(collectNum);
                    if (savedTestBlock && currentTestBlock.line != savedTestBlock.line) {
                        // 存到一块
                        savedTestBlock.content += currentTestBlock.content;
                    } else {
                        collectedTestBlocks.set(collectNum, currentTestBlock);
                    }
                
                } else if (type.includes('test:')) {
                    // 执行保存好的代码并输出
                    const testNum = type.split(':')[1];
                    if (testNum === '*') {
                        console.error(`Connot execute public code at line ${line}.`);
                        process.exit(-1);
                    }
                    const savedBlock = collectedTestBlocks.get(testNum);
                    // 公共代码块
                    const publicBlock = collectedTestBlocks.get('*');
                    if (savedBlock) {
                        // 公共代码块总是被放置在所有代码前面
                        const publicCode = publicBlock ? publicBlock.content : '';
                        const output = await testZigCode(publicCode + savedBlock.content + content);
                        result += `\n\`\`\`ansi\n${output}\`\`\`\n`;
                        // 执行完成后就清除
                        // TODO: 有必要吗？
                        collectedTestBlocks.delete(testNum);
                        // 不清除公共代码块
                    } else {
                        console.error(`CodeBlock with test number ${testNum} is not saved.`);
                        process.exit(-1);
                    }
                }
                currentTestBlock = null;
            }
        } else if (inCodeBlock) {
            if (currentBlock) {
                currentBlock.content += line + '\n'; // 添加代码内容
            }
            if (currentTestBlock) {
                currentTestBlock.content += line + '\n';
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