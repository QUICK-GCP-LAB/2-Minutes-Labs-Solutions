# Activity: Apply more filters in SQL

## Solution [here]()

### Run the following Commands

```
SELECT * 
FROM log_in_attempts 
WHERE login_date > '2022-05-09';

SELECT * 
FROM log_in_attempts 
WHERE login_date >= '2022-05-09';

SELECT * 
FROM log_in_attempts 
WHERE login_date BETWEEN '2022-05-09' AND '2022-05-11';

SELECT * 
FROM log_in_attempts 
WHERE login_time < '07:00:00';

SELECT * 
FROM log_in_attempts 
WHERE login_time >= '06:00:00' AND login_time < '07:00:00';

SELECT event_id, username, login_date
FROM log_in_attempts
WHERE event_id >= 100;

SELECT event_id, username, login_date
FROM log_in_attempts
WHERE event_id BETWEEN 100 AND 150;
```

### Congratulations 🎉 for completing the Lab !

##### *You Have Successfully Demonstrated Your Skills And Determination.*

#### *Well done!*

#### Don't Forget to Join the [Telegram Channel](https://t.me/quickgcplab) & [Discussion group](https://t.me/quickgcplabchats)

# [QUICK GCP LAB](https://www.youtube.com/@quickgcplab)