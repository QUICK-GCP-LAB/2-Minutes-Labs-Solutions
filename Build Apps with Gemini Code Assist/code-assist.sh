clear

#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

gcloud auth login

sudo apt update
sudo apt -y upgrade
sudo apt install -y python3-venv
python3 -m venv ~/env
source ~/env/bin/activate

# Function to get PROJECT_ID input and export it
function set_project_id {
    while true; do
	echo
        echo -n "${BOLD}${YELLOW}Enter your PROJECT_ID: ${RESET}"
        read -r PROJECT_ID

        # Check if input is empty
        if [[ -z "$PROJECT_ID" ]]; then
            echo
            echo "${BOLD}${RED}PROJECT_ID cannot be empty. Please enter a valid ID.${RESET}"
            echo
        else
            export PROJECT_ID="$PROJECT_ID"
            echo
            echo "${BOLD}${GREEN}PROJECT_ID set to: $PROJECT_ID${RESET}"
            echo
            break
        fi
    done
}

# Call function to get input from user
set_project_id

gcloud config set project $PROJECT_ID

export BUCKET_NAME=$PROJECT_ID-code
gcloud storage cp -r gs://$BUCKET_NAME/* .

cd ~/codeassist-demo
source ~/env/bin/activate
pip install -r requirements.txt

# Start Flask app in the background using nohup
nohup python3 main.py > output.log 2>&1 &

echo
echo "${BOLD}${GREEN}Flask app started successfully.${RESET}"
echo

# Function to prompt user and kill all running Flask processes
function check_stop {
    while true; do
        echo -n "${BOLD}${YELLOW}Have you checked your progress up to Task 4? (Y/N): ${RESET}"
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "${BOLD}${RED}Stopping all running Flask processes...${RESET}"

            # Find all running Flask processes and kill them
            PIDS=$(ps aux | grep "python3 main.py" | grep -v grep | awk '{print $2}')
            if [[ -n "$PIDS" ]]; then
                kill -9 $PIDS
                echo "${BOLD}${GREEN}All Flask processes stopped.${RESET}"
            else
                echo "${BOLD}${MAGENTA}No running Flask processes found.${RESET}"
            fi

            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "${BOLD}${CYAN}Please check the score for Task 4.${RESET}"
            echo
            break
        else
            echo
            echo "${BOLD}${MAGENTA}Invalid input. Please enter Y or N.${RESET}"
            echo
        fi
    done
}

# Call function to prompt user
check_stop

cat > ~/codeassist-demo/test_calendar.py <<EOF
import unittest
import calendar

class TestNumberToRoman(unittest.TestCase):

    def test_basic_conversions(self):
        self.assertEqual(calendar.number_to_roman(1), "I")
        self.assertEqual(calendar.number_to_roman(5), "V")
        self.assertEqual(calendar.number_to_roman(10), "X")
        self.assertEqual(calendar.number_to_roman(50), "L")
        self.assertEqual(calendar.number_to_roman(100), "C")
        self.assertEqual(calendar.number_to_roman(500), "D")
        self.assertEqual(calendar.number_to_roman(1000), "M")

    def test_combinations(self):
        self.assertEqual(calendar.number_to_roman(4), "IV")
        self.assertEqual(calendar.number_to_roman(9), "IX")
        self.assertEqual(calendar.number_to_roman(14), "XIV")
        self.assertEqual(calendar.number_to_roman(40), "XL")
        self.assertEqual(calendar.number_to_roman(90), "XC")
        self.assertEqual(calendar.number_to_roman(400), "CD")
        self.assertEqual(calendar.number_to_roman(900), "CM")
        self.assertEqual(calendar.number_to_roman(1994), "MCMXCIV")
        self.assertEqual(calendar.number_to_roman(3888), "MMMDCCCLXXXVIII")

    def test_edge_cases(self):
        self.assertEqual(calendar.number_to_roman(0), "") #  Should handle zero
        self.assertRaises(TypeError, calendar.number_to_roman, "abc") # Should handle invalid input

    def test_large_numbers(self):
        self.assertEqual(calendar.number_to_roman(3000), "MMM")
        self.assertEqual(calendar.number_to_roman(3999), "MMMCMXCIX")

if __name__ == '__main__':
    unittest.main()

EOF

python3 test_calendar.py

