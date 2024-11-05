import hashlib
import pathlib
import sys
import subprocess
import shutil

def run_zig(code: str) -> str:
    zig = f'''
const std = @import("std");

pub fn main() !void {{
    {code}
}}
'''
    tmp = pathlib.Path('./tmp')
    if not tmp.exists():
        tmp.mkdir()
    
    suffix = hashlib.md5(code.encode()).hexdigest()[0:5]
    tmp_zig_file = pathlib.Path(f'./tmp/tmp-{suffix}.zig')
    with open(tmp_zig_file, 'w+') as f:
        f.write(zig)
    print(f'Temporary Zig file saved to {tmp_zig_file.absolute()}.')

    # check zig installation
    if shutil.which('zig') is None:
        print('Error: Cannot find zig')
    
    print(f'Running zig run {tmp_zig_file.absolute()}')
    try:
        result = subprocess.run(['zig', 'run', tmp_zig_file.absolute()], check=True, text=True, capture_output=True)
        result_str = ''
        if result.stdout == '':
            result_str += '$stdout returns nothing.\n'
        else:
            result_str += '$stdout:\n'
            result_str += result.stdout
        
        if result.stderr == '':
            result_str += '$stderr returns nothing.\n'
        else:
            result_str += '$stderr:\n'
            result_str += result.stderr
        
        print(result_str)
        return result_str
    
    except subprocess.CalledProcessError as e:
        print('Zig run Failed:')
        print(e.stderr)
        exit(1)
    

class MarkdownPreprocesser:
    def __init__(self, source: str):
        self.line = 1
        self.source = source
        self.current = (-1, source[0] if len(source) > 0 else None)

    def is_at_end(self):
        return self.current[0] >= len(self.source)

    def advance(self):
        if self.is_at_end():
            self.current = (len(self.source), None)
        else:
            ci, _c = self.current
            self.current = (ci + 1, self.source[ci])
        
        if self.current[1] == '\n':
            self.line += 1
        
        return self.current
    
    def nextMatchs(self, compare: str):
        ci, p = self.current
        if ci + len(compare) > len(self.source):
            return False
        if (self.source[ci:ci+len(compare)] == compare):
            for i in range(len(compare)):
                self.advance()
            return True
        return False

    def preprocess(self) -> str:
        result = ''
        while(not self.is_at_end()):
            ci, c = self.advance()
            if c == '`':
                if(self.nextMatchs('``')):
                    result += '```'
                    # starts a code block
                    print('Started a block')
                    if (self.nextMatchs('zig')):
                        result += 'zig\n'
                        
                        ci, c = self.advance() # consume trailing \n
                        
                        # get zig snippet
                        start = ci
                        while c != '`' and not self.nextMatchs('``'):
                            self.advance()
                        
                        print('Closed block')

                        self.advance()
                        # skip code snippets marked as skip
                        skip = False
                        if self.nextMatchs('-skip'):
                            print('Skipping.')
                            skip = True
                        else:
                            print('Running.')
                        
                        end = self.current[0] - (8 if skip else 3)
                        code = self.source[start:end]
                        print(code)
                        result += code
                        result += '```'
                        if not skip:
                            result += '\n'
                        else:
                            result += '' # use this in production
                            # result += '-skip' # use this in debugging
                        
                        if not skip:
                            program_result = run_zig(code)
                            result += '\n```shell\n'
                            # result += code
                            result += program_result
                            result += '```'
                    else:
                        print('Not a zig block, skipping.')
                else:
                    result += '`'
            else:
                result += c
        return result
        

def main():
    args = sys.argv
    if len(args) <= 2:
        print('Usage: uv run main.py <filename> <output>')
        exit(64)
    
    input_file = pathlib.Path(args[1])
    output = args[2]
    print(f'Preprocessing {input_file.absolute()}.')
    source = ''
    if not input_file.exists():
        print(f'{input_file.absolute} does not exist.')
        exit(65)
    
    with open(input_file, 'r+') as f:
        source = f.read()

    prepocessor = MarkdownPreprocesser(source)
    result = prepocessor.preprocess().strip()

    print(f'Save to {pathlib.Path(output).absolute()}')
    with open(output, 'w+') as f:
        f.write(result)

if __name__ == '__main__':
    main()
