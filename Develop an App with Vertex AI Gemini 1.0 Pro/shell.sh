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
#----------------------------------------------------start--------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

PROJECT_ID=$(gcloud config get-value project)
echo "PROJECT_ID=${PROJECT_ID}"
echo "REGION=${REGION}"

gcloud services enable cloudbuild.googleapis.com cloudfunctions.googleapis.com run.googleapis.com logging.googleapis.com storage-component.googleapis.com aiplatform.googleapis.com

echo "${RED}${BOLD}Task 1. ${RESET}""${WHITE}${BOLD}Configure your environment and project${RESET}" "${GREEN}${BOLD}Completed${RESET}"

mkdir ~/gemini-app

cd ~/gemini-app

python3 -m venv gemini-streamlit

source gemini-streamlit/bin/activate

cat > ~/gemini-app/requirements.txt <<EOF
streamlit
google-cloud-aiplatform==1.38.1
google-cloud-logging==3.6.0

EOF

pip install -r requirements.txt

cat > ~/gemini-app/app.py <<EOF
import os
import streamlit as st
from app_tab1 import render_story_tab
from vertexai.preview.generative_models import GenerativeModel
import vertexai
import logging
from google.cloud import logging as cloud_logging

# configure logging
logging.basicConfig(level=logging.INFO)
# attach a Cloud Logging handler to the root logger
log_client = cloud_logging.Client()
log_client.setup_logging()

PROJECT_ID = os.environ.get('PROJECT_ID')   # Your Qwiklabs Google Cloud Project ID
LOCATION = os.environ.get('REGION')         # Your Qwiklabs Google Cloud Project Region
vertexai.init(project=PROJECT_ID, location=LOCATION)

@st.cache_resource
def load_models():
    text_model_pro = GenerativeModel("gemini-pro")
    multimodal_model_pro = GenerativeModel("gemini-pro-vision")
    return text_model_pro, multimodal_model_pro

st.header("Vertex AI Gemini API", divider="rainbow")
text_model_pro, multimodal_model_pro = load_models()

tab1, tab2, tab3, tab4 = st.tabs(["Story", "Marketing Campaign", "Image Playground", "Video Playground"])

with tab1:
    render_story_tab(text_model_pro)

EOF

cat ~/gemini-app/app.py

cat > ~/gemini-app/app_tab1.py <<EOF
import streamlit as st
from vertexai.preview.generative_models import GenerativeModel
from response_utils import *
import logging

# create the model prompt based on user input.
def generate_prompt():
    # Story character input
    character_name = st.text_input("Enter character name: \n\n",key="character_name",value="Mittens")
    character_type = st.text_input("What type of character is it? \n\n",key="character_type",value="Cat")
    character_persona = st.text_input("What personality does the character have? \n\n",
                                      key="character_persona",value="Mitten is a very friendly cat.")
    character_location = st.text_input("Where does the character live? \n\n",key="character_location",value="Andromeda Galaxy")

    # Story length and premise
    length_of_story = st.radio("Select the length of the story: \n\n",["Short","Long"],key="length_of_story",horizontal=True)
    story_premise = st.multiselect("What is the story premise? (can select multiple) \n\n",["Love","Adventure","Mystery","Horror","Comedy","Sci-Fi","Fantasy","Thriller"],key="story_premise",default=["Love","Adventure"])
    creative_control = st.radio("Select the creativity level: \n\n",["Low","High"],key="creative_control",horizontal=True)
    if creative_control == "Low":
        temperature = 0.30
    else:
        temperature = 0.95

    prompt = f"""Write a {length_of_story} story based on the following premise: \n
    character_name: {character_name} \n
    character_type: {character_type} \n
    character_persona: {character_persona} \n
    character_location: {character_location} \n
    story_premise: {",".join(story_premise)} \n
    If the story is "short", then make sure to have 5 chapters or else if it is "long" then 10 chapters. 
    Important point is that each chapter should be generated based on the premise given above.
    First start by giving the book introduction, chapter introductions and then each chapter. It should also have a proper ending.
    The book should have a prologue and an epilogue.
    """

    return temperature, prompt

