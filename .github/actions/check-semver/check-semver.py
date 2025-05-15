from packaging import version
import subprocess
import sys

subprocess.run(["sh", "-c", "git config --global --add safe.directory /github/workspace"], check=True)

proc = subprocess.Popen(['sh', '-c', 'git rev-list --tags --reverse | while read commit; do git tag --points-at "$commit" | sort ; done'], stdout=subprocess.PIPE, encoding='utf8')

output, error = proc.communicate()

if error:
    print(f"🚫 Error on executing git command: {error}")
    sys.exit(1)

tags = output.strip().split('\n')
semver_tags = []
for tag in tags:
    try:
        version.parse(tag)
        semver_tags.append(tag)
    except version.InvalidVersion:
        print(f"⚠️ Warning: {tag} is not a valid semver tag, ignoring it")

def check_semver_order(tags_to_check):
    for i in range(len(tags_to_check) - 1):
        current = version.parse(tags_to_check[i])
        next_tag = version.parse(tags_to_check[i+1])
        
        if current > next_tag:
            print(f"🚫 Error: Tags out of order - {tags_to_check[i]} comes after {tags_to_check[i+1]}")
            incorrect_tag = tags_to_check[i+1]
            return False, incorrect_tag
    return True, None

if not check_semver_order(semver_tags)[0]:
    is_valid, incorrect_tag = check_semver_order(semver_tags)
    print(f"🚫 There was a tag ({incorrect_tag}) that broke semver versioning. Please make sure tags are in correct semver order when sorted temporally.")
    print('📋 Execute this to check tag order locally: git rev-list --tags --reverse | while read commit; do git tag --points-at "$commit" | sort; done')
    sys.exit(1)
else:
    print("✅ Tags are in correct semver order")
    sys.exit(0)
