# Running Windows Containers on Compute Engine || [GSP153](https://www.cloudskillsboost.google/focuses/3348?parent=catalog) ||

## Solution [here](https://youtu.be/7-UkrVD-SkQ)

### Run the following Commands in Command Prompt

```
docker images
mkdir my-windows-app
cd my-windows-app
mkdir content
call > content\index.html
notepad content\index.html
```
```
<html>
  <head>
    <title>Windows containers</title>
  </head>
  <body>
    <p>Windows containers are cool!</p>
  </body>
</html>
```
```
call > Dockerfile
notepad Dockerfile
```
```
FROM mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2019

RUN powershell -NoProfile -Command Remove-Item -Recurse C:\inetpub\wwwroot\*

WORKDIR /inetpub/wwwroot

COPY content/ .
```
```
docker build -t gcr.io/dotnet-atamel/iis-site-windows .
docker images
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)