# function to render the story tab, and call the model, and display the model prompt and response.
def render_story_tab (text_model_pro: GenerativeModel):
    st.write("Using Gemini 1.0 Pro - Text only model")
    st.subheader("Generate a story")

    temperature, prompt = generate_prompt()

    config = {
        "temperature": temperature,
        "max_output_tokens": 2048,
        }

    generate_t2t = st.button("Generate my story", key="generate_t2t")
    if generate_t2t and prompt:
        # st.write(prompt)
        with st.spinner("Generating your story using Gemini..."):
            first_tab1, first_tab2 = st.tabs(["Story response", "Prompt"])
            with first_tab1: 
                response = get_gemini_pro_text_response(text_model_pro, prompt, generation_config=config)
                if response:
                    st.write("Your story:")
                    st.write(response)
                    logging.info(response)
            with first_tab2: 
                st.text(prompt)

EOF

cat ~/gemini-app/app_tab1.py

cat > ~/gemini-app/response_utils.py <<EOF

from vertexai.preview.generative_models import (Content,
                                            GenerationConfig,
                                            GenerativeModel,
                                            GenerationResponse,
                                            Image,
                                            HarmCategory, 
                                            HarmBlockThreshold,
                                            Part)

def get_gemini_pro_text_response( model: GenerativeModel,
                                  prompt: str, 
                                  generation_config: GenerationConfig,
                                  stream=True):

    safety_settings={
        HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_NONE,
        HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_NONE,
        HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: HarmBlockThreshold.BLOCK_NONE,
        HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: HarmBlockThreshold.BLOCK_NONE,
    }

    responses = model.generate_content(prompt,
                                   generation_config = generation_config,
                                   safety_settings = safety_settings,
                                   stream=True)

    final_response = []
    for response in responses:
        try:
            final_response.append(response.text)
        except IndexError:
            final_response.append("")
            continue
    return " ".join(final_response)

EOF

cat ~/gemini-app/response_utils.py

streamlit run app.py \
--browser.serverAddress=localhost \
--server.enableCORS=false \
--server.enableXsrfProtection=false \
--server.port 8080

echo "${RED}${BOLD}Task 4. ${RESET}""${WHITE}${BOLD}Run and test the app locally${RESET}" "${GREEN}${BOLD}Completed${RESET}"

cat > ~/gemini-app/app_tab2.py <<EOF
import streamlit as st
from vertexai.preview.generative_models import GenerativeModel
from response_utils import *
import logging

# create the model prompt based on user input.
def generate_prompt():
    st.write("Using Gemini 1.0 Pro - Text only model")
    st.subheader("Generate your marketing campaign")

    product_name = st.text_input("What is the name of the product? \n\n",key="product_name",value="ZomZoo")
    product_category = st.radio("Select your product category: \n\n",["Clothing","Electronics","Food","Health & Beauty","Home & Garden"],key="product_category",horizontal=True)

    st.write("Select your target audience: ")
    target_audience_age = st.radio("Target age: \n\n",["18-24","25-34","35-44","45-54","55-64","65+"],key="target_audience_age",horizontal=True)
    # target_audience_gender = st.radio("Target gender: \n\n",["male","female","trans","non-binary","others"],key="target_audience_gender",horizontal=True)
    target_audience_location = st.radio("Target location: \n\n",["Urban", "Suburban","Rural"],key="target_audience_location",horizontal=True)

    st.write("Select your marketing campaign goal: ")
    campaign_goal = st.multiselect("Select your marketing campaign goal: \n\n",["Increase brand awareness","Generate leads","Drive sales","Improve brand sentiment"],key="campaign_goal",default=["Increase brand awareness","Generate leads"])
    if campaign_goal is None:
        campaign_goal = ["Increase brand awareness","Generate leads"]
    brand_voice = st.radio("Select your brand voice: \n\n",["Formal","Informal","Serious","Humorous"],key="brand_voice",horizontal=True)
    estimated_budget = st.radio("Select your estimated budget ($): \n\n",["1,000-5,000","5,000-10,000","10,000-20,000","20,000+"],key="estimated_budget",horizontal=True)

    prompt = f"""Generate a marketing campaign for {product_name}, a {product_category} designed for the age group: {target_audience_age}. 
    The target location is this: {target_audience_location}.
    Aim to primarily achieve {campaign_goal}. 
    Emphasize the product's unique selling proposition while using a {brand_voice} tone of voice. 
    Allocate the total budget of {estimated_budget}.  
    With these inputs, make sure to follow following guidelines and generate the marketing campaign with proper headlines: \n
    - Briefly describe the company, its values, mission, and target audience.
    - Highlight any relevant brand guidelines or messaging frameworks.
    - Provide a concise overview of the campaign's objectives and goals.
    - Briefly explain the product or service being promoted.
    - Define your ideal customer with clear demographics, psychographics, and behavioral insights.
    - Understand their needs, wants, motivations, and pain points.
    - Clearly articulate the desired outcomes for the campaign.
    - Use SMART goals (Specific, Measurable, Achievable, Relevant, and Time-bound) for clarity.
    - Define key performance indicators (KPIs) to track progress and success.
    - Specify the primary and secondary goals of the campaign.
    - Examples include brand awareness, lead generation, sales growth, or website traffic.
    - Clearly define what differentiates your product or service from competitors.
    - Emphasize the value proposition and unique benefits offered to the target audience.
    - Define the desired tone and personality of the campaign messaging.
    - Identify the specific channels you will use to reach your target audience.
    - Clearly state the desired action you want the audience to take.
    - Make it specific, compelling, and easy to understand.
    - Identify and analyze your key competitors in the market.
    - Understand their strengths and weaknesses, target audience, and marketing strategies.
    - Develop a differentiation strategy to stand out from the competition.
    - Define how you will track the success of the campaign.
    - Use relevant KPIs to measure performance and return on investment (ROI).
    Provide bullet points and headlines for the marketing campaign. Do not produce any empty lines. Be very succinct and to the point.
    """

    return prompt

