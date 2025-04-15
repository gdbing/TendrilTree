import subprocess
import re
import csv
import datetime

def run_tests():
    # Run tests and capture output
    result = subprocess.run(
        ["xcodebuild", "test", "-scheme", "TendrilTree", "-destination", "platform=macOS",  "-only-testing:TendrilTreeTests/Measurements"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )
    return result.stdout

def parse_results(output):
    # regex to match: testName measured ... average: <num>
    regex = r"Test Case '-\[\w+\.(\w+) (\w+)\]' measured \[Time, seconds\] average: ([0-9.]+),"
    results = {}
    for match in re.finditer(regex, output):
        classname, testname, average = match.groups()
        full_testname = f"{classname}.{testname}"
        results[full_testname] = float(average)
    return results

def get_git_sha():
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"]).decode('utf-8').strip()
    except Exception:
        return "unknown"

def write_csv_row(csvfile, row, headers):
    file_exists = False
    try:
        with open(csvfile, "r") as f:
            file_exists = True
    except FileNotFoundError:
        file_exists = False

    with open(csvfile, "a", newline='') as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        if not file_exists:
            writer.writeheader()
        writer.writerow(row)

def main():
    out = run_tests()
    results = parse_results(out)
    now = datetime.datetime.now().isoformat()
    git_sha = get_git_sha()
    row = {"date": now, "git_sha": git_sha}
    row.update(results)

    # Set up CSV headers
    headers = ["date", "git_sha"] + list(results.keys())
    write_csv_row("perf_results.csv", row, headers)
    print(f"Performance results recorded: {row}")

if __name__ == "__main__":
    main()