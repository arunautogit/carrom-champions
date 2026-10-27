import os
import re

directory = 'f:/CARROM/scenes'

for root, dirs, files in os.walk(directory):
    for file in files:
        if file.endswith('.tscn'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Remove ext_resource for theme
            content = re.sub(r'\[ext_resource type="Theme" [^\]]+\]\n', '', content)
            
            # Remove theme = ExtResource("...")
            content = re.sub(r'theme = ExtResource\("[^"]+"\)\n', '', content)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Cleaned {filepath}")