# function to render the story tab, and call the model, and display the model prompt and response.
def render_mktg_campaign_tab (text_model_pro: GenerativeModel):
    st.write("Using Gemini 1.0 Pro - Text only model")
    st.subheader("Generate a marketing campaign")

    prompt = generate_prompt()

    config = {
        "temperature": 0.8,
        "max_output_tokens": 2048,
        }

    generate_t2m = st.button("Generate campaign", key="generate_t2m")
    if generate_t2m and prompt:
        # st.write(prompt)
        with st.spinner("Generating a marketing campaign using Gemini..."):
            first_tab1, first_tab2 = st.tabs(["Campaign response", "Prompt"])
            with first_tab1: 
                response = get_gemini_pro_text_response(text_model_pro, prompt, generation_config=config)
                if response:
                    st.write("Marketing campaign:")
                    st.write(response)
                    logging.info(response)
            with first_tab2: 
                st.text(prompt)

EOF

cat >> ~/gemini-app/app.py <<EOF

from app_tab2 import render_mktg_campaign_tab

with tab2:
    render_mktg_campaign_tab(text_model_pro)

EOF

streamlit run app.py \
--browser.serverAddress=localhost \
--server.enableCORS=false \
--server.enableXsrfProtection=false \
--server.port 8080

echo "${RED}${BOLD}Task 5. ${RESET}""${WHITE}${BOLD}Generate a marketing campaign${RESET}" "${GREEN}${BOLD}Completed${RESET}"

cat > ~/gemini-app/app_tab3.py <<EOF
import streamlit as st
from vertexai.preview.generative_models import GenerativeModel, Part
from response_utils import *
import logging

