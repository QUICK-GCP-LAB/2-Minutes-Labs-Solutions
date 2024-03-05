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

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

gcloud auth list

mkdir test && cd test

cat > Dockerfile <<EOF
# Use an official Node runtime as the parent image
FROM node:lts

# Set the working directory in the container to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD . /app

# Make the container's port 80 available to the outside world
EXPOSE 80

# Run app.js using node when the container launches
CMD ["node", "app.js"]
EOF

cat > app.js << EOF;
const http = require("http");

const hostname = "0.0.0.0";
const port = 80;

const server = http.createServer((req, res) => {
	res.statusCode = 200;
	res.setHeader("Content-Type", "text/plain");
	res.end("Welcome to Cloud\n");
});

server.listen(port, hostname, () => {
	console.log("Server running at http://%s:%s/", hostname, port);
});

process.on("SIGINT", function () {
	console.log("Caught interrupt signal and will exit");
	process.exit();
});
EOF

docker build -t node-app:0.2 .

docker run -p 8080:80 --name my-app-2 -d node-app:0.2
docker ps

gcloud artifacts repositories create my-repository \
    --repository-format=docker \
    --location=$REGION \
    --description="Awesome Lab" 

gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

docker build -t $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/my-repository/node-app:0.2 .

docker push $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/my-repository/node-app:0.2

docker stop $(docker ps -q)
docker rm $(docker ps -aq)

docker rmi $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/my-repository/node-app:0.2
docker rmi node:lts
docker rmi -f $(docker images -aq) # remove remaining images
docker images

docker run -p 4000:80 -d $REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/my-repository/node-app:0.2

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
