import sys

def fix():
    try:
        with open('./test/7seg.hex', 'r') as f:
            raw_words = f.read().split()
            data_bytes = [w for w in raw_words if not w.startswith('@')]
        
        with open('./test/7seg.hex', 'w') as f:
            buf = []
            for b in data_bytes:
                buf.append(b)
                if len(buf) == 4:
                    word = "".join(reversed(buf))
                    f.write(word + '\n')
                    buf = []
            
            if buf:
                word = "".join(reversed(buf)).ljust(8, '0')
                f.write(word + '\n')
                
        print("Completed HEX format.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    fix()