# render the Image Playground tab with multiple child tabs
def render_image_playground_tab(multimodal_model_pro: GenerativeModel):

    st.write("Using Gemini 1.0 Pro Vision - Multimodal model")
    recommendations, screens, diagrams, equations = st.tabs(["Furniture recommendation", "Oven instructions", "ER diagrams", "Math reasoning"])

    with recommendations:
        room_image_uri = "gs://cloud-training/OCBL447/gemini-app/images/living_room.jpeg"
        chair_1_image_uri = "gs://cloud-training/OCBL447/gemini-app/images/chair1.jpeg"
        chair_2_image_uri = "gs://cloud-training/OCBL447/gemini-app/images/chair2.jpeg"
        chair_3_image_uri = "gs://cloud-training/OCBL447/gemini-app/images/chair3.jpeg"
        chair_4_image_uri = "gs://cloud-training/OCBL447/gemini-app/images/chair4.jpeg"

        room_image_url = "https://storage.googleapis.com/"+room_image_uri.split("gs://")[1]
        chair_1_image_url = "https://storage.googleapis.com/"+chair_1_image_uri.split("gs://")[1]
        chair_2_image_url = "https://storage.googleapis.com/"+chair_2_image_uri.split("gs://")[1]
        chair_3_image_url = "https://storage.googleapis.com/"+chair_3_image_uri.split("gs://")[1]
        chair_4_image_url = "https://storage.googleapis.com/"+chair_4_image_uri.split("gs://")[1]        

        room_image = Part.from_uri(room_image_uri, mime_type="image/jpeg")
        chair_1_image = Part.from_uri(chair_1_image_uri,mime_type="image/jpeg")
        chair_2_image = Part.from_uri(chair_2_image_uri,mime_type="image/jpeg")
        chair_3_image = Part.from_uri(chair_3_image_uri,mime_type="image/jpeg")
        chair_4_image = Part.from_uri(chair_4_image_uri,mime_type="image/jpeg")

        st.image(room_image_url,width=350, caption="Image of a living room")
        st.image([chair_1_image_url,chair_2_image_url,chair_3_image_url,chair_4_image_url],width=200, caption=["Chair 1","Chair 2","Chair 3","Chair 4"])

        st.write("Our expectation: Recommend a chair that would complement the given image of a living room.")
        prompt_list = ["Consider the following chairs:",
                    "chair 1:", chair_1_image,
                    "chair 2:", chair_2_image,
                    "chair 3:", chair_3_image, "and",
                    "chair 4:", chair_4_image, "\n"
                    "For each chair, explain why it would be suitable or not suitable for the following room:",
                    room_image,
                    "Only recommend for the room provided and not other rooms. Provide your recommendation in a table format with chair name and reason as columns.",
            ]

        tab1, tab2 = st.tabs(["Response", "Prompt"])
        generate_image_description = st.button("Generate recommendation", key="generate_image_description")
        with tab1:
            if generate_image_description and prompt_list: 
                with st.spinner("Generating recommendation using Gemini..."):
                    response = get_gemini_pro_vision_response(multimodal_model_pro, prompt_list)
                    st.markdown(response)
                    logging.info(response)
        with tab2:
            st.write("Prompt used:")
            st.text(prompt_list)
EOF

cat ~/gemini-app/app_tab3.py

cat >> ~/gemini-app/response_utils.py <<EOF

def get_gemini_pro_vision_response(model: GenerativeModel, prompt_list, generation_config={}, stream=True):

    generation_config = {'temperature': 0.1,
                     'max_output_tokens': 2048
                     }

    responses = model.generate_content(prompt_list, generation_config = generation_config, stream=True)

    final_response = []
    for response in responses:
        try:
            final_response.append(response.text)
        except IndexError: 
            final_response.append("")
            continue
    return(" ".join(final_response))

EOF

cat >> ~/gemini-app/app.py <<EOF

from app_tab3 import render_image_playground_tab

with tab3:
    render_image_playground_tab(multimodal_model_pro)

EOF

streamlit run app.py \
--browser.serverAddress=localhost \
--server.enableCORS=false \
--server.enableXsrfProtection=false \
--server.port 8080

echo "${RED}${BOLD}Task 6. ${RESET}""${WHITE}${BOLD}Generate the image playground${RESET}" "${GREEN}${BOLD}Completed${RESET}"

cat >> ~/gemini-app/app_tab3.py <<EOF

    with screens:
        oven_screen_uri = "gs://cloud-training/OCBL447/gemini-app/images/oven.jpg"
        oven_screen_url = "https://storage.googleapis.com/"+oven_screen_uri.split("gs://")[1]

        oven_screen_img = Part.from_uri(oven_screen_uri, mime_type="image/jpeg")
        st.image(oven_screen_url, width=350, caption="Image of an oven control panel")
        st.write("Provide instructions for resetting the clock on this appliance in English")

        prompt = """How can I reset the clock on this appliance? Provide the instructions in English.
                If instructions include buttons, also explain where those buttons are physically located.
                """

        tab1, tab2 = st.tabs(["Response", "Prompt"])
        generate_instructions_description = st.button("Generate instructions", key="generate_instructions_description")
        with tab1:
            if generate_instructions_description and prompt: 
                with st.spinner("Generating instructions using Gemini..."):
                    response = get_gemini_pro_vision_response(multimodal_model_pro, [oven_screen_img, prompt])
                    st.markdown(response)
                    logging.info(response)
        with tab2:
            st.write("Prompt used:")
            st.text(prompt+"\n"+"input_image")