cat > ~/codeassist-demo/calendar.py <<EOF
def number_to_roman(number):
    """Converts an integer to its Roman numeral equivalent.

    Args:
        number: An integer between 0 and 3999.

    Returns:
        A string representing the Roman numeral equivalent of the number.
        Returns an empty string if the input is 0.
        Raises TypeError if the input is not an integer or is out of range.
    """
    try:
        number = int(number)
    except ValueError:
        raise TypeError("Input must be an integer.")

    if not 0 <= number <= 3999:
        raise TypeError("Input must be between 0 and 3999.")

    if number == 0:
        return ""

    roman_map = { 1000: 'M', 900: 'CM', 500: 'D', 400: 'CD', 100: 'C', 90: 'XC',
                50: 'L', 40: 'XL', 10: 'X', 9: 'IX', 5: 'V', 4: 'IV', 1: 'I'}

    result = ""
    for value, numeral in roman_map.items():
        while number >= value:
            result += numeral
            number -= value
    return result
EOF

python3 test_calendar.py

cat > ~/codeassist-demo/calendar.py <<EOF
def number_to_roman(number):
    """Converts an integer to its Roman numeral equivalent.

    Args:
        number: An integer between 0 and 3999.

    Returns:
        A string representing the Roman numeral equivalent of the number.
        Returns an empty string if the input is 0.
        Raises TypeError if the input is not an integer or is out of range.
    """
    try:
        number = int(number)
    except ValueError:
        raise TypeError("Input must be an integer.")

    if not 0 <= number <= 3999:
        raise TypeError("Input must be between 0 and 3999.")

    if number == 0:
        return ""

    roman_map = { 1000: 'M', 900: 'CM', 500: 'D', 400: 'CD', 100: 'C', 90: 'XC',
                50: 'L', 40: 'XL', 10: 'X', 9: 'IX', 5: 'V', 4: 'IV', 1: 'I'}

    result = ""
    for value, numeral in roman_map.items():
        while number >= value:
            result += numeral
            number -= value
    return result
EOF

python3 test_calendar.py

cat > ~/codeassist-demo/main.py <<EOF
import os  # Import the os module for environment variables
from flask import Flask, render_template, request  # Import Flask framework components
import calendar  # Import the calendar module for Roman numeral conversion

# Create a Flask app instance
app = Flask(__name__)

# Define a route for the home page
@app.route("/", methods=["GET"])
def home_page():
    # Render the index.html template
    return render_template("index.html")

# Define a route for the conversion endpoint
@app.route("/convert", methods=["POST"])
def convert():
    # Get the number from the form data
    number = request.form["number"]
    # Convert the number to Roman numerals using the calendar module
    roman = calendar.number_to_roman(number)
    # Render the convert.html template with the number and its Roman numeral equivalent
    return render_template("convert.html", number=number, roman=roman)

# Run the Flask app if this script is executed directly
if __name__ == "__main__":
    # Run the app in debug mode, listening on all interfaces (0.0.0.0)
    # and using the port specified in the environment variable PORT or defaulting to 8080
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
EOF

cat > ~/codeassist-demo/templates/index.html <<EOF
<!DOCTYPE html>

<!--
 Copyright 2024 Google LLC

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 -->

<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Roman Numerals Converter</title>
    <style>
        body {
            font-family: sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }

        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 20px;
        }

        form {
            background-color: #fff;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            text-align: center;
        }

        label {
            display: block;
            margin-bottom: 10px;
            color: #555;
        }

        input[type="text"] {
            width: 100%;
            padding: 10px;
            margin-bottom: 20px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
        }

        button {
            background-color: #007bff;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 4px;
            cursor: pointer;
            transition: background-color 0.3s;
        }

        button:hover {
            background-color: #0056b3;
        }
    </style>
</head>
<body>
    <h1>Roman Numerals Converter</h1>

    <form action="/convert" method="post">
        <label for="number">Enter a number:</label>
        <input type="text" name="number" id="number" required placeholder="e.g., 1999"/>
        <button type="submit">Convert!</button>
    </form>
</body>
</html>
EOF

cat > ~/codeassist-demo/templates/convert.html <<EOF
<!DOCTYPE html>

<!--
 Copyright 2024 Google LLC

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 -->

<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Conversion Result</title>
    <style>
        body {
            font-family: sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }

        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 20px;
        }

        .result-container {
            background-color: #fff;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            text-align: center;
            margin-bottom: 20px;
        }

        p {
            color: #555;
            margin-bottom: 15px;
            line-height: 1.6;
        }

        a {
            color: #007bff;
            text-decoration: none;
            transition: color 0.3s;
        }

        a:hover {
            color: #0056b3;
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <h1>Conversion Result</h1>

    <div class="result-container">
        <p>The number {{ number }} is {{ roman }} in Roman Numerals.</p>
    </div>

    <p><a href="/">Return to home page.</a></p>
</body>
</html>
EOF

python3 main.py