EOF

streamlit run app.py \
--browser.serverAddress=localhost \
--server.enableCORS=false \
--server.enableXsrfProtection=false \
--server.port 8080

echo "${RED}${BOLD}Task 7. ${RESET}""${WHITE}${BOLD}Analyze image layout${RESET}" "${GREEN}${BOLD}Completed${RESET}"

cat >> ~/gemini-app/app_tab3.py <<EOF

    with diagrams:
        er_diag_uri = "gs://cloud-training/OCBL447/gemini-app/images/er.png"
        er_diag_url = "https://storage.googleapis.com/"+er_diag_uri.split("gs://")[1]

        er_diag_img = Part.from_uri(er_diag_uri,mime_type="image/png")
        st.image(er_diag_url, width=350, caption="Image of an ER diagram")
        st.write("Document the entities and relationships in this ER diagram.")

        prompt = """Document the entities and relationships in this ER diagram."""

        tab1, tab2 = st.tabs(["Response", "Prompt"])
        er_diag_img_description = st.button("Generate documentation", key="er_diag_img_description")
        with tab1:
            if er_diag_img_description and prompt: 
                with st.spinner("Generating..."):
                    response = get_gemini_pro_vision_response(multimodal_model_pro,[er_diag_img,prompt])
                    st.markdown(response)
                    logging.info(response)
        with tab2:
            st.write("Prompt used:")
            st.text(prompt+"\n"+"input_image")

EOF

streamlit run app.py \
--browser.serverAddress=localhost \
--server.enableCORS=false \
--server.enableXsrfProtection=false \
--server.port 8080

echo "${RED}${BOLD}Task 8. ${RESET}""${WHITE}${BOLD}Analyze ER diagrams${RESET}" "${GREEN}${BOLD}Completed${RESET}"

cat >> ~/gemini-app/app_tab3.py <<EOF

    with equations:
        math_image_uri = "gs://cloud-training/OCBL447/gemini-app/images/math_eqn.jpg"
        math_image_url = "https://storage.googleapis.com/"+math_image_uri.split("gs://")[1]

        math_image_img = Part.from_uri(math_image_uri,mime_type="image/jpeg")
        st.image(math_image_url,width=350, caption="Image of a math equation")
        st.markdown(f"""
                Ask questions about the math equation as follows: 
                - Extract the formula.
                - What is the symbol right before Pi? What does it mean?
                - Is this a famous formula? Does it have a name?
                    """)

        prompt = """Follow the instructions. Surround math expressions with $. Use a table with a row for each instruction and its result.
                INSTRUCTIONS:
                - Extract the formula.
                - What is the symbol right before Pi? What does it mean?
                - Is this a famous formula? Does it have a name?
                """

        tab1, tab2 = st.tabs(["Response", "Prompt"])
        math_image_description = st.button("Generate answers", key="math_image_description")
        with tab1:
            if math_image_description and prompt: 
                with st.spinner("Generating answers for formula using Gemini..."):
                    response = get_gemini_pro_vision_response(multimodal_model_pro, [math_image_img, prompt])
                    st.markdown(response)
                    logging.info(response)
        with tab2:
            st.write("Prompt used:")
            st.text(prompt)

EOF

streamlit run app.py \
--browser.serverAddress=localhost \
--server.enableCORS=false \
--server.enableXsrfProtection=false \
--server.port 8080

echo "${RED}${BOLD}Task 9. ${RESET}""${WHITE}${BOLD}Math reasoning${RESET}" "${GREEN}${BOLD}Completed${RESET}"

cat > ~/gemini-app/app_tab4.py <<EOF
import streamlit as st
from vertexai.preview.generative_models import GenerativeModel, Part
from response_utils import *
import logging

# render the Video Playground tab with multiple child tabs
def render_video_playground_tab(multimodal_model_pro: GenerativeModel):

    st.write("Using Gemini 1.0 Pro Vision - Multimodal model")
    video_desc, video_tags, video_highlights, video_geoloc = st.tabs(["Video description", "Video tags", "Video highlights", "Video geolocation"])

    with video_desc:
        video_desc_uri = "gs://cloud-training/OCBL447/gemini-app/videos/mediterraneansea.mp4"
        video_desc_url = "https://storage.googleapis.com/"+video_desc_uri.split("gs://")[1]            

        video_desc_vid = Part.from_uri(video_desc_uri, mime_type="video/mp4")
        st.video(video_desc_url)
        st.write("Generate a description of the video.")

        prompt = """Describe what is happening in the video and answer the following questions: \n
                - What am I looking at?
                - Where should I go to see it?
                - What are other top 5 places in the world that look like this? 
                """

        tab1, tab2 = st.tabs(["Response", "Prompt"])
        video_desc_description = st.button("Generate video description", key="video_desc_description")
        with tab1:
            if video_desc_description and prompt: 
                with st.spinner("Generating video description"):
                    response = get_gemini_pro_vision_response(multimodal_model_pro, [prompt, video_desc_vid])
                    st.markdown(response)
                    logging.info(response)
        with tab2:
            st.write("Prompt used:")
            st.write(prompt,"\n","{video_data}")

EOF

cat ~/gemini-app/app_tab4.py

cat >> ~/gemini-app/app.py <<EOF

from app_tab4 import render_video_playground_tab

with tab4:
    render_video_playground_tab(multimodal_model_pro)

EOF

streamlit run app.py \
--browser.serverAddress=localhost \
--server.enableCORS=false \
--server.enableXsrfProtection=false \
--server.port 8080

echo "${RED}${BOLD}Task 10. ${RESET}""${WHITE}${BOLD}Generate the video playground${RESET}" "${GREEN}${BOLD}Completed${RESET}"

cat >> ~/gemini-app/app_tab4.py <<EOF

    with video_tags:
        video_tags_uri = "gs://cloud-training/OCBL447/gemini-app/videos/photography.mp4"
        video_tags_url = "https://storage.googleapis.com/"+video_tags_uri.split("gs://")[1]

        video_tags_vid = Part.from_uri(video_tags_uri, mime_type="video/mp4")
        st.video(video_tags_url)
        st.write("Generate tags for the video.")

        prompt = """Answer the following questions using the video only:
                    1. What is in the video?
                    2. What objects are in the video?
                    3. What is the action in the video?
                    4. Provide 5 best tags for this video?
                    Write the answer in table format with the questions and answers in columns.
                """

        tab1, tab2 = st.tabs(["Response", "Prompt"])
        video_tags_desc = st.button("Generate video tags", key="video_tags_desc")
        with tab1:
            if video_tags_desc and prompt: 
                with st.spinner("Generating video tags"):
                    response = get_gemini_pro_vision_response(multimodal_model_pro, [prompt, video_tags_vid])
                    st.markdown(response)
                    logging.info(response)
        with tab2:
            st.write("Prompt used:")
            st.write(prompt,"\n","{video_data}")

EOF

streamlit run app.py \
--browser.serverAddress=localhost \
--server.enableCORS=false \
--server.enableXsrfProtection=false \
--server.port 8080

echo "${RED}${BOLD}Task 11. ${RESET}""${WHITE}${BOLD}Generate video tags${RESET}" "${GREEN}${BOLD}Completed${RESET}"

cat >> ~/gemini-app/app_tab4.py <<EOF

    with video_highlights:
        video_highlights_uri = "gs://cloud-training/OCBL447/gemini-app/videos/pixel8.mp4"
        video_highlights_url = "https://storage.googleapis.com/"+video_highlights_uri.split("gs://")[1]

        video_highlights_vid = Part.from_uri(video_highlights_uri, mime_type="video/mp4")
        st.video(video_highlights_url)
        st.write("Generate highlights for the video.")

        prompt = """Answer the following questions using the video only:
                What is the profession of the girl in this video?
                Which features of the phone are highlighted here?
                Summarize the video in one paragraph.
                Write these questions and their answers in table format. 
                """

        tab1, tab2 = st.tabs(["Response", "Prompt"])
        video_highlights_description = st.button("Generate video highlights", key="video_highlights_description")
        with tab1:
            if video_highlights_description and prompt: 
                with st.spinner("Generating video highlights"):
                    response = get_gemini_pro_vision_response(multimodal_model_pro, [prompt, video_highlights_vid])
                    st.markdown(response)
                    logging.info(response)
        with tab2:
            st.write("Prompt used:")
            st.write(prompt,"\n","{video_data}")

EOF

streamlit run app.py \
--browser.serverAddress=localhost \
--server.enableCORS=false \
--server.enableXsrfProtection=false \
--server.port 8080

echo "${RED}${BOLD}Task 12. ${RESET}""${WHITE}${BOLD}Generate video highlights${RESET}" "${GREEN}${BOLD}Completed${RESET}"

cat >> ~/gemini-app/app_tab4.py <<EOF

    with video_geoloc:
        video_geolocation_uri = "gs://cloud-training/OCBL447/gemini-app/videos/bus.mp4"
        video_geolocation_url = "https://storage.googleapis.com/"+video_geolocation_uri.split("gs://")[1]

        video_geolocation_vid = Part.from_uri(video_geolocation_uri, mime_type="video/mp4")
        st.video(video_geolocation_url)
        st.markdown("""Answer the following questions from the video:
                    - What is this video about?
                    - How do you know which city it is?
                    - What street is this?
                    - What is the nearest intersection?
                    """)

        prompt = """Answer the following questions using the video only:
                What is this video about?
                How do you know which city it is?
                What street is this?
                What is the nearest intersection?
                Answer the following questions using a table format with the questions and answers as columns. 
                """

        tab1, tab2 = st.tabs(["Response", "Prompt"])
        video_geolocation_description = st.button("Generate", key="video_geolocation_description")
        with tab1:
            if video_geolocation_description and prompt: 
                with st.spinner("Generating location information"):
                    response = get_gemini_pro_vision_response(multimodal_model_pro, [prompt, video_geolocation_vid])
                    st.markdown(response)
                    logging.info(response)
        with tab2:
            st.write("Prompt used:")
            st.write(prompt,"\n","{video_data}")

EOF

streamlit run app.py \
--browser.serverAddress=localhost \
--server.enableCORS=false \
--server.enableXsrfProtection=false \
--server.port 8080

echo "${RED}${BOLD}Task 13. ${RESET}""${WHITE}${BOLD}Generate video location${RESET}" "${GREEN}${BOLD}Completed${RESET}"

cd ~/gemini-app

SERVICE_NAME='gemini-app-playground' # Name of your Cloud Run service.
AR_REPO='gemini-app-repo'            # Name of your repository in Artifact Registry that stores your application container image.
echo "SERVICE_NAME=${SERVICE_NAME}"
echo "AR_REPO=${AR_REPO}"

gcloud artifacts repositories create "$AR_REPO" --location="$REGION" --repository-format=Docker

gcloud auth configure-docker "$REGION-docker.pkg.dev"

cat > ~/gemini-app/Dockerfile <<EOF
FROM python:3.8

EXPOSE 8080
WORKDIR /app

COPY . ./

RUN pip install -r requirements.txt

ENTRYPOINT ["streamlit", "run", "app.py", "--server.port=8080", "--server.address=0.0.0.0"]

EOF

gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/$SERVICE_NAME"

gcloud run deploy "$SERVICE_NAME" \
  --port=8080 \
  --image="$REGION-docker.pkg.dev/$PROJECT_ID/$AR_REPO/$SERVICE_NAME" \
  --allow-unauthenticated \
  --region=$REGION \
  --platform=managed  \
  --project=$PROJECT_ID \
  --set-env-vars=PROJECT_ID=$PROJECT_ID,REGION=$REGION

echo "${RED}${BOLD}Task 14. ${RESET}""${WHITE}${BOLD}Deploy the app to Cloud Run${RESET}" "${GREEN}${BOLD}Completed${RESET}"

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#